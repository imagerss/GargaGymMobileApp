import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_config.dart';
import '../../core/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/sync_service.dart';

class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.takenAt,
    this.note,
    this.photoPath,
    this.localPath,
    this.pending = false,
  });

  final int id;
  final DateTime takenAt;
  final String? note;
  final String? photoPath;
  final String? localPath;
  final bool pending;

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) => ProgressPhoto(
    id: (json['id'] as num).toInt(),
    takenAt: _parseDate(json['taken_at']) ?? DateTime.now(),
    note: json['note'] as String?,
    photoPath: json['photo_path'] as String?,
    localPath: json['local_path'] as String?,
    pending: json['pending'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'taken_at': takenAt.toIso8601String(),
    'note': note,
    'photo_path': photoPath,
    'local_path': localPath,
    'pending': pending,
  };
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

class PhotosController extends ChangeNotifier {
  PhotosController({
    required ApiClient apiClient,
    required SyncService syncService,
    AppConfig config = const AppConfig(),
  }) : _apiClient = apiClient,
       _syncService = syncService,
       _config = config;

  static const _cacheKey = 'progress_photos_cache_v1';
  final ApiClient _apiClient;
  final SyncService _syncService;
  final AppConfig _config;
  final _prefs = SharedPreferencesAsync();
  final picker = ImagePicker();

  List<ProgressPhoto> photos = const [];
  bool loading = false;
  bool uploading = false;
  int? deletingId;
  String note = '';
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    photos = await _readCache();
    if (await _syncService.isOnline) {
      await refresh();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!await _syncService.isOnline) {
      photos = await _readCache();
      notifyListeners();
      return;
    }
    await _syncPending();
    final response = await _apiClient.getJson('/progress-photos');
    final fresh = _extractList(response).map(ProgressPhoto.fromJson).toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    final pending = <ProgressPhoto>[];
    for (final photo in (await _readCache()).where((item) => item.pending)) {
      if (await _syncService.hasPendingLocalEntity(
        'progress_photos',
        photo.id,
      )) {
        pending.add(photo);
      }
    }
    photos = [...pending, ...fresh];
    await _writeCache(photos);
    notifyListeners();
  }

  Future<void> pickAndAdd(ImageSource source) async {
    final file = await picker.pickImage(source: source, imageQuality: 88);
    if (file == null) return;
    await addPickedFile(file);
  }

  Future<void> addPickedFile(XFile file) async {
    uploading = true;
    error = null;
    notifyListeners();
    final photo = ProgressPhoto(
      id: -DateTime.now().millisecondsSinceEpoch,
      takenAt: DateTime.now(),
      note: note.trim().isEmpty ? null : note.trim(),
      localPath: file.path,
      pending: true,
    );
    if (await _syncService.isOnline) {
      try {
        await _upload(photo);
        await refresh();
        note = '';
        uploading = false;
        notifyListeners();
        return;
      } catch (_) {
        // Fall through to offline pending photo when upload cannot reach server.
      }
    }

    photos = [photo, ...photos];
    await _writeCache(photos);
    await _syncService.queueOperation(
      resource: 'progress_photos',
      action: 'create',
      localEntityId: photo.id,
      data: {
        'photo_data_url': await _dataUrlForFile(file.path),
        'taken_at': photo.takenAt.toIso8601String(),
        if (photo.note?.isNotEmpty == true) 'note': photo.note,
      },
    );
    note = '';
    _syncInBackground();
    uploading = false;
    notifyListeners();
  }

  Future<void> delete(ProgressPhoto photo) async {
    final previous = photos;
    deletingId = photo.id;
    photos = photos.where((item) => item.id != photo.id).toList();
    await _writeCache(photos);
    notifyListeners();
    try {
      if (photo.id < 0) {
        await _syncService.discardLocalEntity('progress_photos', photo.id);
      } else if (photo.id > 0) {
        if (await _syncService.isOnline) {
          await _apiClient.deleteJson('/progress-photos/${photo.id}');
        } else {
          await _syncService.queueOperation(
            resource: 'progress_photos',
            action: 'delete',
            entityId: photo.id,
          );
          _syncInBackground();
        }
      }
    } catch (e) {
      photos = previous;
      error = e is ApiException ? e.message : 'Nie udalo sie usunac zdjecia.';
    } finally {
      deletingId = null;
      notifyListeners();
    }
  }

  String photoUrl(ProgressPhoto photo) {
    if (photo.localPath != null) return photo.localPath!;
    final value = photo.photoPath ?? '';
    if (value.startsWith('http')) return value;
    final origin = Uri.parse(_config.apiBaseUrl).origin;
    return value.startsWith('/') ? '$origin$value' : '$origin/$value';
  }

  Future<void> _syncPending() async {
    final status = await _syncService.syncNow();
    if (status.error != null) {
      error = status.error;
    }
  }

  Future<ProgressPhoto> _upload(ProgressPhoto photo) async {
    final path = photo.localPath;
    if (path == null) throw const ApiException('Nie znaleziono pliku zdjecia.');
    final response = await _apiClient.postMultipart(
      '/progress-photos',
      fields: {
        'taken_at': photo.takenAt.toIso8601String(),
        if (photo.note?.isNotEmpty == true) 'note': photo.note!,
      },
      files: [await http.MultipartFile.fromPath('photo', path)],
    );
    return ProgressPhoto.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<String> _dataUrlForFile(String path) async {
    final extension = path.split('.').last.toLowerCase();
    final mediaType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'image/jpeg',
    };
    return 'data:$mediaType;base64,${base64Encode(await File(path).readAsBytes())}';
  }

  void _syncInBackground() => unawaited(_syncPending().catchError((_) {}));

  Future<List<ProgressPhoto>> _readCache() async {
    final raw = await _prefs.getString(_cacheKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded
              .whereType<Map<String, dynamic>>()
              .map(ProgressPhoto.fromJson)
              .toList()
        : [];
  }

  Future<void> _writeCache(List<ProgressPhoto> value) => _prefs.setString(
    _cacheKey,
    jsonEncode(value.map((e) => e.toJson()).toList()),
  );

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return data is List ? data.whereType<Map<String, dynamic>>().toList() : [];
  }
}

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key, required this.controller});
  final PhotosController controller;
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _note.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zdjecia progresu',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dodaj i usuwaj zdjecia sylwetki',
                    style: TextStyle(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _note,
                    decoration: const InputDecoration(
                      labelText: 'Notatka do zdjecia',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: c.uploading
                              ? null
                              : () {
                                  c.note = _note.text;
                                  c.pickAndAdd(ImageSource.camera);
                                  _note.clear();
                                },
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Aparat'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: c.uploading
                              ? null
                              : () {
                                  c.note = _note.text;
                                  c.pickAndAdd(ImageSource.gallery);
                                  _note.clear();
                                },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeria'),
                        ),
                      ),
                    ],
                  ),
                  if (c.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      c.error!,
                      style: const TextStyle(
                        color: Color(0xff9f1239),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (c.loading)
              const Center(child: CircularProgressIndicator())
            else if (c.photos.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Text(
                  'Brak zdjec.',
                  style: TextStyle(color: AppColors.slate500),
                ),
              )
            else
              for (final photo in c.photos)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: photo.localPath != null
                            ? Image.file(
                                File(photo.localPath!),
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                c.photoUrl(photo),
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  photo.note?.isNotEmpty == true
                                      ? photo.note!
                                      : 'Zdjecie progresu',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${photo.takenAt.day}.${photo.takenAt.month}.${photo.takenAt.year}',
                                  style: const TextStyle(
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (photo.pending)
                            const Text(
                              'Oczekuje',
                              style: TextStyle(color: AppColors.slate500),
                            ),
                          IconButton(
                            onPressed: c.deletingId == null
                                ? () => c.delete(photo)
                                : null,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xffb91c1c),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

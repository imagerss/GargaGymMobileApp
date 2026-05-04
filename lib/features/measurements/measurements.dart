import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/sync_service.dart';

class BodyMeasurement {
  const BodyMeasurement({
    required this.id,
    required this.measuredAt,
    this.weight,
    this.waistCm,
  });

  final int id;
  final DateTime measuredAt;
  final double? weight;
  final double? waistCm;

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: (json['id'] as num).toInt(),
      measuredAt:
          DateTime.tryParse(json['measured_at'] as String? ?? '') ??
          DateTime.now(),
      weight: (json['weight'] as num?)?.toDouble(),
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'measured_at': measuredAt.toIso8601String(),
    'weight': weight,
    'waist_cm': waistCm,
  };
}

class MeasurementsController extends ChangeNotifier {
  MeasurementsController({
    required ApiClient apiClient,
    required SyncService syncService,
  }) : _apiClient = apiClient,
       _syncService = syncService;

  static const _cacheKey = 'body_measurements_cache_v1';
  static const _opsKey = 'body_measurements_ops_v1';
  final ApiClient _apiClient;
  final SyncService _syncService;
  final _prefs = SharedPreferencesAsync();

  List<BodyMeasurement> items = const [];
  bool loading = false;
  bool saving = false;
  int? deletingId;
  String? error;
  bool _syncing = false;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _readCache();
      if (await _syncService.isOnline) {
        await refresh();
      }
    } catch (_) {
      error = 'Nie udalo sie pobrac pomiarow.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!await _syncService.isOnline) {
      items = await _readCache();
      notifyListeners();
      return;
    }
    await _syncPending();
    final response = await _apiClient.getJson('/body-measurements');
    final fresh = _extractList(response).map(BodyMeasurement.fromJson).toList()
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    items = fresh;
    await _writeCache(fresh);
    notifyListeners();
  }

  Future<void> add({required double weight, double? waistCm}) async {
    saving = true;
    error = null;
    notifyListeners();
    final item = BodyMeasurement(
      id: -DateTime.now().millisecondsSinceEpoch,
      measuredAt: DateTime.now(),
      weight: weight,
      waistCm: waistCm,
    );
    items = [item, ...items];
    await _writeCache(items);
    await _addOp({
      'action': 'create',
      'local_id': item.id,
      'data': item.toJson(),
    });
    _syncInBackground();
    saving = false;
    notifyListeners();
  }

  Future<void> delete(BodyMeasurement item) async {
    final previous = items;
    deletingId = item.id;
    items = items.where((entry) => entry.id != item.id).toList();
    await _writeCache(items);
    notifyListeners();

    if (item.id < 0) {
      await _removeOpsForLocal(item.id);
    } else {
      await _addOp({'action': 'delete', 'id': item.id});
      _syncInBackground();
    }
    deletingId = null;
    if (error != null) items = previous;
    notifyListeners();
  }

  Future<void> _syncPending() async {
    if (_syncing || !await _syncService.isOnline) return;
    _syncing = true;
    try {
      final ops = await _readOps();
      for (final op in ops) {
        try {
          if (op['action'] == 'create') {
            final data = Map<String, dynamic>.from(op['data'] as Map);
            final response = await _apiClient.postJson(
              '/body-measurements',
              body: data,
            );
            final created = BodyMeasurement.fromJson(
              response['data'] as Map<String, dynamic>,
            );
            items = [
              for (final item in await _readCache())
                if (item.id == op['local_id']) created else item,
            ];
            await _writeCache(items);
          } else if (op['action'] == 'delete') {
            await _apiClient.deleteJson('/body-measurements/${op['id']}');
          }
          await _removeOp(op['client_id'] as String);
        } on ApiException catch (exception) {
          error = exception.message;
        }
      }
    } finally {
      _syncing = false;
    }
  }

  void _syncInBackground() => unawaited(_syncPending().catchError((_) {}));

  Future<List<BodyMeasurement>> _readCache() async {
    final raw = await _prefs.getString(_cacheKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BodyMeasurement.fromJson)
        .toList()
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
  }

  Future<void> _writeCache(List<BodyMeasurement> value) => _prefs.setString(
    _cacheKey,
    jsonEncode(value.map((item) => item.toJson()).toList()),
  );

  Future<List<Map<String, dynamic>>> _readOps() async {
    final raw = await _prefs.getString(_opsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded.whereType<Map<String, dynamic>>().toList()
        : [];
  }

  Future<void> _writeOps(List<Map<String, dynamic>> ops) =>
      _prefs.setString(_opsKey, jsonEncode(ops));

  Future<void> _addOp(Map<String, dynamic> op) async {
    final ops = await _readOps();
    ops.add({...op, 'client_id': 'm-${DateTime.now().microsecondsSinceEpoch}'});
    await _writeOps(ops);
  }

  Future<void> _removeOp(String id) async {
    final ops = await _readOps();
    await _writeOps(ops.where((op) => op['client_id'] != id).toList());
  }

  Future<void> _removeOpsForLocal(int id) async {
    final ops = await _readOps();
    await _writeOps(ops.where((op) => op['local_id'] != id).toList());
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return data is List ? data.whereType<Map<String, dynamic>>().toList() : [];
  }
}

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key, required this.controller});
  final MeasurementsController controller;

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  final _weight = TextEditingController();
  final _waist = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _weight.dispose();
    _waist.dispose();
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
            _Panel(
              title: 'Pomiary ciala',
              subtitle: 'Zapis wagi i pomiarow',
              child: Column(
                children: [
                  TextField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Waga (kg)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _waist,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Talia (cm)'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: c.saving
                        ? null
                        : () async {
                            final weight = double.tryParse(
                              _weight.text.replaceAll(',', '.'),
                            );
                            if (weight == null) return;
                            await c.add(
                              weight: weight,
                              waistCm: double.tryParse(
                                _waist.text.replaceAll(',', '.'),
                              ),
                            );
                            _weight.clear();
                            _waist.clear();
                          },
                    icon: const Icon(Icons.add),
                    label: Text(c.saving ? 'Zapisuje...' : 'Dodaj pomiar'),
                  ),
                  if (c.error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorText(c.error!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (c.loading)
              const Center(child: CircularProgressIndicator())
            else if (c.items.isEmpty)
              const _EmptyText('Brak pomiarow.')
            else
              for (final item in c.items)
                _ListTileCard(
                  title: _formatDate(item.measuredAt),
                  subtitle:
                      'Waga ${item.weight ?? '-'} kg | Talia ${item.waistCm ?? '-'} cm',
                  trailing: IconButton(
                    onPressed: c.deletingId == null
                        ? () => c.delete(item)
                        : null,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xffb91c1c),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
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
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppColors.slate500)),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _ListTileCard extends StatelessWidget {
  const _ListTileCard({
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.slate200),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: AppColors.slate500)),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.slate200),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.slate500)),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xfffff1f2),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xffffcdd2)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xff9f1239),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

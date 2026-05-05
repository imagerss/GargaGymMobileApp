import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class SyncStatus {
  const SyncStatus({
    this.isSyncing = false,
    this.lastSyncAt,
    this.pendingOperations = 0,
    this.error,
  });

  final bool isSyncing;
  final String? lastSyncAt;
  final int pendingOperations;
  final String? error;
}

class SyncOperation {
  const SyncOperation({
    required this.clientId,
    required this.resource,
    required this.action,
    required this.createdAt,
    this.entityId,
    this.localEntityId,
    this.localRef,
    this.data,
  });

  final String clientId;
  final String resource;
  final String action;
  final String createdAt;
  final int? entityId;
  final int? localEntityId;
  final String? localRef;
  final Map<String, dynamic>? data;

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      clientId: json['client_id'] as String,
      resource: json['resource'] as String,
      action: json['action'] as String,
      createdAt:
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      entityId: (json['entity_id'] as num?)?.toInt(),
      localEntityId: (json['local_entity_id'] as num?)?.toInt(),
      localRef: json['local_ref'] as String?,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'resource': resource,
    'action': action,
    'created_at': createdAt,
    'entity_id': entityId,
    'local_entity_id': localEntityId,
    'local_ref': localRef,
    'data': data,
  };
}

class SyncService {
  SyncService({
    required ApiClient apiClient,
    Connectivity? connectivity,
    SharedPreferencesAsync? preferences,
  }) : _apiClient = apiClient,
       _connectivity = connectivity ?? Connectivity(),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const _lastSyncKey = 'last_sync_at';
  static const _operationsKey = 'sync_operations_v1';

  final ApiClient _apiClient;
  final Connectivity _connectivity;
  final SharedPreferencesAsync _preferences;
  bool _syncing = false;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result.any((item) => item != ConnectivityResult.none);
  }

  Future<SyncStatus> loadState() async {
    return SyncStatus(
      lastSyncAt: await _preferences.getString(_lastSyncKey),
      pendingOperations: await pendingCount(),
    );
  }

  Future<SyncStatus> syncNow() async {
    if (_syncing) return loadState();
    if (!await isOnline) return loadState();

    _syncing = true;
    try {
      final pushServerTime = await pushQueue();
      final lastSyncAt = await _preferences.getString(_lastSyncKey);
      final pulled = await pullChanges(updatedSince: lastSyncAt);
      final pullServerTime = pulled?['server_time'] as String?;
      final serverTime = pullServerTime ?? pushServerTime ?? lastSyncAt;
      if (serverTime != null) {
        await _preferences.setString(_lastSyncKey, serverTime);
      }

      return SyncStatus(
        lastSyncAt: serverTime,
        pendingOperations: await pendingCount(),
      );
    } on ApiException catch (exception) {
      return SyncStatus(
        lastSyncAt: await _preferences.getString(_lastSyncKey),
        pendingOperations: await pendingCount(),
        error: exception.message,
      );
    } finally {
      _syncing = false;
    }
  }

  Future<void> queueOperation({
    required String resource,
    required String action,
    int? entityId,
    int? localEntityId,
    String? localRef,
    Map<String, dynamic>? data,
  }) async {
    final operations = await readOperations();
    final replaceIndex = action == 'create'
        ? operations.indexWhere(
            (operation) =>
                operation.resource == resource &&
                operation.action == 'create' &&
                ((localRef != null && operation.localRef == localRef) ||
                    (localEntityId != null &&
                        operation.localEntityId == localEntityId)),
          )
        : -1;
    final operation = SyncOperation(
      clientId: replaceIndex >= 0
          ? operations[replaceIndex].clientId
          : 'mobile-${DateTime.now().microsecondsSinceEpoch}',
      resource: resource,
      action: action,
      entityId: entityId,
      localEntityId: localEntityId,
      localRef: localRef,
      data: data,
      createdAt: replaceIndex >= 0
          ? operations[replaceIndex].createdAt
          : DateTime.now().toIso8601String(),
    );

    if (replaceIndex >= 0) {
      operations[replaceIndex] = operation;
    } else {
      operations.add(operation);
    }
    await writeOperations(operations);
  }

  Future<void> discardLocalEntity(
    String resource,
    int localEntityId, [
    String? localRef,
  ]) async {
    final operations = await readOperations();
    await writeOperations(
      operations
          .where(
            (operation) =>
                operation.resource != resource ||
                ((operation.localEntityId == null ||
                        operation.localEntityId != localEntityId) &&
                    (localRef == null || operation.localRef != localRef)),
          )
          .toList(),
    );
  }

  Future<bool> hasPendingLocalEntity(
    String resource,
    int? localEntityId, [
    String? localRef,
  ]) async {
    final operations = await readOperations();
    return operations.any(
      (operation) =>
          operation.resource == resource &&
          ((localEntityId != null &&
                  operation.localEntityId == localEntityId) ||
              (localRef != null && operation.localRef == localRef)),
    );
  }

  Future<int> pendingCount() async => (await readOperations()).length;

  Future<List<SyncOperation>> readOperations() async {
    final raw = await _preferences.getString(_operationsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SyncOperation.fromJson)
        .toList();
  }

  Future<void> writeOperations(List<SyncOperation> operations) async {
    await _preferences.setString(
      _operationsKey,
      jsonEncode(operations.map((operation) => operation.toJson()).toList()),
    );
  }

  Future<String?> pushQueue() async {
    if (!await isOnline) return null;
    final operations = await readOperations();
    if (operations.isEmpty) return null;

    final response = await _apiClient.postJson(
      '/sync/push',
      body: {
        'operations': operations
            .map(
              (operation) => {
                'client_id': operation.clientId,
                'resource': operation.resource,
                'action': operation.action,
                'id': operation.entityId,
                'data': operation.data,
              },
            )
            .toList(),
      },
    );
    final data = response['data'] as Map<String, dynamic>?;
    final applied = data?['applied'];
    final appliedClientIds = applied is List
        ? applied
              .whereType<Map<String, dynamic>>()
              .map((item) => item['client_id']?.toString())
              .nonNulls
              .toSet()
        : <String>{};

    if (appliedClientIds.isNotEmpty) {
      await writeOperations(
        operations
            .where(
              (operation) => !appliedClientIds.contains(operation.clientId),
            )
            .toList(),
      );
    }

    final failed = data?['failed'];
    if (failed is List && failed.isNotEmpty) {
      final first = failed.whereType<Map<String, dynamic>>().firstOrNull;
      throw ApiException(
        first?['error']?.toString() ?? 'Nie udalo sie zsynchronizowac zmian.',
      );
    }

    return data?['server_time'] as String?;
  }

  Future<Map<String, dynamic>?> pullChanges({String? updatedSince}) async {
    if (!await isOnline) return null;
    final query = updatedSince == null
        ? '?limit=200'
        : '?updated_since=$updatedSince&limit=200';
    final response = await _apiClient.getJson('/sync/pull$query');
    return response['data'] as Map<String, dynamic>?;
  }
}

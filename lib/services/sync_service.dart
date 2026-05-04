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

class SyncService {
  SyncService({
    required ApiClient apiClient,
    Connectivity? connectivity,
    SharedPreferencesAsync? preferences,
  }) : _apiClient = apiClient,
       _connectivity = connectivity ?? Connectivity(),
       _preferences = preferences ?? SharedPreferencesAsync();

  static const _lastSyncKey = 'last_sync_at';

  final ApiClient _apiClient;
  final Connectivity _connectivity;
  final SharedPreferencesAsync _preferences;

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result.any((item) => item != ConnectivityResult.none);
  }

  Future<SyncStatus> loadState() async {
    return SyncStatus(lastSyncAt: await _preferences.getString(_lastSyncKey));
  }

  Future<SyncStatus> syncNow() async {
    if (!await isOnline) return loadState();

    final lastSyncAt = await _preferences.getString(_lastSyncKey);
    final data = await _apiClient.getJson(
      '/sync/pull${lastSyncAt == null ? '' : '?updated_since=$lastSyncAt&limit=200'}',
    );
    final serverTime =
        (data['data'] as Map<String, dynamic>?)?['server_time'] as String?;
    if (serverTime != null) {
      await _preferences.setString(_lastSyncKey, serverTime);
    }

    return SyncStatus(lastSyncAt: serverTime ?? lastSyncAt);
  }
}

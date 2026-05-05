import 'package:gargagymmobileapp/core/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gargagymmobileapp/features/auth/auth_models.dart';
import 'package:gargagymmobileapp/features/auth/auth_controller.dart';
import 'package:gargagymmobileapp/features/auth/auth_repository.dart';
import 'package:gargagymmobileapp/features/auth/session_store.dart';
import 'package:gargagymmobileapp/main.dart';
import 'package:gargagymmobileapp/services/api_client.dart';
import 'package:gargagymmobileapp/services/sync_service.dart';

void main() {
  testWidgets('shows auth screen after empty session restore', (tester) async {
    final apiClient = ApiClient(baseUrl: 'http://localhost:8000/api');
    final controller = AuthController(
      authRepository: AuthRepository(
        apiClient: apiClient,
        config: const AppConfig(
          apiBaseUrl: 'http://localhost:8000/api',
          deviceName: 'test-device',
        ),
      ),
      sessionStore: _FakeSessionStore(),
      apiClient: apiClient,
      syncService: _FakeSyncService(),
    );

    await tester.pumpWidget(GargaGymApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Witaj ponownie'), findsOneWidget);
    expect(find.text('Zaloguj'), findsWidgets);
  });
}

class _FakeSessionStore implements SessionStore {
  @override
  Future<void> clearSession() async {}

  @override
  Future<int?> readLastUserId() async => null;

  @override
  Future<String?> readToken() async => null;

  @override
  Future<AuthUser?> readUser() async => null;

  @override
  Future<void> saveSession(AuthSession session) async {}
}

class _FakeSyncService implements SyncService {
  @override
  Future<bool> get isOnline async => false;

  @override
  Future<void> discardLocalEntity(
    String resource,
    int localEntityId, [
    String? localRef,
  ]) async {}

  @override
  Future<bool> hasPendingLocalEntity(
    String resource,
    int? localEntityId, [
    String? localRef,
  ]) async => false;

  @override
  Future<SyncStatus> loadState() async => const SyncStatus();

  @override
  Future<int> pendingCount() async => 0;

  @override
  Future<Map<String, dynamic>?> pullChanges({String? updatedSince}) async =>
      null;

  @override
  Future<String?> pushQueue() async => null;

  @override
  Future<void> queueOperation({
    required String resource,
    required String action,
    int? entityId,
    int? localEntityId,
    String? localRef,
    Map<String, dynamic>? data,
  }) async {}

  @override
  Future<List<SyncOperation>> readOperations() async => const [];

  @override
  Future<SyncStatus> syncNow() async => const SyncStatus();

  @override
  Future<void> writeOperations(List<SyncOperation> operations) async {}
}

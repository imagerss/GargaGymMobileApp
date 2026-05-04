import 'package:flutter/foundation.dart';

import '../../services/api_client.dart';
import '../../services/sync_service.dart';
import 'auth_models.dart';
import 'auth_repository.dart';
import 'session_store.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required AuthRepository authRepository,
    required SessionStore sessionStore,
    required ApiClient apiClient,
    required SyncService syncService,
  }) : _authRepository = authRepository,
       _sessionStore = sessionStore,
       _apiClient = apiClient,
       _syncService = syncService;

  final AuthRepository _authRepository;
  final SessionStore _sessionStore;
  final ApiClient _apiClient;
  final SyncService _syncService;

  AuthUser? user;
  bool initialized = false;
  bool loading = false;
  bool offline = false;
  String? error;
  SyncStatus syncStatus = const SyncStatus();

  bool get isAuthenticated => user != null;

  Future<void> restoreSession() async {
    final token = await _sessionStore.readToken();
    final cachedUser = await _sessionStore.readUser();

    if (token != null) {
      _apiClient.bearerToken = token;
      user = cachedUser;
      notifyListeners();
    }

    offline = !await _syncService.isOnline;
    if (token != null && !offline) {
      try {
        final freshUser = await _authRepository.me();
        user = freshUser;
        await _sessionStore.saveSession(
          AuthSession(token: token, user: freshUser),
        );
        syncStatus = await _syncService.syncNow();
      } catch (_) {
        if (cachedUser == null) {
          await logoutLocal();
        }
      }
    }

    initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _authenticate(
      () => _authRepository.login(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _authenticate(
      () => _authRepository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      ),
    );
  }

  Future<void> _authenticate(Future<AuthSession> Function() request) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final session = await request();
      final previousUserId = user?.id ?? await _sessionStore.readLastUserId();
      if (previousUserId != null && previousUserId != session.user.id) {
        await _clearLocalUserData();
      }
      _apiClient.bearerToken = session.token;
      user = session.user;
      await _sessionStore.saveSession(session);
      offline = !await _syncService.isOnline;
      if (!offline) {
        syncStatus = await _syncService.syncNow();
      }
    } on ApiException catch (exception) {
      error = exception.message;
      rethrow;
    } catch (_) {
      error = 'Nie udalo sie polaczyc. Sprobuj ponownie.';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (!offline) {
        await _authRepository.logout();
      }
    } finally {
      await logoutLocal();
    }
  }

  Future<void> logoutLocal() async {
    _apiClient.bearerToken = null;
    user = null;
    await _sessionStore.clearSession();
    notifyListeners();
  }

  Future<void> syncIfNeeded() async {
    if (!isAuthenticated) return;
    offline = !await _syncService.isOnline;
    if (!offline) {
      syncStatus = await _syncService.syncNow();
    }
    notifyListeners();
  }

  Future<void> _clearLocalUserData() async {
    // Clear per-user cached resources here when the next mobile modules land.
  }
}

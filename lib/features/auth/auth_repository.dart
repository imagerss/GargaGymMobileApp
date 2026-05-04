import '../../core/app_config.dart';
import '../../services/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required AppConfig config})
    : _apiClient = apiClient,
      _config = config;

  final ApiClient _apiClient;
  final AppConfig _config;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.postJson(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        'device_name': _config.deviceName,
      },
    );
    return _sessionFromJson(data);
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await _apiClient.postJson(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': _config.deviceName,
      },
    );
    return _sessionFromJson(data);
  }

  Future<AuthUser> me() async {
    final data = await _apiClient.getJson('/auth/me');
    final rawUser = data['user'];
    if (rawUser is! Map<String, dynamic>) {
      throw const ApiException('Niepoprawny format odpowiedzi /auth/me.');
    }
    return AuthUser.fromJson(rawUser);
  }

  Future<void> logout() async {
    await _apiClient.postJson('/auth/logout');
  }

  AuthSession _sessionFromJson(Map<String, dynamic> data) {
    final token = data['token'];
    final user = data['user'];
    if (token is! String || user is! Map<String, dynamic>) {
      throw const ApiException('Niepoprawny format odpowiedzi auth.');
    }
    return AuthSession(token: token, user: AuthUser.fromJson(user));
  }
}

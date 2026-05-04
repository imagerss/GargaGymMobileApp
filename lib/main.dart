import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/session_store.dart';
import 'features/home/home_screen.dart';
import 'services/api_client.dart';
import 'services/sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GargaGymApp());
}

class GargaGymApp extends StatefulWidget {
  const GargaGymApp({super.key, this.controller});

  final AuthController? controller;

  @override
  State<GargaGymApp> createState() => _GargaGymAppState();
}

class _GargaGymAppState extends State<GargaGymApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = widget.controller ?? _buildAuthController();
    _authController.addListener(_handleAuthChanged);
    _authController.restoreSession();
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthChanged);
    if (widget.controller == null) {
      _authController.dispose();
    }
    super.dispose();
  }

  void _handleAuthChanged() => setState(() {});

  AuthController _buildAuthController() {
    const config = AppConfig();
    final apiClient = ApiClient(baseUrl: config.apiBaseUrl);
    final syncService = SyncService(apiClient: apiClient);
    return AuthController(
      authRepository: AuthRepository(apiClient: apiClient, config: config),
      sessionStore: SessionStore(),
      apiClient: apiClient,
      syncService: syncService,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GargaGym',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _authController.initialized
          ? _authController.isAuthenticated
                ? HomeScreen(controller: _authController)
                : AuthScreen(controller: _authController)
          : const _SplashScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

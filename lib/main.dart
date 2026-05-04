import 'package:flutter/material.dart';

import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/session_store.dart';
import 'features/exercises/exercise_repository.dart';
import 'features/exercises/exercise_store.dart';
import 'features/exercises/exercises_controller.dart';
import 'features/home/home_screen.dart';
import 'features/plans/workout_plan_repository.dart';
import 'features/plans/workout_plan_store.dart';
import 'features/plans/workout_plans_controller.dart';
import 'features/measurements/measurements.dart';
import 'features/photos/photos.dart';
import 'features/sessions/sessions.dart';
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
  ExercisesController? _exercisesController;
  WorkoutPlansController? _plansController;
  SessionsController? _sessionsController;
  MeasurementsController? _measurementsController;
  PhotosController? _photosController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      final dependencies = _buildDependencies();
      _authController = dependencies.authController;
      _exercisesController = dependencies.exercisesController;
      _plansController = dependencies.plansController;
      _sessionsController = dependencies.sessionsController;
      _measurementsController = dependencies.measurementsController;
      _photosController = dependencies.photosController;
    } else {
      _authController = widget.controller!;
    }
    _authController.addListener(_handleAuthChanged);
    _authController.restoreSession();
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthChanged);
    if (widget.controller == null) {
      _authController.dispose();
    }
    _exercisesController?.dispose();
    _plansController?.dispose();
    _sessionsController?.dispose();
    _measurementsController?.dispose();
    _photosController?.dispose();
    super.dispose();
  }

  void _handleAuthChanged() => setState(() {});

  _AppDependencies _buildDependencies() {
    const config = AppConfig();
    final apiClient = ApiClient(baseUrl: config.apiBaseUrl);
    final syncService = SyncService(apiClient: apiClient);
    final authController = AuthController(
      authRepository: AuthRepository(apiClient: apiClient, config: config),
      sessionStore: SessionStore(),
      apiClient: apiClient,
      syncService: syncService,
    );
    final exerciseRepository = ExerciseRepository(
      apiClient: apiClient,
      syncService: syncService,
      store: ExerciseStore(),
    );
    final exercisesController = ExercisesController(
      repository: exerciseRepository,
    );
    final plansController = WorkoutPlansController(
      repository: WorkoutPlanRepository(
        apiClient: apiClient,
        syncService: syncService,
        exerciseRepository: exerciseRepository,
        store: WorkoutPlanStore(),
      ),
    );
    final planRepository = WorkoutPlanRepository(
      apiClient: apiClient,
      syncService: syncService,
      exerciseRepository: exerciseRepository,
      store: WorkoutPlanStore(),
    );
    return _AppDependencies(
      authController: authController,
      exercisesController: exercisesController,
      plansController: plansController,
      sessionsController: SessionsController(
        apiClient: apiClient,
        syncService: syncService,
        planRepository: planRepository,
      ),
      measurementsController: MeasurementsController(
        apiClient: apiClient,
        syncService: syncService,
      ),
      photosController: PhotosController(
        apiClient: apiClient,
        syncService: syncService,
      ),
    );
  }

  ExercisesController _buildExercisesController() {
    const config = AppConfig();
    final apiClient = ApiClient(baseUrl: config.apiBaseUrl);
    final syncService = SyncService(apiClient: apiClient);
    return ExercisesController(
      repository: ExerciseRepository(
        apiClient: apiClient,
        syncService: syncService,
        store: ExerciseStore(),
      ),
    );
  }

  WorkoutPlansController _buildPlansController() {
    const config = AppConfig();
    final apiClient = ApiClient(baseUrl: config.apiBaseUrl);
    final syncService = SyncService(apiClient: apiClient);
    final exerciseRepository = ExerciseRepository(
      apiClient: apiClient,
      syncService: syncService,
      store: ExerciseStore(),
    );
    return WorkoutPlansController(
      repository: WorkoutPlanRepository(
        apiClient: apiClient,
        syncService: syncService,
        exerciseRepository: exerciseRepository,
        store: WorkoutPlanStore(),
      ),
    );
  }

  ExercisesController _ensureExercisesController() {
    return _exercisesController ??= _buildExercisesController();
  }

  WorkoutPlansController _ensurePlansController() {
    return _plansController ??= _buildPlansController();
  }

  SessionsController _ensureSessionsController() {
    const config = AppConfig();
    final apiClient = ApiClient(baseUrl: config.apiBaseUrl);
    final syncService = SyncService(apiClient: apiClient);
    final exerciseRepository = ExerciseRepository(
      apiClient: apiClient,
      syncService: syncService,
      store: ExerciseStore(),
    );
    return _sessionsController ??= SessionsController(
      apiClient: apiClient,
      syncService: syncService,
      planRepository: WorkoutPlanRepository(
        apiClient: apiClient,
        syncService: syncService,
        exerciseRepository: exerciseRepository,
        store: WorkoutPlanStore(),
      ),
    );
  }

  MeasurementsController _ensureMeasurementsController() {
    const config = AppConfig();
    final apiClient = ApiClient(baseUrl: config.apiBaseUrl);
    return _measurementsController ??= MeasurementsController(
      apiClient: apiClient,
      syncService: SyncService(apiClient: apiClient),
    );
  }

  PhotosController _ensurePhotosController() {
    const config = AppConfig();
    final apiClient = ApiClient(baseUrl: config.apiBaseUrl);
    return _photosController ??= PhotosController(
      apiClient: apiClient,
      syncService: SyncService(apiClient: apiClient),
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
                ? HomeScreen(
                    controller: _authController,
                    exercisesController: _ensureExercisesController(),
                    plansController: _ensurePlansController(),
                    sessionsController: _ensureSessionsController(),
                    measurementsController: _ensureMeasurementsController(),
                    photosController: _ensurePhotosController(),
                  )
                : AuthScreen(controller: _authController)
          : const _SplashScreen(),
    );
  }
}

class _AppDependencies {
  const _AppDependencies({
    required this.authController,
    required this.exercisesController,
    required this.plansController,
    required this.sessionsController,
    required this.measurementsController,
    required this.photosController,
  });

  final AuthController authController;
  final ExercisesController exercisesController;
  final WorkoutPlansController plansController;
  final SessionsController sessionsController;
  final MeasurementsController measurementsController;
  final PhotosController photosController;
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

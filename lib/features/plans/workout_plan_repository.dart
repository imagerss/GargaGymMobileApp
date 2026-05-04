import 'dart:async';

import '../../services/api_client.dart';
import '../../services/sync_service.dart';
import '../exercises/exercise_models.dart';
import '../exercises/exercise_repository.dart';
import 'workout_plan_models.dart';
import 'workout_plan_store.dart';

class WorkoutPlanRepository {
  WorkoutPlanRepository({
    required ApiClient apiClient,
    required SyncService syncService,
    required ExerciseRepository exerciseRepository,
    required WorkoutPlanStore store,
  }) : _apiClient = apiClient,
       _syncService = syncService,
       _exerciseRepository = exerciseRepository,
       _store = store;

  final ApiClient _apiClient;
  final SyncService _syncService;
  final ExerciseRepository _exerciseRepository;
  final WorkoutPlanStore _store;
  bool _syncing = false;
  final List<PlanSyncFailure> _failures = [];

  List<PlanSyncFailure> takeFailures() {
    final copy = List<PlanSyncFailure>.from(_failures);
    _failures.clear();
    return copy;
  }

  Future<List<WorkoutPlan>> listPlans() async {
    final cached = await _store.readPlans();
    if (cached.isNotEmpty) {
      if (await _syncService.isOnline) {
        return refreshPlans();
      }
      final enriched = await _enrichExerciseNames(cached);
      await _store.writePlans(enriched);
      return enriched;
    }

    if (!await _syncService.isOnline) return [];
    final fresh = await _enrichExerciseNames(await _fetchPlans());
    await _store.writePlans(fresh);
    return fresh;
  }

  Future<List<WorkoutPlan>> refreshPlans() async {
    if (!await _syncService.isOnline) {
      return _enrichExerciseNames(await _store.readPlans());
    }
    await syncPending();
    final fresh = await _enrichExerciseNames(await _fetchPlans());
    await _store.writePlans(fresh);
    return fresh;
  }

  Future<List<Exercise>> listExercises() => _exerciseRepository.listExercises();

  Future<WorkoutPlan> createPlan(String name) async {
    final localId = await _store.nextTempPlanId();
    final tempPlan = WorkoutPlan(
      id: localId,
      name: name,
      description: 'Plan z aplikacji mobilnej',
      isActive: true,
    );
    await _store.upsertPlan(tempPlan);

    final payload = {
      'name': name,
      'description': 'Plan z aplikacji mobilnej',
      'is_active': true,
    };

    await _queueCreatePlan(localId, payload);
    _syncInBackground();
    return tempPlan;
  }

  Future<void> deletePlan(WorkoutPlan plan) async {
    await _store.removePlan(plan.id);
    if (plan.id < 0) {
      await _store.discardOperationsForPlan(plan.id);
      return;
    }

    await _queueDeletePlan(plan.id);
    _syncInBackground();
  }

  Future<WorkoutPlan> addExerciseToPlan({
    required WorkoutPlan plan,
    required Exercise exercise,
    required int targetSets,
    required int targetReps,
  }) async {
    final localItemId = await _store.nextTempItemId();
    final localPlan = _addExerciseLocally(
      plan: plan,
      itemId: localItemId,
      exercise: exercise,
      targetSets: targetSets,
      targetReps: targetReps,
    );
    await _store.upsertPlan(localPlan);

    final payload = {
      'exercise_id': exercise.id,
      'target_sets': targetSets,
      'target_reps_min': targetReps,
      'target_reps_max': targetReps,
      'sort_order': _firstDay(plan).workoutDayExercises.length,
    };

    await _queueAddExercise(
      plan.id > 0 ? plan.id : null,
      plan.id < 0 ? plan.id : null,
      localItemId,
      payload,
    );
    _syncInBackground();
    return localPlan;
  }

  Future<WorkoutPlan> removeExerciseFromPlan({
    required WorkoutPlan plan,
    required WorkoutDayExercise dayExercise,
  }) async {
    final localPlan = _removeExerciseLocally(plan, dayExercise.id);
    await _store.upsertPlan(localPlan);

    if (dayExercise.id < 0) {
      return localPlan;
    }

    await _queueRemoveExercise(plan.id, dayExercise.id);
    _syncInBackground();
    return localPlan;
  }

  Future<void> syncPending() async {
    if (_syncing) return;
    if (!await _syncService.isOnline) return;
    _syncing = true;
    try {
      final operations = await _store.readOperations();
      final localPlanMap = <int, int>{};

      for (final operation in operations) {
        if (operation.action == PlanOperationAction.createPlan) {
          final created = await _createRemotePlan(operation.data ?? {});
          if (operation.localPlanId != null) {
            localPlanMap[operation.localPlanId!] = created.id;
            await _store.replacePlanId(operation.localPlanId!, created);
          }
        }

        if (operation.action == PlanOperationAction.deletePlan &&
            operation.planId != null) {
          try {
            await _apiClient.deleteJson('/workout-plans/${operation.planId}');
          } on ApiException catch (exception) {
            _failures.add(
              PlanSyncFailure(
                planId: operation.planId,
                message: _messageForDeleteFailure(exception),
              ),
            );
            continue;
          }
        }

        if (operation.action == PlanOperationAction.addExercise) {
          final planId =
              operation.planId ??
              (operation.localPlanId == null
                  ? null
                  : localPlanMap[operation.localPlanId]);
          if (planId != null) {
            final refreshed = await _addRemoteExercise(
              planId,
              operation.data ?? {},
            );
            await _store.upsertPlan(refreshed);
          }
        }

        if (operation.action == PlanOperationAction.removeExercise &&
            operation.dayExerciseId != null) {
          try {
            await _apiClient.deleteJson(
              '/workout-day-exercises/${operation.dayExerciseId}',
            );
          } on ApiException catch (exception) {
            _failures.add(
              PlanSyncFailure(
                planId: operation.planId,
                message: _messageForDeleteFailure(exception),
              ),
            );
            continue;
          }
        }

        await _store.removeOperation(operation.clientId);
      }
    } finally {
      _syncing = false;
    }
  }

  void unawaitedRefresh() {
    _fetchPlans()
        .then(_enrichExerciseNames)
        .then(_store.writePlans)
        .catchError((_) => <WorkoutPlan>[]);
  }

  void _syncInBackground() {
    unawaited(syncPending().catchError((_) {}));
  }

  Future<List<WorkoutPlan>> _fetchPlans() async {
    final response = await _apiClient.getJson('/workout-plans');
    final records = _extractList(response);
    return records.map(WorkoutPlan.fromJson).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }

  Future<List<WorkoutPlan>> _enrichExerciseNames(
    List<WorkoutPlan> plans,
  ) async {
    final exercises = await _exerciseRepository.refreshExercises();
    final nameById = {
      for (final exercise in exercises) exercise.id: exercise.name,
    };

    return plans
        .map(
          (plan) => plan.copyWith(
            workoutDays: plan.workoutDays
                .map(
                  (day) => day.copyWith(
                    workoutDayExercises: day.workoutDayExercises
                        .map(
                          (item) => item.copyWith(
                            exerciseName:
                                nameById[item.exerciseId] ?? item.exerciseName,
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  Future<WorkoutPlan> _fetchPlan(int id) async {
    final response = await _apiClient.getJson('/workout-plans/$id');
    final data = response['data'];
    if (data is Map<String, dynamic>) return WorkoutPlan.fromJson(data);
    throw const ApiException('Nie udalo sie pobrac planu.');
  }

  Future<WorkoutPlan> _createRemotePlan(Map<String, dynamic> payload) async {
    final response = await _apiClient.postJson('/workout-plans', body: payload);
    final data = response['data'];
    if (data is Map<String, dynamic>) return WorkoutPlan.fromJson(data);
    throw const ApiException('Nie udalo sie dodac planu.');
  }

  Future<WorkoutPlan> _addRemoteExercise(
    int planId,
    Map<String, dynamic> payload,
  ) async {
    final plan = await _fetchPlan(planId);
    final day = _firstDay(plan);
    final dayId = day.id > 0 ? day.id : await _createFirstDay(planId);
    await _apiClient.postJson('/workout-days/$dayId/exercises', body: payload);
    return _fetchPlan(planId);
  }

  Future<int> _createFirstDay(int planId) async {
    final response = await _apiClient.postJson(
      '/workout-plans/$planId/days',
      body: {'name': 'Dzien 1', 'day_order': 1},
    );
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return (data['id'] as num).toInt();
    }
    throw const ApiException('Nie udalo sie przygotowac planu.');
  }

  WorkoutPlan _addExerciseLocally({
    required WorkoutPlan plan,
    required int itemId,
    required Exercise exercise,
    required int targetSets,
    required int targetReps,
  }) {
    final day = _firstDay(plan);
    final nextItem = WorkoutDayExercise.fromExercise(
      id: itemId,
      exercise: exercise,
      targetSets: targetSets,
      targetReps: targetReps,
      sortOrder: day.workoutDayExercises.length,
    );
    final nextDay = day.copyWith(
      workoutDayExercises: [...day.workoutDayExercises, nextItem],
    );
    return _replaceFirstDay(plan, nextDay);
  }

  WorkoutPlan _removeExerciseLocally(WorkoutPlan plan, int itemId) {
    final day = _firstDay(plan);
    final nextDay = day.copyWith(
      workoutDayExercises: day.workoutDayExercises
          .where((item) => item.id != itemId)
          .toList(),
    );
    return _replaceFirstDay(plan, nextDay);
  }

  WorkoutDay _firstDay(WorkoutPlan plan) {
    final days = [...plan.workoutDays]
      ..sort((a, b) => a.dayOrder.compareTo(b.dayOrder));
    if (days.isNotEmpty) return days.first;
    return const WorkoutDay(id: -1, name: 'Dzien 1', dayOrder: 1);
  }

  WorkoutPlan _replaceFirstDay(WorkoutPlan plan, WorkoutDay nextDay) {
    final otherDays = plan.workoutDays
        .where((day) => day.dayOrder != nextDay.dayOrder)
        .toList();
    return plan.copyWith(workoutDays: [nextDay, ...otherDays]);
  }

  Future<void> _queueCreatePlan(
    int localId,
    Map<String, dynamic> payload,
  ) async {
    await _store.addOperation(
      PlanOperation(
        clientId: _clientId(),
        action: PlanOperationAction.createPlan,
        localPlanId: localId,
        data: payload,
      ),
    );
  }

  Future<void> _queueDeletePlan(int planId) async {
    await _store.addOperation(
      PlanOperation(
        clientId: _clientId(),
        action: PlanOperationAction.deletePlan,
        planId: planId,
      ),
    );
  }

  Future<void> _queueAddExercise(
    int? planId,
    int? localPlanId,
    int localItemId,
    Map<String, dynamic> payload,
  ) async {
    await _store.addOperation(
      PlanOperation(
        clientId: _clientId(),
        action: PlanOperationAction.addExercise,
        planId: planId,
        localPlanId: localPlanId,
        localDayExerciseId: localItemId,
        data: payload,
      ),
    );
  }

  Future<void> _queueRemoveExercise(int planId, int dayExerciseId) async {
    await _store.addOperation(
      PlanOperation(
        clientId: _clientId(),
        action: PlanOperationAction.removeExercise,
        planId: planId,
        dayExerciseId: dayExerciseId,
      ),
    );
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList();
      }
    }
    return [];
  }

  String _clientId() => 'mobile-${DateTime.now().microsecondsSinceEpoch}';

  String _messageForDeleteFailure(ApiException exception) {
    if (exception.statusCode == 409 || exception.statusCode == 422) {
      return 'Nie mozna usunac tego elementu, bo jest juz uzywany w treningach.';
    }
    if (exception.statusCode == 403) {
      return 'Nie masz uprawnien do usuniecia tego elementu.';
    }
    return exception.message;
  }
}

class PlanSyncFailure {
  const PlanSyncFailure({required this.message, this.planId});

  final String message;
  final int? planId;
}

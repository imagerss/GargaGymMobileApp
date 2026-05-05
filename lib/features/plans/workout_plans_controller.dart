import 'package:flutter/foundation.dart';

import '../exercises/exercise_models.dart';
import 'workout_plan_models.dart';
import 'workout_plan_repository.dart';

class WorkoutPlansController extends ChangeNotifier {
  WorkoutPlansController({required WorkoutPlanRepository repository})
    : _repository = repository;

  final WorkoutPlanRepository _repository;

  List<WorkoutPlan> plans = const [];
  List<Exercise> exercises = const [];
  bool loading = false;
  bool creating = false;
  int? deletingId;
  int? savingPlanId;
  String? error;
  String? syncError;

  Future<void> load() async {
    loading = true;
    error = null;
    syncError = null;
    notifyListeners();
    try {
      plans = await _repository.listPlans();
      exercises = await _repository.listExercises();
      _consumeSyncFailures();
    } catch (_) {
      error = 'Nie udalo sie pobrac planow.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    error = null;
    syncError = null;
    notifyListeners();
    try {
      plans = await _repository.refreshPlans();
      exercises = await _repository.listExercises();
      _consumeSyncFailures();
    } catch (_) {
      error = 'Nie udalo sie odswiezyc planow.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> createPlan(String name) async {
    if (creating) return;
    creating = true;
    error = null;
    syncError = null;
    notifyListeners();
    try {
      final created = await _repository.createPlan(name);
      plans = [created, ...plans.where((plan) => plan.id != created.id)]
        ..sort((a, b) => b.id.compareTo(a.id));
      plans = await _repository.listPlans();
      _consumeSyncFailures();
    } catch (_) {
      error = 'Nie udalo sie dodac planu.';
    } finally {
      creating = false;
      notifyListeners();
    }
  }

  Future<void> deletePlan(WorkoutPlan plan) async {
    if (deletingId != null) return;
    final previous = plans;
    deletingId = plan.id;
    plans = plans.where((item) => item.id != plan.id).toList();
    error = null;
    syncError = null;
    notifyListeners();
    try {
      await _repository.deletePlan(plan);
      _consumeSyncFailures(restore: previous);
      if (syncError == null) {
        plans = await _repository.listPlans();
      }
      _checkBackgroundFailures(restore: previous);
    } catch (_) {
      plans = previous;
      error = 'Nie udalo sie usunac planu.';
    } finally {
      deletingId = null;
      notifyListeners();
    }
  }

  Future<void> addExerciseToPlan({
    required WorkoutPlan plan,
    required Exercise exercise,
    required int targetSets,
    required int targetReps,
  }) async {
    if (savingPlanId != null) return;
    savingPlanId = plan.id;
    error = null;
    syncError = null;
    notifyListeners();
    try {
      final updated = await _repository.addExerciseToPlan(
        plan: plan,
        exercise: exercise,
        targetSets: targetSets,
        targetReps: targetReps,
      );
      _replacePlan(updated);
      plans = await _repository.listPlans();
      _consumeSyncFailures();
      _checkBackgroundFailures();
    } catch (_) {
      error = 'Nie udalo sie dodac cwiczenia do planu.';
    } finally {
      savingPlanId = null;
      notifyListeners();
    }
  }

  Future<void> removeExerciseFromPlan({
    required WorkoutPlan plan,
    required WorkoutDayExercise dayExercise,
  }) async {
    if (savingPlanId != null) return;
    savingPlanId = plan.id;
    error = null;
    syncError = null;
    notifyListeners();
    try {
      final updated = await _repository.removeExerciseFromPlan(
        plan: plan,
        dayExercise: dayExercise,
      );
      _replacePlan(updated);
      if (syncError == null) {
        plans = await _repository.listPlans();
      }
      _consumeSyncFailures();
      _checkBackgroundFailures();
    } catch (_) {
      error = 'Nie udalo sie usunac cwiczenia z planu.';
    } finally {
      savingPlanId = null;
      notifyListeners();
    }
  }

  void _replacePlan(WorkoutPlan plan) {
    plans = [
      for (final item in plans)
        if (item.id == plan.id) plan else item,
    ];
  }

  void _consumeSyncFailures({List<WorkoutPlan>? restore}) {
    final failures = _repository.takeFailures();
    if (failures.isEmpty) return;
    syncError = failures.last.message;
    if (restore != null) {
      final failedIds = failures.map((failure) => failure.planId).toSet();
      final shouldRestore = restore.where(
        (plan) => failedIds.contains(plan.id),
      );
      if (shouldRestore.isNotEmpty) {
        final currentIds = plans.map((plan) => plan.id).toSet();
        plans = [
          ...shouldRestore.where((plan) => !currentIds.contains(plan.id)),
          ...plans,
        ]..sort((a, b) => b.id.compareTo(a.id));
      }
    }
  }

  void _checkBackgroundFailures({List<WorkoutPlan>? restore}) {
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      _consumeSyncFailures(restore: restore);
      notifyListeners();
    });
  }
}

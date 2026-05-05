import 'package:flutter/foundation.dart';

import 'exercise_models.dart';
import 'exercise_repository.dart';

class ExercisesController extends ChangeNotifier {
  ExercisesController({required ExerciseRepository repository})
    : _repository = repository;

  final ExerciseRepository _repository;

  List<Exercise> exercises = const [];
  bool loading = false;
  bool creating = false;
  int? deletingId;
  String? error;
  String? syncError;

  Future<void> load() async {
    loading = true;
    error = null;
    syncError = null;
    notifyListeners();

    try {
      exercises = await _repository.listExercises();
      _consumeSyncFailures();
    } catch (_) {
      error = 'Nie udalo sie pobrac cwiczen.';
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
      exercises = await _repository.refreshExercises();
      _consumeSyncFailures();
    } catch (_) {
      error = 'Nie udalo sie odswiezyc cwiczen.';
    } finally {
      notifyListeners();
    }
  }

  Future<void> addExercise({
    required String name,
    required String muscleGroup,
  }) async {
    if (creating) return;
    creating = true;
    error = null;
    syncError = null;
    notifyListeners();

    try {
      final created = await _repository.addExercise(
        name: name,
        muscleGroup: muscleGroup,
      );
      exercises = [created, ...exercises.where((item) => item.id != created.id)]
        ..sort((a, b) => b.id.compareTo(a.id));
      exercises = await _repository.listExercises();
      _consumeSyncFailures();
    } catch (_) {
      error = 'Nie udalo sie dodac cwiczenia.';
    } finally {
      creating = false;
      notifyListeners();
    }
  }

  Future<void> deleteExercise(Exercise exercise) async {
    if (deletingId != null) return;

    final previous = exercises;
    deletingId = exercise.id;
    exercises = exercises.where((item) => item.id != exercise.id).toList();
    error = null;
    syncError = null;
    notifyListeners();

    try {
      await _repository.deleteExercise(exercise);
      _consumeSyncFailures(restore: previous);
      if (syncError == null) {
        exercises = await _repository.listExercises();
      }
      _checkBackgroundFailures(restore: previous);
    } catch (_) {
      exercises = previous;
      error = 'Nie udalo sie usunac cwiczenia.';
    } finally {
      deletingId = null;
      notifyListeners();
    }
  }

  void _checkBackgroundFailures({List<Exercise>? restore}) {
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      _consumeSyncFailures(restore: restore);
      notifyListeners();
    });
  }

  void _consumeSyncFailures({List<Exercise>? restore}) {
    final failures = _repository.takeFailures();
    if (failures.isEmpty) return;
    syncError = failures.last.message;
    if (restore != null) {
      final failedIds = failures.map((failure) => failure.entityId).toSet();
      final shouldRestore = restore.where(
        (exercise) => failedIds.contains(exercise.id),
      );
      if (shouldRestore.isNotEmpty) {
        final currentIds = exercises.map((exercise) => exercise.id).toSet();
        exercises = [
          ...shouldRestore.where(
            (exercise) => !currentIds.contains(exercise.id),
          ),
          ...exercises,
        ]..sort((a, b) => b.id.compareTo(a.id));
      }
    }
  }
}

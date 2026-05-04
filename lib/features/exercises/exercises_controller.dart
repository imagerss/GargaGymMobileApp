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

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      exercises = await _repository.listExercises();
    } catch (_) {
      error = 'Nie udalo sie pobrac cwiczen.';
    } finally {
      loading = false;
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
    notifyListeners();

    try {
      final created = await _repository.addExercise(
        name: name,
        muscleGroup: muscleGroup,
      );
      exercises = [created, ...exercises.where((item) => item.id != created.id)]
        ..sort((a, b) => b.id.compareTo(a.id));
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
    notifyListeners();

    try {
      await _repository.deleteExercise(exercise);
    } catch (_) {
      exercises = previous;
      error = 'Nie udalo sie usunac cwiczenia.';
    } finally {
      deletingId = null;
      notifyListeners();
    }
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_models.dart';

class ExerciseStore {
  ExerciseStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _cacheKey = 'exercises_cache_v1';
  static const _operationsKey = 'exercise_operations_v1';
  static const _tempIdKey = 'exercise_next_temp_id';

  final SharedPreferencesAsync _preferences;

  Future<List<Exercise>> readExercises() async {
    final raw = await _preferences.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }

  Future<void> writeExercises(List<Exercise> exercises) async {
    await _preferences.setString(
      _cacheKey,
      jsonEncode(exercises.map((exercise) => exercise.toJson()).toList()),
    );
  }

  Future<void> upsertExercise(Exercise exercise) async {
    final exercises = await readExercises();
    final index = exercises.indexWhere((item) => item.id == exercise.id);
    if (index >= 0) {
      exercises[index] = exercise;
    } else {
      exercises.insert(0, exercise);
    }
    await writeExercises(exercises);
  }

  Future<void> removeExercise(int id) async {
    final exercises = await readExercises();
    await writeExercises(exercises.where((item) => item.id != id).toList());
  }

  Future<void> replaceExerciseId(int previousId, Exercise nextExercise) async {
    final exercises = await readExercises();
    await writeExercises([
      for (final exercise in exercises)
        if (exercise.id == previousId) nextExercise else exercise,
    ]);
  }

  Future<int> nextTempId() async {
    final current = await _preferences.getInt(_tempIdKey) ?? -1;
    await _preferences.setInt(_tempIdKey, current - 1);
    return current;
  }

  Future<List<ExerciseOperation>> readOperations() async {
    final raw = await _preferences.getString(_operationsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ExerciseOperation.fromJson)
        .toList();
  }

  Future<void> writeOperations(List<ExerciseOperation> operations) async {
    await _preferences.setString(
      _operationsKey,
      jsonEncode(operations.map((operation) => operation.toJson()).toList()),
    );
  }

  Future<void> addOperation(ExerciseOperation operation) async {
    final operations = await readOperations();
    operations.add(operation);
    await writeOperations(operations);
  }

  Future<void> removeOperation(String clientId) async {
    final operations = await readOperations();
    await writeOperations(
      operations.where((operation) => operation.clientId != clientId).toList(),
    );
  }

  Future<void> discardOperationsForLocalId(int localId) async {
    final operations = await readOperations();
    await writeOperations(
      operations
          .where((operation) => operation.localEntityId != localId)
          .toList(),
    );
  }
}

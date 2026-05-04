import 'dart:async';

import '../../services/api_client.dart';
import '../../services/sync_service.dart';
import 'exercise_models.dart';
import 'exercise_store.dart';

class ExerciseRepository {
  ExerciseRepository({
    required ApiClient apiClient,
    required SyncService syncService,
    required ExerciseStore store,
  }) : _apiClient = apiClient,
       _syncService = syncService,
       _store = store;

  final ApiClient _apiClient;
  final SyncService _syncService;
  final ExerciseStore _store;

  Future<List<Exercise>> listExercises() async {
    final cached = await _store.readExercises();
    if (cached.isNotEmpty) {
      if (await _syncService.isOnline) {
        await syncPending();
        unawaitedRefresh();
      }
      return cached;
    }

    if (!await _syncService.isOnline) return [];
    final fresh = await _fetchExercises();
    await _store.writeExercises(fresh);
    return fresh;
  }

  Future<Exercise> addExercise({
    required String name,
    required String muscleGroup,
  }) async {
    final localId = await _store.nextTempId();
    final tempExercise = Exercise(
      id: localId,
      name: name,
      muscleGroup: muscleGroup,
      isCustom: true,
    );
    await _store.upsertExercise(tempExercise);

    final payload = {'name': name, 'muscle_group': muscleGroup};
    if (await _syncService.isOnline) {
      try {
        final created = await _createRemote(payload);
        await _store.replaceExerciseId(localId, created);
        return created;
      } catch (_) {
        await _queueCreate(localId, payload);
        return tempExercise;
      }
    }

    await _queueCreate(localId, payload);
    return tempExercise;
  }

  Future<void> deleteExercise(Exercise exercise) async {
    await _store.removeExercise(exercise.id);

    if (exercise.id < 0) {
      await _store.discardOperationsForLocalId(exercise.id);
      return;
    }

    if (await _syncService.isOnline) {
      try {
        await _apiClient.deleteJson('/exercises/${exercise.id}');
        return;
      } catch (_) {
        await _queueDelete(exercise.id);
        return;
      }
    }

    await _queueDelete(exercise.id);
  }

  Future<void> syncPending() async {
    if (!await _syncService.isOnline) return;
    final operations = await _store.readOperations();

    for (final operation in operations) {
      if (operation.action == ExerciseOperationAction.create) {
        final created = await _createRemote(operation.data ?? {});
        if (operation.localEntityId != null) {
          await _store.replaceExerciseId(operation.localEntityId!, created);
        } else {
          await _store.upsertExercise(created);
        }
      }

      if (operation.action == ExerciseOperationAction.delete &&
          operation.entityId != null) {
        await _apiClient.deleteJson('/exercises/${operation.entityId}');
      }

      await _store.removeOperation(operation.clientId);
    }
  }

  void unawaitedRefresh() {
    _fetchExercises()
        .then(_store.writeExercises)
        .catchError((_) => <Exercise>[]);
  }

  Future<List<Exercise>> _fetchExercises() async {
    final response = await _apiClient.getJson('/exercises');
    final records = _extractList(response);
    return records.map(Exercise.fromJson).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }

  Future<Exercise> _createRemote(Map<String, dynamic> payload) async {
    final response = await _apiClient.postJson('/exercises', body: payload);
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return Exercise.fromJson(data);
    }
    throw const ApiException('Nie udalo sie dodac cwiczenia.');
  }

  Future<void> _queueCreate(int localId, Map<String, dynamic> payload) async {
    await _store.addOperation(
      ExerciseOperation(
        clientId: _clientId(),
        action: ExerciseOperationAction.create,
        localEntityId: localId,
        data: payload,
      ),
    );
  }

  Future<void> _queueDelete(int entityId) async {
    await _store.addOperation(
      ExerciseOperation(
        clientId: _clientId(),
        action: ExerciseOperationAction.delete,
        entityId: entityId,
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

  String _clientId() {
    return 'mobile-${DateTime.now().microsecondsSinceEpoch}';
  }
}

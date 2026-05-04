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
  bool _syncing = false;
  final List<SyncFailure> _failures = [];

  List<SyncFailure> takeFailures() {
    final copy = List<SyncFailure>.from(_failures);
    _failures.clear();
    return copy;
  }

  Future<List<Exercise>> listExercises() async {
    final cached = await _store.readExercises();
    if (cached.isNotEmpty) {
      if (await _syncService.isOnline) {
        return refreshExercises();
      }
      return cached;
    }

    if (!await _syncService.isOnline) return [];
    final fresh = await _fetchExercises();
    await _store.writeExercises(fresh);
    return fresh;
  }

  Future<List<Exercise>> refreshExercises() async {
    if (!await _syncService.isOnline) return _store.readExercises();
    await syncPending();
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
    await _queueCreate(localId, payload);
    _syncInBackground();
    return tempExercise;
  }

  Future<void> deleteExercise(Exercise exercise) async {
    await _store.removeExercise(exercise.id);

    if (exercise.id < 0) {
      await _store.discardOperationsForLocalId(exercise.id);
      return;
    }

    await _queueDelete(exercise.id);
    _syncInBackground();
  }

  Future<void> syncPending() async {
    if (_syncing) return;
    if (!await _syncService.isOnline) return;
    _syncing = true;
    try {
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
          try {
            await _apiClient.deleteJson('/exercises/${operation.entityId}');
          } on ApiException catch (exception) {
            _failures.add(
              SyncFailure(
                resource: 'exercises',
                entityId: operation.entityId,
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
    _fetchExercises()
        .then(_store.writeExercises)
        .catchError((_) => <Exercise>[]);
  }

  void _syncInBackground() {
    unawaited(syncPending().catchError((_) {}));
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

  String _messageForDeleteFailure(ApiException exception) {
    if (exception.statusCode == 409 || exception.statusCode == 422) {
      return 'Nie mozna usunac cwiczenia, bo jest uzywane w planie lub treningu.';
    }
    if (exception.statusCode == 403) {
      return 'Nie masz uprawnien do usuniecia tego cwiczenia.';
    }
    return exception.message;
  }
}

class SyncFailure {
  const SyncFailure({
    required this.resource,
    required this.message,
    this.entityId,
  });

  final String resource;
  final int? entityId;
  final String message;
}

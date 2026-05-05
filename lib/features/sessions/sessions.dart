import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_theme.dart';
import '../../services/api_client.dart';
import '../../services/sync_service.dart';
import '../plans/workout_plan_models.dart';
import '../plans/workout_plan_repository.dart';

class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.planName,
    required this.startedAt,
    required this.status,
    this.remoteId,
    this.planId,
    this.endedAt,
    this.exercises = const [],
  });

  final String id;
  final int? remoteId;
  final int? planId;
  final String planName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final List<WorkoutDayExercise> exercises;

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      TrainingSession(
        id: json['id'] as String,
        remoteId: (json['remote_id'] as num?)?.toInt(),
        planId: (json['plan_id'] as num?)?.toInt(),
        planName: json['plan_name'] as String? ?? 'Sesja',
        startedAt:
            DateTime.tryParse(json['started_at'] as String? ?? '') ??
            DateTime.now(),
        endedAt: DateTime.tryParse(json['ended_at'] as String? ?? ''),
        status: json['status'] as String? ?? 'active',
        exercises: json['exercises'] is List
            ? (json['exercises'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map(WorkoutDayExercise.fromJson)
                  .toList()
            : const [],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'remote_id': remoteId,
    'plan_id': planId,
    'plan_name': planName,
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    'status': status,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  TrainingSession copyWith({
    int? remoteId,
    DateTime? endedAt,
    String? status,
    List<WorkoutDayExercise>? exercises,
  }) => TrainingSession(
    id: id,
    remoteId: remoteId ?? this.remoteId,
    planId: planId,
    planName: planName,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
    status: status ?? this.status,
    exercises: exercises ?? this.exercises,
  );
}

class SessionSetInput {
  const SessionSetInput({
    required this.workoutSessionExerciseId,
    required this.setNumber,
    required this.reps,
    required this.weight,
  });

  final int workoutSessionExerciseId;
  final int setNumber;
  final int reps;
  final double weight;

  Map<String, dynamic> toJson() => {
    'workout_session_exercise_id': workoutSessionExerciseId,
    'set_number': setNumber,
    'reps': reps,
    'weight': weight,
  };
}

class SessionsController extends ChangeNotifier {
  SessionsController({
    required ApiClient apiClient,
    required SyncService syncService,
    required WorkoutPlanRepository planRepository,
  }) : _apiClient = apiClient,
       _syncService = syncService,
       _planRepository = planRepository;

  static const _cacheKey = 'training_sessions_cache_v1';
  final ApiClient _apiClient;
  final SyncService _syncService;
  final WorkoutPlanRepository _planRepository;
  final _prefs = SharedPreferencesAsync();

  List<TrainingSession> sessions = const [];
  List<WorkoutPlan> plans = const [];
  bool loading = false;
  bool creating = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    sessions = await _readCache();
    plans = await _planRepository.listPlans();
    if (await _syncService.isOnline) {
      await refresh();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!await _syncService.isOnline) {
      sessions = await _readCache();
      notifyListeners();
      return;
    }
    await _syncPending();
    plans = await _planRepository.refreshPlans();
    final response = await _apiClient.getJson('/workout-sessions');
    final remote = _extractList(response).map(_remoteToSession).toList();
    final localPending = <TrainingSession>[];
    for (final session in (await _readCache()).where(
      (item) => item.remoteId == null || item.remoteId! < 0,
    )) {
      if (await _syncService.hasPendingLocalEntity(
        'workout_sessions',
        session.remoteId,
        session.id,
      )) {
        localPending.add(session);
      }
    }
    sessions = [...localPending, ...remote]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    await _writeCache(sessions);
    notifyListeners();
  }

  Future<void> start(WorkoutPlan plan) async {
    creating = true;
    error = null;
    notifyListeners();
    final day = [...plan.workoutDays]
      ..sort((a, b) => a.dayOrder.compareTo(b.dayOrder));
    final session = TrainingSession(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      remoteId: -DateTime.now().millisecondsSinceEpoch,
      planId: plan.id,
      planName: plan.name,
      startedAt: DateTime.now(),
      status: 'active',
      exercises: day.isEmpty ? const [] : day.first.workoutDayExercises,
    );
    if (await _syncService.isOnline && plan.id > 0) {
      try {
        final response = await _apiClient.postJson(
          '/workout-sessions',
          body: {
            'workout_plan_id': plan.id,
            'started_at': session.startedAt.toIso8601String(),
            'status': 'active',
          },
        );
        final data = response['data'] as Map<String, dynamic>;
        final remoteSession = session.copyWith(
          remoteId: (data['id'] as num).toInt(),
          exercises: _sessionExercisesFromPlan(plan, data),
        );
        sessions = [remoteSession, ...sessions];
        await _writeCache(sessions);
        creating = false;
        notifyListeners();
        return;
      } catch (_) {
        // Fall through to offline session when server is unreachable.
      }
    }

    sessions = [session, ...sessions];
    await _writeCache(sessions);
    await _syncService.queueOperation(
      resource: 'workout_sessions',
      action: 'create',
      localEntityId: session.remoteId,
      localRef: session.id,
      data: {
        'workout_plan_id': plan.id > 0 ? plan.id : null,
        'started_at': session.startedAt.toIso8601String(),
        'status': 'active',
      },
    );
    _syncInBackground();
    creating = false;
    notifyListeners();
  }

  Future<void> complete(
    TrainingSession session, {
    List<SessionSetInput> sets = const [],
    double? weight,
    double? waist,
    String? photoDataUrl,
  }) async {
    final ended = DateTime.now();
    final data = {
      'status': 'completed',
      'ended_at': ended.toIso8601String(),
      'sets': sets.map((set) => set.toJson()).toList(),
      if (weight != null)
        'measurement': {
          'measured_at': ended.toIso8601String(),
          'weight': weight,
          'waist_cm': waist,
        },
      if (photoDataUrl != null)
        'progress_photo': {
          'photo_data_url': photoDataUrl,
          'taken_at': ended.toIso8601String(),
          'note': 'Sesja ${session.planName}',
        },
    };
    if (await _syncService.isOnline &&
        session.remoteId != null &&
        session.remoteId! > 0) {
      try {
        await _apiClient.postJson(
          '/workout-sessions/${session.remoteId}/complete',
          body: data,
        );
        await refresh();
        return;
      } catch (_) {
        // Fall through to offline completion when server is unreachable.
      }
    }

    sessions = [
      for (final item in sessions)
        if (item.id == session.id)
          item.copyWith(status: 'completed', endedAt: ended)
        else
          item,
    ];
    await _writeCache(sessions);
    if (session.remoteId != null && session.remoteId! > 0) {
      await _syncService.queueOperation(
        resource: 'workout_sessions',
        action: 'update',
        entityId: session.remoteId,
        data: data,
      );
    } else {
      await _syncService.queueOperation(
        resource: 'workout_sessions',
        action: 'create',
        localEntityId: session.remoteId,
        localRef: session.id,
        data: _offlineCreateData(session, data, sets),
      );
    }
    _syncInBackground();
    notifyListeners();
  }

  Future<void> _syncPending() async {
    final status = await _syncService.syncNow();
    if (status.error != null) {
      error = status.error;
    }
  }

  Map<String, dynamic> _offlineCreateData(
    TrainingSession session,
    Map<String, dynamic> data,
    List<SessionSetInput> sets,
  ) {
    return {
      ...data,
      'workout_plan_id': session.planId != null && session.planId! > 0
          ? session.planId
          : null,
      'started_at': session.startedAt.toIso8601String(),
      'sets': _setsGroupedByExercise(session, sets),
    };
  }

  List<Map<String, dynamic>> _setsGroupedByExercise(
    TrainingSession session,
    List<SessionSetInput> sets,
  ) {
    return session.exercises
        .map((exercise) {
          final exerciseSets = sets
              .where((set) => set.workoutSessionExerciseId == exercise.id)
              .map(
                (set) => {
                  'set_number': set.setNumber,
                  'reps_done': set.reps,
                  'weight_kg': set.weight,
                },
              )
              .toList();
          return {'exercise_id': exercise.exerciseId, 'sets': exerciseSets};
        })
        .where((entry) => (entry['sets'] as List).isNotEmpty)
        .toList();
  }

  TrainingSession _remoteToSession(Map<String, dynamic> json) {
    final planId = (json['workout_plan_id'] as num?)?.toInt();
    final plan = plans.where((p) => p.id == planId).firstOrNull;
    final planName = plan?.name ?? 'Sesja';
    return TrainingSession(
      id: 'remote-${json['id']}',
      remoteId: (json['id'] as num).toInt(),
      planId: planId,
      planName: planName,
      startedAt:
          DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.now(),
      endedAt: DateTime.tryParse(json['ended_at'] as String? ?? ''),
      status: json['status'] as String? ?? 'active',
      exercises: plan == null
          ? const []
          : _sessionExercisesFromPlan(plan, json),
    );
  }

  List<WorkoutDayExercise> _sessionExercisesFromPlan(
    WorkoutPlan plan,
    Map<String, dynamic> sessionJson,
  ) {
    final sessionExercises = sessionJson['workout_session_exercises'];
    final sessionExerciseIdByExerciseId = <int, int>{};
    if (sessionExercises is List) {
      for (final raw in sessionExercises.whereType<Map<String, dynamic>>()) {
        final exerciseId = (raw['exercise_id'] as num?)?.toInt();
        final id = (raw['id'] as num?)?.toInt();
        if (exerciseId != null && id != null) {
          sessionExerciseIdByExerciseId[exerciseId] = id;
        }
      }
    }

    final days = [...plan.workoutDays]
      ..sort((a, b) => a.dayOrder.compareTo(b.dayOrder));
    if (days.isEmpty) return const [];
    return days.first.workoutDayExercises
        .map(
          (exercise) => exercise.copyWith(
            id:
                sessionExerciseIdByExerciseId[exercise.exerciseId] ??
                exercise.id,
          ),
        )
        .toList();
  }

  void _syncInBackground() => unawaited(_syncPending().catchError((_) {}));
  Future<List<TrainingSession>> _readCache() async {
    final raw = await _prefs.getString(_cacheKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded
              .whereType<Map<String, dynamic>>()
              .map(TrainingSession.fromJson)
              .toList()
        : [];
  }

  Future<void> _writeCache(List<TrainingSession> value) => _prefs.setString(
    _cacheKey,
    jsonEncode(value.map((e) => e.toJson()).toList()),
  );

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
    }
    return data is List ? data.whereType<Map<String, dynamic>>().toList() : [];
  }
}

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key, required this.controller});
  final SessionsController controller;
  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  WorkoutPlan? selected;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesje treningowe',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Wybierz plan i rozpocznij trening',
                    style: TextStyle(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<WorkoutPlan>(
                    initialValue: selected,
                    items: c.plans
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text(p.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                    decoration: const InputDecoration(
                      labelText: 'Plan treningowy',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: c.creating || selected == null
                        ? null
                        : () => c.start(selected!),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      c.creating ? 'Rozpoczynam...' : 'Rozpocznij sesje',
                    ),
                  ),
                  if (c.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      c.error!,
                      style: const TextStyle(
                        color: Color(0xff9f1239),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (c.loading)
              const Center(child: CircularProgressIndicator())
            else if (c.sessions.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: const Text(
                  'Brak sesji.',
                  style: TextStyle(color: AppColors.slate500),
                ),
              )
            else
              for (final session in c.sessions)
                _SessionCard(
                  session: session,
                  onComplete: session.status == 'active'
                      ? () => c.complete(session)
                      : null,
                ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, this.onComplete});
  final TrainingSession session;
  final VoidCallback? onComplete;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.slate200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                session.planName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              session.status == 'active' ? 'W trakcie' : 'Zakonczona',
              style: const TextStyle(color: AppColors.slate500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Start: ${session.startedAt.day}.${session.startedAt.month}.${session.startedAt.year}',
          style: const TextStyle(color: AppColors.slate500),
        ),
        if (session.exercises.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final e in session.exercises)
            Text('${e.exerciseName} - ${e.targetSets}x${e.targetReps}'),
        ],
        if (onComplete != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.check),
            label: const Text('Zakoncz sesje'),
          ),
        ],
      ],
    ),
  );
}

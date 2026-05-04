import '../exercises/exercise_models.dart';

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.workoutDays = const [],
  });

  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final List<WorkoutDay> workoutDays;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final days = json['workout_days'];
    return WorkoutPlan(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      workoutDays: days is List
          ? days
                .whereType<Map<String, dynamic>>()
                .map(WorkoutDay.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'workout_days': workoutDays.map((day) => day.toJson()).toList(),
    };
  }

  WorkoutPlan copyWith({
    int? id,
    String? name,
    String? description,
    bool? isActive,
    List<WorkoutDay>? workoutDays,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      workoutDays: workoutDays ?? this.workoutDays,
    );
  }
}

class WorkoutDay {
  const WorkoutDay({
    required this.id,
    required this.name,
    required this.dayOrder,
    this.workoutDayExercises = const [],
  });

  final int id;
  final String name;
  final int dayOrder;
  final List<WorkoutDayExercise> workoutDayExercises;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    final exercises = json['workout_day_exercises'];
    return WorkoutDay(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Dzien 1',
      dayOrder: (json['day_order'] as num?)?.toInt() ?? 1,
      workoutDayExercises: exercises is List
          ? exercises
                .whereType<Map<String, dynamic>>()
                .map(WorkoutDayExercise.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'day_order': dayOrder,
      'workout_day_exercises': workoutDayExercises
          .map((exercise) => exercise.toJson())
          .toList(),
    };
  }

  WorkoutDay copyWith({
    int? id,
    String? name,
    int? dayOrder,
    List<WorkoutDayExercise>? workoutDayExercises,
  }) {
    return WorkoutDay(
      id: id ?? this.id,
      name: name ?? this.name,
      dayOrder: dayOrder ?? this.dayOrder,
      workoutDayExercises: workoutDayExercises ?? this.workoutDayExercises,
    );
  }
}

class WorkoutDayExercise {
  const WorkoutDayExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.sortOrder,
  });

  final int id;
  final int exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int sortOrder;

  factory WorkoutDayExercise.fromJson(Map<String, dynamic> json) {
    final exercise = json['exercise'];
    return WorkoutDayExercise(
      id: (json['id'] as num).toInt(),
      exerciseId: (json['exercise_id'] as num).toInt(),
      exerciseName: exercise is Map<String, dynamic>
          ? exercise['name'] as String? ?? ''
          : '',
      targetSets: (json['target_sets'] as num?)?.toInt() ?? 3,
      targetReps:
          (json['target_reps_max'] as num?)?.toInt() ??
          (json['target_reps_min'] as num?)?.toInt() ??
          10,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  factory WorkoutDayExercise.fromExercise({
    required int id,
    required Exercise exercise,
    required int targetSets,
    required int targetReps,
    required int sortOrder,
  }) {
    return WorkoutDayExercise(
      id: id,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      targetSets: targetSets,
      targetReps: targetReps,
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise_id': exerciseId,
      'exercise': {'id': exerciseId, 'name': exerciseName},
      'target_sets': targetSets,
      'target_reps_min': targetReps,
      'target_reps_max': targetReps,
      'sort_order': sortOrder,
    };
  }

  WorkoutDayExercise copyWith({
    int? id,
    int? exerciseId,
    String? exerciseName,
    int? targetSets,
    int? targetReps,
    int? sortOrder,
  }) {
    return WorkoutDayExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

enum PlanOperationAction { createPlan, deletePlan, addExercise, removeExercise }

class PlanOperation {
  const PlanOperation({
    required this.clientId,
    required this.action,
    this.planId,
    this.localPlanId,
    this.dayExerciseId,
    this.localDayExerciseId,
    this.data,
  });

  final String clientId;
  final PlanOperationAction action;
  final int? planId;
  final int? localPlanId;
  final int? dayExerciseId;
  final int? localDayExerciseId;
  final Map<String, dynamic>? data;

  factory PlanOperation.fromJson(Map<String, dynamic> json) {
    return PlanOperation(
      clientId: json['client_id'] as String,
      action: PlanOperationAction.values.firstWhere(
        (item) => item.name == json['action'],
        orElse: () => PlanOperationAction.createPlan,
      ),
      planId: (json['plan_id'] as num?)?.toInt(),
      localPlanId: (json['local_plan_id'] as num?)?.toInt(),
      dayExerciseId: (json['day_exercise_id'] as num?)?.toInt(),
      localDayExerciseId: (json['local_day_exercise_id'] as num?)?.toInt(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'action': action.name,
      'plan_id': planId,
      'local_plan_id': localPlanId,
      'day_exercise_id': dayExerciseId,
      'local_day_exercise_id': localDayExerciseId,
      'data': data,
    };
  }
}

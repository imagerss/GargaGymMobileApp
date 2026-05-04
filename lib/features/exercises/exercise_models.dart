class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.description,
    this.isCustom = true,
  });

  final int id;
  final String name;
  final String muscleGroup;
  final String? description;
  final bool isCustom;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      muscleGroup: json['muscle_group'] as String? ?? '',
      description: json['description'] as String?,
      isCustom: json['is_custom'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup,
      'description': description,
      'is_custom': isCustom,
    };
  }

  Exercise copyWith({
    int? id,
    String? name,
    String? muscleGroup,
    String? description,
    bool? isCustom,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

enum ExerciseOperationAction { create, delete }

class ExerciseOperation {
  const ExerciseOperation({
    required this.clientId,
    required this.action,
    this.entityId,
    this.localEntityId,
    this.data,
  });

  final String clientId;
  final ExerciseOperationAction action;
  final int? entityId;
  final int? localEntityId;
  final Map<String, dynamic>? data;

  factory ExerciseOperation.fromJson(Map<String, dynamic> json) {
    return ExerciseOperation(
      clientId: json['client_id'] as String,
      action: ExerciseOperationAction.values.firstWhere(
        (item) => item.name == json['action'],
        orElse: () => ExerciseOperationAction.create,
      ),
      entityId: (json['entity_id'] as num?)?.toInt(),
      localEntityId: (json['local_entity_id'] as num?)?.toInt(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'action': action.name,
      'entity_id': entityId,
      'local_entity_id': localEntityId,
      'data': data,
    };
  }
}

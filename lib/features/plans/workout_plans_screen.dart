import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../exercises/exercise_models.dart';
import 'workout_plan_models.dart';
import 'workout_plans_controller.dart';

class WorkoutPlansScreen extends StatefulWidget {
  const WorkoutPlansScreen({super.key, required this.controller});

  final WorkoutPlansController controller;

  @override
  State<WorkoutPlansScreen> createState() => _WorkoutPlansScreenState();
}

class _WorkoutPlansScreenState extends State<WorkoutPlansScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int? _configuringPlanId;
  final Map<int, _PlanExerciseForm> _forms = {};

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
    widget.controller.load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _handleChanged() => setState(() {});

  Future<void> _createPlan() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.createPlan(_nameController.text.trim());
    if (widget.controller.error == null) {
      _nameController.clear();
    }
  }

  _PlanExerciseForm _formFor(int planId) {
    return _forms.putIfAbsent(planId, _PlanExerciseForm.new);
  }

  Future<void> _addExercise(WorkoutPlan plan) async {
    final form = _formFor(plan.id);
    final exercise = widget.controller.exercises
        .where((item) => item.id == form.exerciseId)
        .firstOrNull;
    if (exercise == null) return;

    await widget.controller.addExerciseToPlan(
      plan: plan,
      exercise: exercise,
      targetSets: form.targetSets,
      targetReps: form.targetReps,
    );
    if (widget.controller.error == null) {
      form.exerciseId = null;
      form.targetSets = 3;
      form.targetReps = 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plany treningowe',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.slate950,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Utworz plan i dodaj do niego cwiczenia z seria/powtorzeniami',
                    style: TextStyle(color: AppColors.slate500),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Nazwa planu',
                              hintText: 'Np. Push Pull Legs',
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Podaj nazwe planu.'
                                : null,
                            onFieldSubmitted: (_) => _createPlan(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: controller.creating
                                  ? null
                                  : _createPlan,
                              icon: controller.creating
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add, size: 18),
                              label: Text(
                                controller.creating
                                    ? 'Dodaje...'
                                    : 'Dodaj plan',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (controller.error != null ||
                      controller.syncError != null) ...[
                    const SizedBox(height: 12),
                    _InlineError(
                      message: controller.error ?? controller.syncError!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (controller.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.plans.isEmpty)
              const _EmptyPlans()
            else
              ...controller.plans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PlanTile(
                    plan: plan,
                    exercises: controller.exercises,
                    form: _formFor(plan.id),
                    configuring: _configuringPlanId == plan.id,
                    deleting: controller.deletingId == plan.id,
                    saving: controller.savingPlanId == plan.id,
                    busy:
                        controller.deletingId != null ||
                        controller.savingPlanId != null,
                    onToggleConfig: () => setState(() {
                      _configuringPlanId = _configuringPlanId == plan.id
                          ? null
                          : plan.id;
                    }),
                    onDelete: () => controller.deletePlan(plan),
                    onAddExercise: () => _addExercise(plan),
                    onRemoveExercise: (dayExercise) =>
                        controller.removeExerciseFromPlan(
                          plan: plan,
                          dayExercise: dayExercise,
                        ),
                    onFormChanged: () => setState(() {}),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.exercises,
    required this.form,
    required this.configuring,
    required this.deleting,
    required this.saving,
    required this.busy,
    required this.onToggleConfig,
    required this.onDelete,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onFormChanged,
  });

  final WorkoutPlan plan;
  final List<Exercise> exercises;
  final _PlanExerciseForm form;
  final bool configuring;
  final bool deleting;
  final bool saving;
  final bool busy;
  final VoidCallback onToggleConfig;
  final VoidCallback onDelete;
  final VoidCallback onAddExercise;
  final ValueChanged<WorkoutDayExercise> onRemoveExercise;
  final VoidCallback onFormChanged;

  List<WorkoutDayExercise> get planExercises {
    final days = [...plan.workoutDays]
      ..sort((a, b) => a.dayOrder.compareTo(b.dayOrder));
    if (days.isEmpty) return const [];
    return [...days.first.workoutDayExercises]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            plan.name,
            style: const TextStyle(
              color: AppColors.slate950,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            plan.description?.isNotEmpty == true
                ? plan.description!
                : 'Brak opisu',
            style: const TextStyle(color: AppColors.slate500),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onToggleConfig,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.slate100,
              side: BorderSide.none,
              foregroundColor: AppColors.slate900,
              minimumSize: const Size.fromHeight(42),
            ),
            child: Text(configuring ? 'Ukryj konfiguracje' : 'Konfiguruj plan'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: busy ? null : onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(42),
            ),
            child: Text(deleting ? 'Usuwam...' : 'Usun'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cwiczenia w planie: ${planExercises.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (planExercises.isEmpty) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Dodaj pierwsze cwiczenie do planu.',
                    style: TextStyle(color: AppColors.slate500),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  for (final item in planExercises)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${item.exerciseName} - ${item.targetSets}x${item.targetReps}',
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => onRemoveExercise(item),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.danger,
                            ),
                            child: const Text('Usun'),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (configuring) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: form.exerciseId,
              items: exercises
                  .map(
                    (exercise) => DropdownMenuItem(
                      value: exercise.id,
                      child: Text(exercise.name),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(labelText: 'Wybierz cwiczenie'),
              onChanged: (value) {
                form.exerciseId = value;
                onFormChanged();
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _NumberStepper(
                    label: 'Serie',
                    value: form.targetSets,
                    onChanged: (value) {
                      form.targetSets = value;
                      onFormChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberStepper(
                    label: 'Powtorz.',
                    value: form.targetReps,
                    onChanged: (value) {
                      form.targetReps = value;
                      onFormChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy || form.exerciseId == null
                    ? null
                    : onAddExercise,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add, size: 18),
                label: Text(saving ? 'Zapisuje...' : 'Dodaj cwiczenie'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.slate500)),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: value <= 1 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _PlanExerciseForm {
  int? exerciseId;
  int targetSets = 3;
  int targetReps = 10;
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: const Text(
        'Nie masz jeszcze planow.',
        style: TextStyle(color: AppColors.slate500),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfffff1f2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffffcdd2)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xff9f1239),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

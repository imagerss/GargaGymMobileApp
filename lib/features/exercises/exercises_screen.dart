import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import 'exercise_models.dart';
import 'exercises_controller.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key, required this.controller});

  final ExercisesController controller;

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _muscleGroupController = TextEditingController();

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
    _muscleGroupController.dispose();
    super.dispose();
  }

  void _handleChanged() => setState(() {});

  Future<void> _addExercise() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await widget.controller.addExercise(
      name: _nameController.text.trim(),
      muscleGroup: _muscleGroupController.text.trim(),
    );

    if (widget.controller.error == null) {
      _nameController.clear();
      _muscleGroupController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return SingleChildScrollView(
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
                  'Cwiczenia',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.slate950,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dodaj i przegladaj cwiczenia',
                  style: TextStyle(color: AppColors.slate500),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nazwa cwiczenia',
                            hintText: 'Np. Wyciskanie sztangi',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Podaj nazwe cwiczenia.'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _muscleGroupController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Partia miesniowa',
                            hintText: 'Np. Klatka piersiowa',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Podaj partie miesniowa.'
                              : null,
                          onFieldSubmitted: (_) => _addExercise(),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: controller.creating ? null : _addExercise,
                          icon: controller.creating
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(
                            controller.creating ? 'Dodaje...' : 'Dodaj',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 12),
                  _InlineError(message: controller.error!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (controller.loading)
            const _LoadingList()
          else if (controller.exercises.isEmpty)
            const _EmptyExercises()
          else
            ...controller.exercises.map(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ExerciseTile(
                  exercise: exercise,
                  deleting: controller.deletingId == exercise.id,
                  disabled: controller.deletingId != null,
                  onDelete: () => controller.deleteExercise(exercise),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.deleting,
    required this.disabled,
    required this.onDelete,
  });

  final Exercise exercise;
  final bool deleting;
  final bool disabled;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    color: AppColors.slate950,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exercise.muscleGroup.isEmpty
                      ? 'Brak partii'
                      : exercise.muscleGroup,
                  style: const TextStyle(color: AppColors.slate500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: disabled ? null : onDelete,
            icon: deleting
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline, size: 18),
            label: const Text('Usun'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xffb91c1c),
              side: const BorderSide(color: Color(0xfffecaca)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
      ),
      child: const Text(
        'Nie masz jeszcze cwiczen.',
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
        borderRadius: BorderRadius.circular(14),
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

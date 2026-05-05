import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import '../../core/app_theme.dart';
import '../auth/auth_controller.dart';
import '../exercises/exercises_controller.dart';
import '../exercises/exercises_screen.dart';
import '../plans/workout_plans_controller.dart';
import '../plans/workout_plans_screen.dart';
import '../plans/workout_plan_models.dart';
import '../measurements/measurements.dart';
import '../photos/photos.dart';
import '../profile/profile_screen.dart';
import '../sessions/sessions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.exercisesController,
    required this.plansController,
    required this.sessionsController,
    required this.measurementsController,
    required this.photosController,
  });

  final AuthController controller;
  final ExercisesController exercisesController;
  final WorkoutPlansController plansController;
  final SessionsController sessionsController;
  final MeasurementsController measurementsController;
  final PhotosController photosController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  _HomeSection _section = _HomeSection.dashboard;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final user = controller.user;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _AppMenu(
        controller: controller,
        section: _section,
        onSelect: (section) => setState(() => _section = section),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1f0f172a),
                      blurRadius: 36,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.slate900,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SLEDZ SWOJ PROGRES',
                            style: TextStyle(
                              color: AppColors.slate500,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'GargaGym',
                            style: TextStyle(
                              color: AppColors.slate950,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Otworz menu',
                      onPressed: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      icon: const Icon(Icons.menu),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_section == _HomeSection.dashboard)
                _DashboardContent(
                  userName: user?.name,
                  offline: controller.offline,
                  sessionsController: widget.sessionsController,
                  measurementsController: widget.measurementsController,
                  photosController: widget.photosController,
                )
              else if (_section == _HomeSection.plans)
                Expanded(
                  child: WorkoutPlansScreen(controller: widget.plansController),
                )
              else if (_section == _HomeSection.sessions)
                Expanded(
                  child: SessionsScreen(controller: widget.sessionsController),
                )
              else if (_section == _HomeSection.measurements)
                Expanded(
                  child: MeasurementsScreen(
                    controller: widget.measurementsController,
                  ),
                )
              else if (_section == _HomeSection.photos)
                Expanded(
                  child: PhotosScreen(controller: widget.photosController),
                )
              else if (_section == _HomeSection.profile)
                Expanded(child: ProfileScreen(controller: controller))
              else
                Expanded(
                  child: ExercisesScreen(
                    controller: widget.exercisesController,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppMenu extends StatelessWidget {
  const _AppMenu({
    required this.controller,
    required this.section,
    required this.onSelect,
  });

  final AuthController controller;
  final _HomeSection section;
  final ValueChanged<_HomeSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width.clamp(0, 360).toDouble(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.slate900,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        color: AppColors.slate950,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MenuItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                selected: section == _HomeSection.dashboard,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(_HomeSection.dashboard);
                },
              ),
              _MenuItem(
                icon: Icons.assignment_outlined,
                label: 'Plany',
                selected: section == _HomeSection.plans,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(_HomeSection.plans);
                },
              ),
              _MenuItem(
                icon: Icons.list_alt_outlined,
                label: 'Sesje',
                selected: section == _HomeSection.sessions,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(_HomeSection.sessions);
                },
              ),
              _MenuItem(
                icon: Icons.fitness_center_outlined,
                label: 'Cwiczenia',
                selected: section == _HomeSection.exercises,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(_HomeSection.exercises);
                },
              ),
              _MenuItem(
                icon: Icons.monitor_weight_outlined,
                label: 'Pomiary',
                selected: section == _HomeSection.measurements,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(_HomeSection.measurements);
                },
              ),
              _MenuItem(
                icon: Icons.photo_camera_outlined,
                label: 'Zdjecia',
                selected: section == _HomeSection.photos,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(_HomeSection.photos);
                },
              ),
              _MenuItem(
                icon: Icons.account_circle_outlined,
                label: 'Profil',
                selected: section == _HomeSection.profile,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(_HomeSection.profile);
                },
              ),
              const Spacer(),
              const Divider(color: AppColors.slate200),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await controller.logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Wyloguj'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xffb91c1c),
                  side: const BorderSide(color: Color(0xfffecaca)),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: selected
          ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Align(alignment: Alignment.centerLeft, child: Text(label)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                alignment: Alignment.centerLeft,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Align(alignment: Alignment.centerLeft, child: Text(label)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                alignment: Alignment.centerLeft,
                foregroundColor: AppColors.slate900,
              ),
            ),
    );
  }
}

enum _HomeSection {
  dashboard,
  plans,
  sessions,
  exercises,
  measurements,
  photos,
  profile,
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.userName,
    required this.offline,
    required this.sessionsController,
    required this.measurementsController,
    required this.photosController,
  });

  final String? userName;
  final bool offline;
  final SessionsController sessionsController;
  final MeasurementsController measurementsController;
  final PhotosController photosController;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _DashboardBody(
        userName: userName,
        offline: offline,
        sessionsController: sessionsController,
        measurementsController: measurementsController,
        photosController: photosController,
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody({
    required this.userName,
    required this.offline,
    required this.sessionsController,
    required this.measurementsController,
    required this.photosController,
  });

  final String? userName;
  final bool offline;
  final SessionsController sessionsController;
  final MeasurementsController measurementsController;
  final PhotosController photosController;

  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  int? _selectedPlanId;
  bool _loaded = false;
  final _finishWeightController = TextEditingController();
  final _finishWaistController = TextEditingController();
  final _setValues = <String, _DashboardSetValue>{};
  XFile? _finishPhoto;

  @override
  void initState() {
    super.initState();
    widget.sessionsController.addListener(_changed);
    widget.measurementsController.addListener(_changed);
    widget.photosController.addListener(_changed);
    _load();
  }

  @override
  void dispose() {
    widget.sessionsController.removeListener(_changed);
    widget.measurementsController.removeListener(_changed);
    widget.photosController.removeListener(_changed);
    _finishWeightController.dispose();
    _finishWaistController.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    await Future.wait([
      widget.sessionsController.load(),
      widget.measurementsController.load(),
      widget.photosController.load(),
    ]);
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.sessionsController.refresh(),
      widget.measurementsController.refresh(),
      widget.photosController.refresh(),
    ]);
  }

  Future<void> _pickFinishPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (picked == null) return;
    setState(() => _finishPhoto = picked);
  }

  Future<void> _completeActiveSession(TrainingSession session) async {
    final weight = double.tryParse(
      _finishWeightController.text.replaceAll(',', '.'),
    );
    final waist = double.tryParse(
      _finishWaistController.text.replaceAll(',', '.'),
    );

    final photoDataUrl = _finishPhoto == null
        ? null
        : 'data:image/jpeg;base64,${base64Encode(await _finishPhoto!.readAsBytes())}';

    await widget.sessionsController.complete(
      session,
      sets: _collectSets(session),
      weight: weight,
      waist: waist,
      photoDataUrl: photoDataUrl,
    );
    _finishWeightController.clear();
    _finishWaistController.clear();
    setState(() {
      _finishPhoto = null;
      _setValues.clear();
    });
    await _refresh();
  }

  List<SessionSetInput> _collectSets(TrainingSession session) {
    final result = <SessionSetInput>[];
    for (final exercise in session.exercises) {
      if (exercise.id <= 0) continue;
      for (var set = 1; set <= exercise.targetSets; set++) {
        final value = _setValues['${session.id}-${exercise.id}-$set'];
        final reps = int.tryParse(value?.reps ?? '');
        final weight = double.tryParse(
          (value?.weight ?? '').replaceAll(',', '.'),
        );
        if (reps == null || weight == null) continue;
        result.add(
          SessionSetInput(
            workoutSessionExerciseId: exercise.id,
            setNumber: set,
            reps: reps,
            weight: weight,
          ),
        );
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final sessions = widget.sessionsController;
    final measurements = widget.measurementsController.items;
    final photos = widget.photosController.photos;
    final activeSession = sessions.sessions
        .where((session) => session.status == 'active')
        .firstOrNull;
    final trend = [...measurements]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final latestPhoto = photos.isEmpty ? null : photos.first;
    if (_selectedPlanId != null &&
        !sessions.plans.any((plan) => plan.id == _selectedPlanId)) {
      _selectedPlanId = null;
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Czesc, ${widget.userName ?? 'sportowcu'}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.slate950,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.offline
                  ? 'Brak internetu. Nadal mozesz korzystac z zapisanych danych.'
                  : 'Twoj panel startowy treningu i progresu.',
              style: const TextStyle(color: AppColors.slate700, height: 1.35),
            ),
            const SizedBox(height: 16),
            _DashboardPanel(
              title: 'Trening',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedPlanId,
                    items: sessions.plans
                        .map(
                          (plan) => DropdownMenuItem(
                            value: plan.id,
                            child: Text(plan.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPlanId = value),
                    decoration: const InputDecoration(
                      labelText: 'Wybierz plan i rozpocznij sesje',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: sessions.creating || _selectedPlanId == null
                        ? null
                        : () {
                            final plan = sessions.plans
                                .where((item) => item.id == _selectedPlanId)
                                .firstOrNull;
                            if (plan == null) return;
                            sessions.start(plan);
                          },
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      sessions.creating
                          ? 'Rozpoczynam...'
                          : 'Rozpocznij sesje teraz',
                    ),
                  ),
                  if (activeSession != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
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
                                  activeSession.planName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Text(
                                'Aktywna sesja',
                                style: TextStyle(color: AppColors.slate500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Start: ${_formatDashboardDate(activeSession.startedAt)}',
                            style: const TextStyle(color: AppColors.slate500),
                          ),
                          if (activeSession.exercises.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            for (final exercise in activeSession.exercises)
                              _DashboardExerciseSets(
                                sessionId: activeSession.id,
                                exercise: exercise,
                                values: _setValues,
                                onChanged: () => setState(() {}),
                              ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: _finishWeightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Waga (kg)',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _finishWaistController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Talia (cm)',
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _pickFinishPhoto,
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: Text(
                              _finishPhoto == null
                                  ? 'Dodaj zdjecie'
                                  : 'Zmien zdjecie',
                            ),
                          ),
                          if (_finishPhoto != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _finishPhoto!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.slate500),
                            ),
                          ],
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () =>
                                _completeActiveSession(activeSession),
                            icon: const Icon(Icons.check),
                            label: const Text('Zakoncz aktywna sesje'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (sessions.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      sessions.error!,
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
            _DashboardPanel(
              title: 'Trend pomiarow',
              child: trend.isEmpty
                  ? const Text(
                      'Brak danych pomiarowych do wykresu.',
                      style: TextStyle(color: AppColors.slate500),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 180,
                          child: CustomPaint(
                            painter: _TrendPainter(trend),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (latestPhoto != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _DashboardPhoto(
                              photo: latestPhoto,
                              controller: widget.photosController,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(
                          'Ostatni pomiar: ${_formatDashboardDate(trend.last.measuredAt)}',
                          style: const TextStyle(color: AppColors.slate500),
                        ),
                        Text(
                          'Waga: ${trend.last.weight ?? '-'} kg | Talia: ${trend.last.waistCm ?? '-'} cm',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardExerciseSets extends StatelessWidget {
  const _DashboardExerciseSets({
    required this.sessionId,
    required this.exercise,
    required this.values,
    required this.onChanged,
  });

  final String sessionId;
  final WorkoutDayExercise exercise;
  final Map<String, _DashboardSetValue> values;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${exercise.exerciseName} - cel ${exercise.targetSets}x${exercise.targetReps}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var set = 1; set <= exercise.targetSets; set++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(
                      'Seria $set',
                      style: const TextStyle(color: AppColors.slate500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'kg'),
                      onChanged: (value) {
                        _valueFor(set).weight = value;
                        onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'powtorzenia',
                      ),
                      onChanged: (value) {
                        _valueFor(set).reps = value;
                        onChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  _DashboardSetValue _valueFor(int set) {
    final key = '$sessionId-${exercise.id}-$set';
    return values.putIfAbsent(key, _DashboardSetValue.new);
  }
}

class _DashboardSetValue {
  String weight = '';
  String reps = '';
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DashboardPhoto extends StatelessWidget {
  const _DashboardPhoto({required this.photo, required this.controller});

  final ProgressPhoto photo;
  final PhotosController controller;

  @override
  Widget build(BuildContext context) {
    if (photo.localPath != null) {
      return Image.file(
        File(photo.localPath!),
        height: 260,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      controller.photoUrl(photo),
      height: 260,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points);

  final List<BodyMeasurement> points;

  @override
  void paint(Canvas canvas, Size size) {
    final weightValues = points.map((point) => point.weight).nonNulls.toList();
    final waistValues = points.map((point) => point.waistCm).nonNulls.toList();
    final allValues = [...weightValues, ...waistValues];
    if (allValues.isEmpty) return;

    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.01
        ? 1.0
        : maxValue - minValue;

    final gridPaint = Paint()
      ..color = AppColors.slate200
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    void drawLine(List<double?> values, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      var started = false;
      for (var i = 0; i < values.length; i++) {
        final value = values[i];
        if (value == null) continue;
        final x = values.length == 1
            ? 0.0
            : size.width * i / (values.length - 1);
        final y = size.height - ((value - minValue) / range * size.height);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
      }
      canvas.drawPath(path, paint);
    }

    drawLine(
      points.map((point) => point.weight).toList(),
      const Color(0xff16a34a),
    );
    drawLine(
      points.map((point) => point.waistCm).toList(),
      const Color(0xffea580c),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}

String _formatDashboardDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

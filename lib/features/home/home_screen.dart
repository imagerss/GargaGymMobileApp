import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_logo.dart';
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
                  borderRadius: BorderRadius.circular(18),
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
                    const AppLogo(size: 44, borderRadius: 12),
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
                  const AppLogo(size: 42, borderRadius: 12),
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
              OutlinedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await controller.logout();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xffb91c1c),
                  side: const BorderSide(color: Color(0xfffecaca)),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Wyloguj'),
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
  static const _setDraftsKey = 'dashboard_session_set_drafts_v1';

  int? _selectedPlanId;
  int? _selectedTrendIndex;
  bool _loaded = false;
  bool _dashboardLoading = true;
  final _finishWeightController = TextEditingController();
  final _finishWaistController = TextEditingController();
  final _prefs = SharedPreferencesAsync();
  final _setValues = <String, _DashboardSetValue>{};
  XFile? _finishPhoto;

  @override
  void initState() {
    super.initState();
    widget.sessionsController.addListener(_changed);
    widget.measurementsController.addListener(_changed);
    widget.photosController.addListener(_changed);
    unawaited(_loadSetDrafts());
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
    setState(() => _dashboardLoading = true);
    try {
      await Future.wait([
        widget.sessionsController.load(),
        widget.measurementsController.load(),
        widget.photosController.load(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _dashboardLoading = false);
      }
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.sessionsController.refresh(),
      widget.measurementsController.refresh(),
      widget.photosController.refresh(),
    ]);
  }

  Future<void> _pickFinishPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
    );
    if (picked == null) return;
    setState(() => _finishPhoto = picked);
  }

  Future<void> _loadSetDrafts() async {
    final raw = await _prefs.getString(_setDraftsKey);
    if (raw == null) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    _setValues
      ..clear()
      ..addAll(
        decoded.map(
          (key, value) => MapEntry(
            key,
            value is Map<String, dynamic>
                ? _DashboardSetValue.fromJson(value)
                : _DashboardSetValue(),
          ),
        ),
      );
    if (mounted) setState(() {});
  }

  void _saveSetDrafts() {
    unawaited(
      _prefs.setString(
        _setDraftsKey,
        jsonEncode(
          _setValues.map((key, value) => MapEntry(key, value.toJson())),
        ),
      ),
    );
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
    unawaited(_prefs.remove(_setDraftsKey));
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
    final trendPoints = trend.length <= 12
        ? trend.map((measurement) => _DashboardTrendPoint(measurement)).toList()
        : trend
              .sublist(trend.length - 12)
              .map((measurement) => _DashboardTrendPoint(measurement))
              .toList();
    final photosByDate = photos
        .where((photo) => photo.photoPath != null || photo.localPath != null)
        .toList();
    final trendPointsWithPhotos = [
      for (final point in trendPoints)
        point.copyWith(photo: _nearestPhoto(point.measurement, photosByDate)),
    ];
    final selectedTrendIndex = trendPointsWithPhotos.isEmpty
        ? null
        : (_selectedTrendIndex ?? trendPointsWithPhotos.length - 1).clamp(
            0,
            trendPointsWithPhotos.length - 1,
          );
    final selectedTrendPoint = selectedTrendIndex == null
        ? null
        : trendPointsWithPhotos[selectedTrendIndex];
    if (_selectedPlanId != null &&
        !sessions.plans.any((plan) => plan.id == _selectedPlanId)) {
      _selectedPlanId = null;
    }

    if (_dashboardLoading) {
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
              const _DashboardLoadingState(),
            ],
          ),
        ),
      );
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: sessions.creating || _selectedPlanId == null
                          ? null
                          : () {
                              final plan = sessions.plans
                                  .where((item) => item.id == _selectedPlanId)
                                  .firstOrNull;
                              if (plan == null) return;
                              sessions.start(plan);
                            },
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: Text(
                        sessions.creating
                            ? 'Rozpoczynam...'
                            : 'Rozpocznij sesje teraz',
                      ),
                    ),
                  ),
                  if (activeSession != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.slate50,
                        borderRadius: BorderRadius.circular(8),
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
                                onChanged: _saveSetDrafts,
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
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      _pickFinishPhoto(ImageSource.camera),
                                  icon: const Icon(Icons.photo_camera),
                                  label: const Text('Aparat'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickFinishPhoto(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library),
                                  label: Text(
                                    _finishPhoto == null ? 'Galeria' : 'Zmien',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_finishPhoto != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _finishPhoto!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.slate500),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => _finishPhoto = null),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                                child: const Text('Usun zdjecie'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _completeActiveSession(activeSession),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Zakoncz aktywna sesje'),
                            ),
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
              child: trendPointsWithPhotos.isEmpty
                  ? const Text(
                      'Brak danych pomiarowych do wykresu.',
                      style: TextStyle(color: AppColors.slate500),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _DashboardTrendLegend(),
                        const SizedBox(height: 10),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) => _selectTrendPoint(
                                details.localPosition.dx,
                                constraints.maxWidth,
                                trendPointsWithPhotos.length,
                              ),
                              onHorizontalDragUpdate: (details) =>
                                  _selectTrendPoint(
                                    details.localPosition.dx,
                                    constraints.maxWidth,
                                    trendPointsWithPhotos.length,
                                  ),
                              child: SizedBox(
                                height: 230,
                                child: CustomPaint(
                                  painter: _TrendPainter(
                                    trendPointsWithPhotos,
                                    selectedIndex: selectedTrendIndex,
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _TrendPager(
                          selectedIndex: selectedTrendIndex ?? 0,
                          count: trendPointsWithPhotos.length,
                          onPrevious:
                              selectedTrendIndex == null ||
                                  selectedTrendIndex == 0
                              ? null
                              : () => setState(
                                  () => _selectedTrendIndex =
                                      selectedTrendIndex - 1,
                                ),
                          onNext:
                              selectedTrendIndex == null ||
                                  selectedTrendIndex ==
                                      trendPointsWithPhotos.length - 1
                              ? null
                              : () => setState(
                                  () => _selectedTrendIndex =
                                      selectedTrendIndex + 1,
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (selectedTrendPoint != null)
                          _TrendValueCard(point: selectedTrendPoint),
                        const SizedBox(height: 12),
                        if (selectedTrendPoint?.photo != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _DashboardPhoto(
                              photo: selectedTrendPoint!.photo!,
                              controller: widget.photosController,
                            ),
                          ),
                        ] else ...[
                          Container(
                            height: 180,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.slate200),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Brak powiazanego zdjecia dla tego punktu.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.slate500),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectTrendPoint(double dx, double width, int count) {
    if (count == 0) return;
    final index = _TrendPainter.indexForDx(dx, width, count);
    if (index == _selectedTrendIndex) return;
    setState(() => _selectedTrendIndex = index);
  }

  ProgressPhoto? _nearestPhoto(
    BodyMeasurement measurement,
    List<ProgressPhoto> photos,
  ) {
    const maxDiff = Duration(hours: 24);
    ProgressPhoto? nearest;
    Duration? nearestDiff;

    for (final photo in photos) {
      final diff = photo.takenAt.difference(measurement.measuredAt).abs();
      if (diff > maxDiff) continue;
      if (nearestDiff == null || diff < nearestDiff) {
        nearest = photo;
        nearestDiff = diff;
      }
    }

    return nearest;
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${exercise.exerciseName} - cel ${exercise.targetSets}x${exercise.targetReps}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var set = 1; set <= exercise.targetSets; set++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.slate50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Seria $set',
                    style: const TextStyle(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(
                            '$sessionId-${exercise.id}-$set-weight-${_valueFor(set).weight}',
                          ),
                          initialValue: _valueFor(set).weight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'kg'),
                          onChanged: (value) {
                            _valueFor(set).weight = value;
                            onChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          key: ValueKey(
                            '$sessionId-${exercise.id}-$set-reps-${_valueFor(set).reps}',
                          ),
                          initialValue: _valueFor(set).reps,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Powtorzenia',
                          ),
                          onChanged: (value) {
                            _valueFor(set).reps = value;
                            onChanged();
                          },
                        ),
                      ),
                    ],
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

  _DashboardSetValue();

  factory _DashboardSetValue.fromJson(Map<String, dynamic> json) =>
      _DashboardSetValue()
        ..weight = json['weight'] as String? ?? ''
        ..reps = json['reps'] as String? ?? '';

  Map<String, dynamic> toJson() => {'weight': weight, 'reps': reps};
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate200),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.slate900,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Ladowanie dashboardu',
            style: TextStyle(
              color: AppColors.slate900,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text('Prosze czekac', style: TextStyle(color: AppColors.slate500)),
        ],
      ),
    );
  }
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
        borderRadius: BorderRadius.circular(12),
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

class _DashboardTrendLegend extends StatelessWidget {
  const _DashboardTrendLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _TrendLegendItem(color: Color(0xff16a34a), label: 'Waga'),
        SizedBox(width: 14),
        _TrendLegendItem(color: Color(0xffea580c), label: 'Talia'),
      ],
    );
  }
}

class _TrendLegendItem extends StatelessWidget {
  const _TrendLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.slate700,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrendPager extends StatelessWidget {
  const _TrendPager({
    required this.selectedIndex,
    required this.count,
    required this.onPrevious,
    required this.onNext,
  });

  final int selectedIndex;
  final int count;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Poprzedni pomiar',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${selectedIndex + 1}/$count',
              style: const TextStyle(
                color: AppColors.slate500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Nastepny pomiar',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _TrendValueCard extends StatelessWidget {
  const _TrendValueCard({required this.point});

  final _DashboardTrendPoint point;

  @override
  Widget build(BuildContext context) {
    final measurement = point.measurement;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDashboardDate(measurement.measuredAt),
                  style: const TextStyle(color: AppColors.slate500),
                ),
                const SizedBox(height: 3),
                Text(
                  'Waga: ${measurement.weight ?? '-'} kg | Talia: ${measurement.waistCm ?? '-'} cm',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Icon(
            point.photo == null
                ? Icons.photo_camera_outlined
                : Icons.photo_camera,
            color: point.photo == null
                ? AppColors.slate200
                : AppColors.slate700,
          ),
        ],
      ),
    );
  }
}

class _DashboardTrendPoint {
  const _DashboardTrendPoint(this.measurement, {this.photo});

  final BodyMeasurement measurement;
  final ProgressPhoto? photo;

  _DashboardTrendPoint copyWith({ProgressPhoto? photo}) {
    return _DashboardTrendPoint(measurement, photo: photo ?? this.photo);
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, {this.selectedIndex});

  static const _leftPadding = 38.0;
  static const _rightPadding = 10.0;
  static const _topPadding = 12.0;
  static const _bottomPadding = 34.0;

  final List<_DashboardTrendPoint> points;
  final int? selectedIndex;

  static int indexForDx(double dx, double width, int count) {
    if (count <= 1) return 0;
    final chartWidth = (width - _leftPadding - _rightPadding).clamp(
      1.0,
      double.infinity,
    );
    final ratio = ((dx - _leftPadding) / chartWidth).clamp(0.0, 1.0);
    return (ratio * (count - 1)).round();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final weightValues = points
        .map((point) => point.measurement.weight)
        .nonNulls
        .toList();
    final waistValues = points
        .map((point) => point.measurement.waistCm)
        .nonNulls
        .toList();
    final allValues = [...weightValues, ...waistValues];
    if (allValues.isEmpty) return;

    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 0.01
        ? 1.0
        : maxValue - minValue;
    final chartRect = Rect.fromLTWH(
      _leftPadding,
      _topPadding,
      size.width - _leftPadding - _rightPadding,
      size.height - _topPadding - _bottomPadding,
    );

    final gridPaint = Paint()
      ..color = AppColors.slate200
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = chartRect.top + chartRect.height * i / 3;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }
    _drawAxisLabel(canvas, maxValue, Offset(0, chartRect.top - 6));
    _drawAxisLabel(canvas, minValue, Offset(0, chartRect.bottom - 12));

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
            ? chartRect.left
            : chartRect.left + chartRect.width * i / (values.length - 1);
        final y =
            chartRect.bottom - ((value - minValue) / range * chartRect.height);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
      }
      canvas.drawPath(path, paint);
    }

    drawLine(
      points.map((point) => point.measurement.weight).toList(),
      const Color(0xff16a34a),
    );
    drawLine(
      points.map((point) => point.measurement.waistCm).toList(),
      const Color(0xffea580c),
    );

    final selected = selectedIndex;
    if (selected != null && selected >= 0 && selected < points.length) {
      final x = points.length == 1
          ? chartRect.left
          : chartRect.left + chartRect.width * selected / (points.length - 1);
      final markerPaint = Paint()
        ..color = AppColors.slate900.withValues(alpha: 0.16)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(x, chartRect.top),
        Offset(x, chartRect.bottom),
        markerPaint,
      );
      final selectedPoint = points[selected];
      _drawSelectedValue(
        canvas,
        x,
        selectedPoint.measurement.weight,
        minValue,
        range,
        chartRect,
        const Color(0xff16a34a),
      );
      _drawSelectedValue(
        canvas,
        x,
        selectedPoint.measurement.waistCm,
        minValue,
        range,
        chartRect,
        const Color(0xffea580c),
      );
      _drawDateLabel(canvas, selectedPoint.measurement.measuredAt, x, size);
    } else {
      _drawDateLabel(
        canvas,
        points.first.measurement.measuredAt,
        chartRect.left,
        size,
      );
      _drawDateLabel(
        canvas,
        points.last.measurement.measuredAt,
        chartRect.right,
        size,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.selectedIndex != selectedIndex;

  void _drawSelectedValue(
    Canvas canvas,
    double x,
    double? value,
    double minValue,
    double range,
    Rect chartRect,
    Color color,
  ) {
    if (value == null) return;
    final y =
        chartRect.bottom - ((value - minValue) / range * chartRect.height);
    canvas.drawCircle(Offset(x, y), 7, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(x, y), 5, Paint()..color = color);
  }

  void _drawAxisLabel(Canvas canvas, double value, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
        style: const TextStyle(color: AppColors.slate500, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _leftPadding - 4);
    painter.paint(canvas, offset);
  }

  void _drawDateLabel(Canvas canvas, DateTime value, double x, Size size) {
    final text =
        '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.slate500,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = (x - painter.width / 2).clamp(0.0, size.width - painter.width);
    painter.paint(canvas, Offset(dx, size.height - 22));
  }
}

String _formatDashboardDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../auth/auth_controller.dart';
import '../exercises/exercises_controller.dart';
import '../exercises/exercises_screen.dart';
import '../plans/workout_plans_controller.dart';
import '../plans/workout_plans_screen.dart';
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
  const _DashboardContent({required this.userName, required this.offline});

  final String? userName;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Witaj, ${userName ?? 'sportowcu'}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.slate950,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          offline
              ? 'Brak internetu. Nadal mozesz korzystac z zapisanych danych.'
              : 'Gotowy na kolejny trening?',
          style: const TextStyle(color: AppColors.slate700, height: 1.35),
        ),
        const SizedBox(height: 20),
        const _StatusTile(
          icon: Icons.event_available_outlined,
          title: 'Dzisiejszy trening',
          subtitle: 'Zaplanuj lub rozpocznij sesje treningowa.',
        ),
        const SizedBox(height: 12),
        const _StatusTile(
          icon: Icons.trending_up_outlined,
          title: 'Twoj progres',
          subtitle: 'Sprawdz pomiary, cele i ostatnie wyniki.',
        ),
        const SizedBox(height: 12),
        const _StatusTile(
          icon: Icons.fitness_center_outlined,
          title: 'Plany i cwiczenia',
          subtitle: 'Przegladaj swoje plany treningowe i baze cwiczen.',
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.slate900),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.slate500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../auth/auth_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.user;

    return Scaffold(
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
                      tooltip: 'Wyloguj',
                      onPressed: controller.logout,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Witaj, ${user?.name ?? 'sportowcu'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.slate950,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                controller.offline
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
          ),
        ),
      ),
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

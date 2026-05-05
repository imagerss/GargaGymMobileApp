import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../auth/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.user;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        width: double.infinity,
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
              'Profil',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.slate950,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _ProfileRow(label: 'Imie', value: user?.name ?? '-'),
            const SizedBox(height: 10),
            _ProfileRow(label: 'Email', value: user?.email ?? '-'),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: controller.logout,
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
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppColors.slate900, fontSize: 16),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

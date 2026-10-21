import 'package:flutter/material.dart';

import '../../../core/provider_role.dart';
import '../../../core/theme/app_theme.dart';

/// First screen after login/signup — decides which half of the app the
/// signed-in account sees. In the real app this should probably be
/// remembered (from the account record) rather than asked every launch;
/// this screen is here for the case where one account can act as either
/// (or for onboarding a brand-new partner account).
class RoleSelectScreen extends StatelessWidget {
  final ValueChanged<ProviderRole> onSelect;

  const RoleSelectScreen({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryForeground.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.primaryForeground.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_rounded,
                    size: 26,
                    color: AppColors.primaryForeground,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ALLCURO PARTNER',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                    color: AppColors.primaryForeground,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'How will you\nwork with us?',
                  style: appHeadingStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                    color: AppColors.primaryForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick one — you can switch later from settings.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryForeground.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 32),
                _RoleCard(
                  icon: Icons.medical_services_outlined,
                  title: "I'm a Nurse",
                  description:
                      'Accept shift requests, manage your schedule, and see job details.',
                  onTap: () => onSelect(ProviderRole.nurse),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.medical_information_outlined,
                  title: "I'm a Doctor / Physiotherapist",
                  description:
                      'Take home-visit consultations and therapy sessions on your schedule.',
                  onTap: () => onSelect(ProviderRole.clinician),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.apartment_rounded,
                  title: 'I run a Homecare Centre',
                  description:
                      'Manage bed availability and respond to placement requests.',
                  onTap: () => onSelect(ProviderRole.centre),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      side: BorderSide(
        color: AppColors.primaryForeground.withValues(alpha: 0.25),
      ),
    );
    return Material(
      color: AppColors.primaryForeground.withValues(alpha: 0.08),
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryForeground.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, size: 22, color: AppColors.primaryForeground),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.primaryForeground.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryForeground.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

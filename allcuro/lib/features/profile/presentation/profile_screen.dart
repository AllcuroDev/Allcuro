import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_shell.dart';
import '../../../core/ui/surface.dart';
import '../../auth/presentation/auth_view_model.dart';
import '../data/models/profile.dart';
import '../data/models/profile_menu_row.dart';
import 'profile_view_model.dart';

const _iconsByKey = <String, IconData>{
  'location': Icons.location_on_outlined,
  'badge': Icons.badge_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'gift': Icons.card_giftcard_outlined,
  'support': Icons.support_agent_outlined,
  'faq': Icons.help_outline_rounded,
};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    return AppShell(
      currentPath: '/profile',
      child: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => const Center(
          child: Text(
            'Could not load profile',
            style: TextStyle(color: AppColors.mutedForeground),
          ),
        ),
        data: (profile) => _ProfileBody(
          profile: profile,
          userProfile: authState.userProfile,
          onLogout: () async {
            await ref.read(authViewModelProvider.notifier).logout();
            if (context.mounted) {
              context.go('/welcome');
            }
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  final Profile profile;
  final Map<String, String> userProfile;
  final VoidCallback onLogout;

  const _ProfileBody({
    required this.profile,
    required this.userProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = userProfile['name'] ?? profile.name;
    final displayPhone = userProfile['phone'] != null && userProfile['phone']!.isNotEmpty
        ? '+91 ${userProfile['phone']}'
        : profile.phone;
    final displayEmail = userProfile['email'] ?? profile.email;
    final displayEmergency = userProfile['emergencyContact'] ?? '+91 98450 12345 (Family)';
    final displayLocation = userProfile['city'] ?? 'Indiranagar, Bengaluru';

    return ListView(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      children: [
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.ink),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.card, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    displayName.isNotEmpty
                        ? displayName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
                        : 'AK',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Light KYC Active · Short Stays Unlocked',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Contact information list
              _InfoRow(
                label: 'Phone Number',
                value: displayPhone,
                icon: Icons.phone_outlined,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Email',
                value: displayEmail,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Care Location',
                value: displayLocation,
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                label: 'Emergency Family SOS',
                value: displayEmergency,
                icon: Icons.emergency_outlined,
              ),

              const SizedBox(height: 28),
              const Text(
                'Account & Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: profile.menuRows
                    .map((r) => _MenuRowCard(row: r))
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Sign Out Button
              Surface(
                onTap: onLogout,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.destructive,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.destructive,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monitor_heart_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'ALLCURO · Healthcare, Made Simple v1.0',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Menu rows that open a page of their own, keyed by `ProfileMenuRow.iconKey`.
const _routesByKey = <String, String>{
  'faq': '/faq',
};

class _MenuRowCard extends StatelessWidget {
  final ProfileMenuRow row;

  const _MenuRowCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final icon = _iconsByKey[row.iconKey] ?? Icons.circle_outlined;
    final route = _routesByKey[row.iconKey];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
        onTap: route == null ? null : () => context.push(route),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    row.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

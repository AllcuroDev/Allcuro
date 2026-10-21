import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/provider_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/surface.dart';
import '../../../core/ui/tappable.dart';
import '../../../core/verification_status.dart';
import '../../auth/presentation/auth_view_model.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authViewModelProvider);
    final session = sessionAsync.valueOrNull;
    final notifier = ref.read(authViewModelProvider.notifier);
    final isCentre = session?.role == ProviderRole.centre;
    final isClinician = session?.role == ProviderRole.clinician;

    return Scaffold(
      backgroundColor: AppColors.card,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
                onPressed: onBack,
              )
            : null,
        title: Text(
          isCentre ? 'Centre Profile' : (isClinician ? 'Clinician Profile' : 'Nurse Profile'),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          isCentre ? 'SC' : (isClinician ? 'AR' : 'PS'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCentre
                                  ? 'Sanjeevani Elder Care Sanctuary'
                                  : (isClinician ? 'Dr. Arjun Rao' : 'Priya Sharma'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              isCentre
                                  ? 'Homecare Centre Partner · Bengaluru'
                                  : (isClinician
                                      ? 'Doctor / Physiotherapist · Bengaluru'
                                      : 'Registered Nurse (GNM) · Bengaluru'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (session != null) ...[
                    const SizedBox(height: 20),
                    isCentre
                        ? _CentreVerificationCard(
                            status: session.centreVerificationStatus,
                            onAdvance: (next) => notifier.setCentreVerificationStatus(next),
                          )
                        : _NurseVerificationCard(
                            status: session.practitionerVerificationStatus,
                            onAdvance: (next) => notifier.setPractitionerVerificationStatus(next),
                          ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.read(authViewModelProvider.notifier).logout(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.destructive,
                        side: const BorderSide(color: AppColors.destructive),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _StatusBadge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _NurseVerificationCard extends StatelessWidget {
  final NurseVerificationStatus status;
  final ValueChanged<NurseVerificationStatus> onAdvance;

  const _NurseVerificationCard({required this.status, required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      NurseVerificationStatus.incomplete => ('Incomplete', AppColors.mutedForeground, AppColors.secondary),
      NurseVerificationStatus.onboarding => ('Setup in progress', AppColors.warning, AppColors.warningSoft),
      NurseVerificationStatus.underReview => ('Under review', AppColors.warning, AppColors.warningSoft),
      NurseVerificationStatus.verified => ('Verified', AppColors.success, AppColors.successSoft),
    };

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verification status', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              _StatusBadge(label: label, color: color, bg: bg),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Complete remaining profile modules anytime. Verified profiles receive 3x more bookings.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mutedForeground, height: 1.35),
          ),
          const SizedBox(height: 16),

          // Progressive Onboarding Action Links
          _SetupActionTile(
            icon: Icons.folder_shared_outlined,
            title: 'Document Vault',
            subtitle: 'Aadhaar, Nursing Council & Degree certificates',
            isComplete: true,
            onTap: () => context.push('/nurse/documents'),
          ),
          const SizedBox(height: 8),
          _SetupActionTile(
            icon: Icons.health_and_safety_outlined,
            title: 'Medical Fitness & TB Report',
            subtitle: 'Upload annual fitness self-declaration',
            isComplete: false,
            onTap: () => context.push('/nurse/documents'),
          ),
          const SizedBox(height: 8),
          _SetupActionTile(
            icon: Icons.account_balance_outlined,
            title: 'Bank Account & Payout Setup',
            subtitle: 'Direct Razorpay Route deposits',
            isComplete: true,
            onTap: () => context.push('/nurse/earnings'),
          ),
          const SizedBox(height: 8),
          _SetupActionTile(
            icon: Icons.psychology_outlined,
            title: 'Skills & Specialisations',
            subtitle: 'ICU, Tracheostomy, Palliative Care tags',
            isComplete: true,
            onTap: () => context.push('/nurse/availability'),
          ),

          if (status == NurseVerificationStatus.underReview) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => onAdvance(NurseVerificationStatus.verified),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                'Demo: mark as verified',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CentreVerificationCard extends StatelessWidget {
  final CentreVerificationStatus status;
  final ValueChanged<CentreVerificationStatus> onAdvance;

  const _CentreVerificationCard({required this.status, required this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      CentreVerificationStatus.incomplete => ('Incomplete', AppColors.mutedForeground, AppColors.secondary),
      CentreVerificationStatus.onboarding => ('Setup in progress', AppColors.warning, AppColors.warningSoft),
      CentreVerificationStatus.pendingReview => ('Pending admin review', AppColors.warning, AppColors.warningSoft),
      CentreVerificationStatus.siteVisitScheduled => ('Site-visit scheduled', AppColors.warning, AppColors.warningSoft),
      CentreVerificationStatus.verified => ('Verified & live', AppColors.success, AppColors.successSoft),
    };
    final next = switch (status) {
      CentreVerificationStatus.onboarding => CentreVerificationStatus.siteVisitScheduled,
      CentreVerificationStatus.pendingReview => CentreVerificationStatus.siteVisitScheduled,
      CentreVerificationStatus.siteVisitScheduled => CentreVerificationStatus.verified,
      _ => null,
    };
    final nextLabel = switch (next) {
      CentreVerificationStatus.siteVisitScheduled => 'Demo: submit & schedule site visit',
      CentreVerificationStatus.verified => 'Demo: mark as verified & live',
      _ => null,
    };

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verification status', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
              _StatusBadge(label: label, color: color, bg: bg),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Complete facility compliance modules to make beds bookable for patients.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mutedForeground, height: 1.35),
          ),
          const SizedBox(height: 16),

          // Centre Progressive Setup Tiles
          _SetupActionTile(
            icon: Icons.gavel_outlined,
            title: 'Compliance & Legal NOCs',
            subtitle: 'CEA, Fire Safety, Biomedical waste clearance',
            isComplete: false,
            onTap: () => context.push('/centre/compliance'),
          ),
          const SizedBox(height: 8),
          _SetupActionTile(
            icon: Icons.people_outline_rounded,
            title: 'Staff Roster & Duty Nurses',
            subtitle: 'Manage nurse-to-patient staff ratios',
            isComplete: true,
            onTap: () => context.push('/centre/staff'),
          ),
          const SizedBox(height: 8),
          _SetupActionTile(
            icon: Icons.hotel_outlined,
            title: 'Room Inventory & Pricing',
            subtitle: 'AC private rooms, packages and photos',
            isComplete: true,
            onTap: () => context.push('/centre/rooms'),
          ),
          const SizedBox(height: 8),
          _SetupActionTile(
            icon: Icons.storefront_outlined,
            title: 'Public Listing Management',
            subtitle: 'Facility amenities, photos and brochure',
            isComplete: true,
            onTap: () => context.push('/centre/listing'),
          ),

          if (next != null && nextLabel != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => onAdvance(next),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                nextLabel,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isComplete;
  final VoidCallback onTap;

  const _SetupActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isComplete ? AppColors.primarySoft : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 17,
                color: isComplete ? AppColors.primary : AppColors.mutedForeground,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isComplete ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: isComplete ? AppColors.primary : AppColors.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }
}

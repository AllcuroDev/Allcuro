import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/provider_role.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/ui/tappable.dart';
import '../../../../core/ui/tool_tile.dart';
import '../../../../core/verification_status.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../auth/presentation/onboarding_view_model.dart';
import '../../data/models/job_request_summary.dart';
import '../../data/models/nurse_visit_model.dart';
import 'nurse_home_view_model.dart';

class NurseHomeScreen extends ConsumerWidget {
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;
  final VoidCallback onSeeAllRequests;
  final VoidCallback onSeeSchedule;
  final void Function(String requestId) onOpenRequest;
  final VoidCallback onOpenAvailability;
  final VoidCallback onOpenEarnings;
  final VoidCallback onOpenTraining;
  final VoidCallback onOpenRatings;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenReferral;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenBankAccount;
  final VoidCallback onOpenActiveVisit;

  const NurseHomeScreen({
    super.key,
    required this.onTabSelected,
    required this.onProfileTap,
    required this.onSeeAllRequests,
    required this.onSeeSchedule,
    required this.onOpenRequest,
    required this.onOpenAvailability,
    required this.onOpenEarnings,
    required this.onOpenTraining,
    required this.onOpenRatings,
    required this.onOpenDocuments,
    required this.onOpenReferral,
    required this.onOpenSupport,
    required this.onOpenBankAccount,
    required this.onOpenActiveVisit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(nurseHomeViewModelProvider);
    final session = ref.watch(authViewModelProvider).valueOrNull;
    final onboardingState = ref.watch(partnerOnboardingProvider);
    final status = session?.practitionerVerificationStatus ?? NurseVerificationStatus.incomplete;

    return ProviderShell(
      role: session?.role ?? ProviderRole.nurse,
      currentIndex: 0,
      onTabSelected: onTabSelected,
      onProfileTap: onProfileTap,
      initials: 'PS',
      child: summary.when(
        data: (data) => _NurseHomeContent(
          status: status,
          onboardingState: onboardingState,
          summary: data,
          onSeeAllRequests: onSeeAllRequests,
          onSeeSchedule: onSeeSchedule,
          onOpenRequest: onOpenRequest,
          onOpenAvailability: onOpenAvailability,
          onOpenEarnings: onOpenEarnings,
          onOpenTraining: onOpenTraining,
          onOpenRatings: onOpenRatings,
          onOpenDocuments: onOpenDocuments,
          onOpenReferral: onOpenReferral,
          onOpenSupport: onOpenSupport,
          onOpenBankAccount: onOpenBankAccount,
          onOpenActiveVisit: onOpenActiveVisit,
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(child: Text('Could not load dashboard: $error')),
      ),
    );
  }
}

class _NurseHomeContent extends ConsumerWidget {
  final NurseVerificationStatus status;
  final PartnerOnboardingState onboardingState;
  final NurseHomeSummary summary;
  final VoidCallback onSeeAllRequests;
  final VoidCallback onSeeSchedule;
  final void Function(String requestId) onOpenRequest;
  final VoidCallback onOpenAvailability;
  final VoidCallback onOpenEarnings;
  final VoidCallback onOpenTraining;
  final VoidCallback onOpenRatings;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenReferral;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenBankAccount;
  final VoidCallback onOpenActiveVisit;

  const _NurseHomeContent({
    required this.status,
    required this.onboardingState,
    required this.summary,
    required this.onSeeAllRequests,
    required this.onSeeSchedule,
    required this.onOpenRequest,
    required this.onOpenAvailability,
    required this.onOpenEarnings,
    required this.onOpenTraining,
    required this.onOpenRatings,
    required this.onOpenDocuments,
    required this.onOpenReferral,
    required this.onOpenSupport,
    required this.onOpenBankAccount,
    required this.onOpenActiveVisit,
  });

  void _showEmergencySosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxl)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.sosRedSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.sosRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Emergency SOS',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.sosRed, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Triggering SOS broadcasts your location to ALLCURO Emergency HQ and dials the 24x7 clinical command desk.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live GPS: 12.9716° N, 77.5946° E (Bengaluru)',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚨 Emergency SOS alert sent! Allcuro team is contacting you.'),
                  backgroundColor: AppColors.sosRed,
                  duration: Duration(seconds: 4),
                ),
              );
            },
            icon: const Icon(Icons.phone_in_talk, size: 16),
            label: const Text('Call Allcuro SOS HQ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sosRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = status == NurseVerificationStatus.verified;
    final isUnderReview = status == NurseVerificationStatus.underReview;
    final nextShift = summary.nextShift;
    final activeVisit = summary.activeVisit;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ========================================================
        // 1. TOP HEADER & DUTY SWITCH BAR
        // ========================================================
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good morning,',
                        style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
                      ),
                      Text(
                        'Priya Sharma',
                        style: appHeadingStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                    ],
                  ),
                  // Emergency Panic SOS Button
                  Tappable(
                    onTap: () => _showEmergencySosDialog(context),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.sosRed,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.sosRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emergency, color: Colors.white, size: 15),
                          SizedBox(width: 4),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Duty Status & Shift Timing Quick Toggle
              if (isVerified)
                _DutyStatusQuickBar(
                  isOnDuty: summary.isOnDuty,
                  shiftTiming: summary.shiftTiming,
                  onToggleDuty: (val) {
                    ref.read(nurseHomeViewModelProvider.notifier).toggleDutyStatus(val);
                  },
                  onTapTiming: onOpenAvailability,
                ),
            ],
          ),
        ),

        // ========================================================
        // STAGE 1: ONBOARDING & ACTIVATION HUB (INCOMPLETE ONLY)
        // (Excluded from daily view when verified)
        // ========================================================
        if (!isVerified && !isUnderReview) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _NurseSetupHub(
              onboarding: onboardingState,
              onOpenDocuments: onOpenDocuments,
              onOpenBankAccount: onOpenBankAccount,
              onOpenAvailability: onOpenAvailability,
              onSubmitForReview: () async {
                await ref.read(partnerOnboardingProvider.notifier).submitNurseForReview();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile submitted for nursing council verification!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ),
        ],

        // ========================================================
        // STAGE 2: UNDER REVIEW BANNER
        // ========================================================
        if (isUnderReview) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _NurseUnderReviewCard(
              onAdvanceToVerified: () {
                ref.read(authViewModelProvider.notifier).setPractitionerVerificationStatus(
                      NurseVerificationStatus.verified,
                    );
              },
            ),
          ),
        ],

        // ========================================================
        // STAGE 3: ACTIONABLE PRIORITY DASHBOARD (VERIFIED)
        // ========================================================
        if (isVerified) ...[
          // Priority Actionable Task Card (Urban Clap style)
          if (activeVisit != null && activeVisit.status != VisitStatus.completed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _ActiveVisitActionCard(
                visit: activeVisit,
                onOpenExecution: onOpenActiveVisit,
              ),
            ),

          // Stat Cards (Coral / soft amber highlights)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Pending requests',
                    value: '${summary.pendingRequestCount}',
                    color: AppColors.coral,
                    bg: AppColors.coralSoft,
                    badge: 'Action Required',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Shifts this week',
                    value: '${summary.shiftsThisWeek}',
                    color: AppColors.primary,
                    bg: AppColors.primarySoft,
                    badge: 'Scheduled',
                  ),
                ),
              ],
            ),
          ),

          // Next Shift Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Schedule',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink),
                ),
                Tappable(
                  onTap: onSeeSchedule,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'View schedule',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: nextShift == null
                ? const Surface(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No upcoming shifts right now',
                      style: TextStyle(color: AppColors.mutedForeground),
                    ),
                  )
                : Surface(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available_outlined, size: 20, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nextShift.timing,
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                              Text(
                                '${nextShift.serviceType} · ${nextShift.patientName} · ${nextShift.locality}',
                                style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // New Patient Shift Requests
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Patient Requests',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink),
                ),
                Tappable(
                  onTap: onSeeAllRequests,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'See all',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: summary.previewRequests.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No pending requests right now', style: TextStyle(color: AppColors.mutedForeground)),
                  )
                : Column(
                    children: summary.previewRequests
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RequestPreviewCard(
                              request: r,
                              onTap: () => onOpenRequest(r.id),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],

        // ========================================================
        // 4. NURSING TOOLS & PRACTICE GRID
        // ========================================================
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            isVerified ? 'Nursing Tools & Practice' : 'Setup Modules',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.82,
            children: [
              ToolTile(icon: Icons.schedule_outlined, label: 'Availability', onTap: onOpenAvailability),
              ToolTile(icon: Icons.analytics_outlined, label: 'Performance', onTap: onOpenRatings),
              ToolTile(icon: Icons.account_balance_outlined, label: 'Bank Payout', onTap: onOpenBankAccount),
              ToolTile(icon: Icons.payments_outlined, label: 'Earnings', onTap: onOpenEarnings),
              ToolTile(icon: Icons.folder_outlined, label: 'Documents', onTap: onOpenDocuments),
              ToolTile(icon: Icons.school_outlined, label: 'Training', onTap: onOpenTraining),
              ToolTile(icon: Icons.card_giftcard_outlined, label: 'Referral', onTap: onOpenReferral),
              ToolTile(icon: Icons.support_agent_outlined, label: '24x7 SOS', onTap: onOpenSupport),
            ],
          ),
        ),
      ],
    );
  }
}

class _DutyStatusQuickBar extends StatelessWidget {
  final bool isOnDuty;
  final String shiftTiming;
  final ValueChanged<bool> onToggleDuty;
  final VoidCallback onTapTiming;

  const _DutyStatusQuickBar({
    required this.isOnDuty,
    required this.shiftTiming,
    required this.onToggleDuty,
    required this.onTapTiming,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOnDuty ? AppColors.successSoft.withValues(alpha: 0.7) : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isOnDuty ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isOnDuty ? AppColors.success : AppColors.mutedForeground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnDuty ? 'ON-DUTY (Available for shifts)' : 'OFF-DUTY (Paused)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isOnDuty ? AppColors.success : AppColors.mutedForeground,
                  ),
                ),
                InkWell(
                  onTap: onTapTiming,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Timing: $shiftTiming',
                        style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOnDuty,
            onChanged: onToggleDuty,
            activeTrackColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _ActiveVisitActionCard extends StatelessWidget {
  final NurseVisit visit;
  final VoidCallback onOpenExecution;

  const _ActiveVisitActionCard({
    required this.visit,
    required this.onOpenExecution,
  });

  @override
  Widget build(BuildContext context) {
    final isReached = visit.status == VisitStatus.reached;
    final isInProgress = visit.status == VisitStatus.inProgress;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isInProgress ? 'ACTIVE IN-PROGRESS VISIT' : (isReached ? 'ARRIVED AT LOCATION' : 'CURRENT BOOKING ACTION'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                visit.bookingId,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_pin_circle_outlined, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${visit.patientName} (${visit.patientAge}y, ${visit.patientGender})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.medicalCondition,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.coral),
                    ),
                    Text(
                      visit.locality,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🗺️ Navigating to ${visit.address}...'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation_outlined, size: 14),
                  label: const Text('Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📞 Dialing ${visit.patientPhone}...'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone_in_talk, size: 14),
                  label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onOpenExecution,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    isInProgress ? 'Clinical Log' : 'Start Visit',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final String badge;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestPreviewCard extends StatelessWidget {
  final JobRequestSummary request;
  final VoidCallback onTap;

  const _RequestPreviewCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Surface(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.coralSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: AppColors.coral, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.serviceType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink),
                ),
                Text(
                  '${request.patientName} · ${request.locality}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            request.pay,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedForeground, size: 18),
        ],
      ),
    );
  }
}

class _NurseSetupHub extends StatelessWidget {
  final PartnerOnboardingState onboarding;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenBankAccount;
  final VoidCallback onOpenAvailability;
  final VoidCallback onSubmitForReview;

  const _NurseSetupHub({
    required this.onboarding,
    required this.onOpenDocuments,
    required this.onOpenBankAccount,
    required this.onOpenAvailability,
    required this.onSubmitForReview,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = onboarding.nurseCompletedStepsCount;
    final percentage = (onboarding.nurseCompletionPercentage * 100).toInt();
    final canSubmit = onboarding.canSubmitNurseForReview;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Profile & KYC Activation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$completedCount of 6 Done ($percentage%)',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: onboarding.nurseCompletionPercentage,
              minHeight: 7,
              backgroundColor: AppColors.secondary,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload govt ID, council & HPR registry, bank details, and declare skills to activate patient matching.',
            style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground, height: 1.35),
          ),
          const SizedBox(height: 14),

          _NurseCheckTile(
            stepNumber: 1,
            title: 'Basic Profile & Qualification',
            subtitle: 'GNM qualification & clinical experience registered',
            isComplete: onboarding.nurseProfileDone,
            statusLabel: 'Done',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _NurseCheckTile(
            stepNumber: 2,
            title: 'Document Vault & HPR Registration',
            subtitle: 'Govt ID, State Nursing Council & ABHA-HPR license',
            isComplete: onboarding.nurseDocsDone,
            statusLabel: onboarding.nurseDocsDone ? 'Uploaded' : 'Upload Docs',
            onTap: onOpenDocuments,
          ),
          const SizedBox(height: 8),
          _NurseCheckTile(
            stepNumber: 3,
            title: 'Medical Fitness & TB Screening',
            subtitle: 'Annual health declaration for home care safety',
            isComplete: onboarding.nurseMedicalFitnessComplete,
            statusLabel: onboarding.nurseMedicalFitnessComplete ? 'Completed' : 'Upload Report',
            onTap: onOpenDocuments,
          ),
          const SizedBox(height: 8),
          _NurseCheckTile(
            stepNumber: 4,
            title: 'Bank Account & Payout Setup',
            subtitle: 'Razorpay Route direct split deposits',
            isComplete: onboarding.nurseBankDone,
            statusLabel: onboarding.nurseBankDone ? 'Configured' : 'Add Bank Info',
            onTap: onOpenBankAccount,
          ),
          const SizedBox(height: 8),
          _NurseCheckTile(
            stepNumber: 5,
            title: 'Skills, Specialisations & Shift Rates',
            subtitle: '${onboarding.nurseSkills.length} skills selected · ₹${onboarding.nurseDailyRate.toInt()}/day',
            isComplete: onboarding.nurseSkillsDone,
            statusLabel: onboarding.nurseSkillsDone ? 'Configured' : 'Configure',
            onTap: onOpenAvailability,
          ),
          const SizedBox(height: 8),
          _NurseCheckTile(
            stepNumber: 6,
            title: 'Police Background Clearance Consent',
            subtitle: 'Automated background clearance check via Aadhaar',
            isComplete: onboarding.nursePoliceDone,
            statusLabel: 'Consented',
            onTap: () {},
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? onSubmitForReview : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.accentForeground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                elevation: 0,
              ),
              child: const Text(
                'Submit Profile for Admin Verification',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NurseUnderReviewCard extends StatelessWidget {
  final VoidCallback onAdvanceToVerified;

  const _NurseUnderReviewCard({required this.onAdvanceToVerified});

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Profile Under Verification',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'Under Review',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your documents and police background clearance are being verified by ALLCURO ops. Verified nurses get instant access to shift requests.',
            style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground, height: 1.35),
          ),
          const SizedBox(height: 14),
          _AuditStepRow(title: 'Aadhaar ID & Face-Match Verification', isDone: true, time: 'Passed (98.4%)'),
          _AuditStepRow(title: 'Nursing Council & HPR Registry Cross-Check', isDone: true, time: 'Passed'),
          _AuditStepRow(title: 'Police Background Verification Clearance', isDone: true, time: 'Clean Record'),
          _AuditStepRow(title: 'ALLCURO Nurse Badge & Shift Matching', isDone: false, time: 'Final Review'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Simulate admin approval to unlock live shifts.',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onAdvanceToVerified,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  child: const Text('Approve & Go Live', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditStepRow extends StatelessWidget {
  final String title;
  final bool isDone;
  final String time;

  const _AuditStepRow({required this.title, required this.isDone, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: isDone ? AppColors.success : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                    color: isDone ? AppColors.ink : AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NurseCheckTile extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final bool isComplete;
  final String statusLabel;
  final VoidCallback onTap;

  const _NurseCheckTile({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.isComplete,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isComplete ? AppColors.card : AppColors.secondary.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isComplete ? AppColors.border : AppColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isComplete ? AppColors.successSoft : AppColors.warningSoft,
                shape: BoxShape.circle,
              ),
              child: isComplete
                  ? const Icon(Icons.check_rounded, size: 13, color: AppColors.success)
                  : Text(
                      '$stepNumber',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.warning),
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isComplete ? AppColors.successSoft : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isComplete ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.mutedForeground),
          ],
        ),
      ),
    );
  }
}

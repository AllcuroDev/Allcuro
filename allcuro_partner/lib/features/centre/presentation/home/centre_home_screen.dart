import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/provider_role.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/surface.dart';
import '../../../../core/ui/tappable.dart';
import '../../../../core/ui/tool_tile.dart';
import '../../../../core/verification_status.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../../auth/presentation/onboarding_view_model.dart';
import '../../data/models/placement_request_summary.dart';
import 'centre_home_view_model.dart';

class CentreHomeScreen extends ConsumerWidget {
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;
  final VoidCallback onSeeAllRequests;
  final VoidCallback onSeeRooms;
  final VoidCallback onOpenListing;
  final VoidCallback onOpenRevenue;
  final VoidCallback onOpenReviews;
  final VoidCallback onOpenCompliance;
  final VoidCallback onOpenStaff;
  final VoidCallback onOpenPromotions;
  final VoidCallback onOpenEquipment;
  final VoidCallback onOpenBankAccount;

  const CentreHomeScreen({
    super.key,
    required this.onTabSelected,
    required this.onProfileTap,
    required this.onSeeAllRequests,
    required this.onSeeRooms,
    required this.onOpenListing,
    required this.onOpenRevenue,
    required this.onOpenReviews,
    required this.onOpenCompliance,
    required this.onOpenStaff,
    required this.onOpenPromotions,
    required this.onOpenEquipment,
    required this.onOpenBankAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(centreHomeViewModelProvider);
    final session = ref.watch(authViewModelProvider).valueOrNull;
    final onboardingState = ref.watch(partnerOnboardingProvider);
    final status = session?.centreVerificationStatus ?? CentreVerificationStatus.incomplete;

    return ProviderShell(
      role: ProviderRole.centre,
      currentIndex: 0,
      onTabSelected: onTabSelected,
      onProfileTap: onProfileTap,
      initials: ref.watch(authViewModelProvider).valueOrNull?.initials ?? 'P',
      child: summary.when(
        data: (data) => _CentreHomeContent(
          status: status,
          centreName: session?.displayName ?? 'Your centre',
          siteVisitAt: session?.centreSiteVisitAt,
          onboardingState: onboardingState,
          summary: data,
          onSeeAllRequests: onSeeAllRequests,
          onSeeRooms: onSeeRooms,
          onOpenListing: onOpenListing,
          onOpenRevenue: onOpenRevenue,
          onOpenReviews: onOpenReviews,
          onOpenCompliance: onOpenCompliance,
          onOpenStaff: onOpenStaff,
          onOpenPromotions: onOpenPromotions,
          onOpenEquipment: onOpenEquipment,
          onOpenBankAccount: onOpenBankAccount,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load dashboard: $error')),
      ),
    );
  }
}

class _CentreHomeContent extends ConsumerWidget {
  final CentreVerificationStatus status;
  final String centreName;
  final DateTime? siteVisitAt;
  final PartnerOnboardingState onboardingState;
  final CentreHomeSummary summary;
  final VoidCallback onSeeAllRequests;
  final VoidCallback onSeeRooms;
  final VoidCallback onOpenListing;
  final VoidCallback onOpenRevenue;
  final VoidCallback onOpenReviews;
  final VoidCallback onOpenCompliance;
  final VoidCallback onOpenStaff;
  final VoidCallback onOpenPromotions;
  final VoidCallback onOpenEquipment;
  final VoidCallback onOpenBankAccount;

  const _CentreHomeContent({
    required this.status,
    required this.centreName,
    required this.siteVisitAt,
    required this.onboardingState,
    required this.summary,
    required this.onSeeAllRequests,
    required this.onSeeRooms,
    required this.onOpenListing,
    required this.onOpenRevenue,
    required this.onOpenReviews,
    required this.onOpenCompliance,
    required this.onOpenStaff,
    required this.onOpenPromotions,
    required this.onOpenEquipment,
    required this.onOpenBankAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVerified = status == CentreVerificationStatus.verified;
    final isUnderReview = status == CentreVerificationStatus.pendingReview ||
        status == CentreVerificationStatus.siteVisitScheduled;

    final totalBeds = onboardingState.rooms.fold<int>(0, (sum, r) => sum + r.beds.length);
    final occupiedBeds = onboardingState.rooms.fold<int>(
      0,
      (sum, r) => sum + r.beds.where((b) => b.occupied).length,
    );
    final occupancy = totalBeds == 0 ? 0.0 : occupiedBeds / totalBeds;
    final vacant = totalBeds - occupiedBeds;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning,',
                style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
              ),
              Text(
                centreName,
                style: appHeadingStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
              const SizedBox(height: 16),

              // ========================================================
              // STAGE 1: ONBOARDING & ACTIVATION HUB (INCOMPLETE)
              // ========================================================
              if (!isVerified && !isUnderReview) ...[
                _SetupProgressHub(
                  onboarding: onboardingState,
                  onOpenCompliance: onOpenCompliance,
                  onOpenBankAccount: onOpenBankAccount,
                  onOpenRooms: onSeeRooms,
                  onOpenStaff: onOpenStaff,
                  onOpenEquipment: onOpenEquipment,
                  onSubmitForReview: () async {
                    await ref.read(partnerOnboardingProvider.notifier).submitCentreForReview();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Application submitted. ALLCURO will review it and schedule a site visit.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              ],

              // ========================================================
              // STAGE 2: UNDER REVIEW & SITE-VISIT SCHEDULED
              // ========================================================
              if (isUnderReview) ...[
                _SiteVisitTimelineCard(
                  status: status,
                  siteVisitAt: siteVisitAt,
                  onboarding: onboardingState,
                  onOpenCompliance: onOpenCompliance,
                  onOpenRooms: onSeeRooms,
                  onOpenEquipment: onOpenEquipment,
                  onAdvanceToVerified: () {
                    ref.read(authViewModelProvider.notifier).setCentreVerificationStatus(
                          CentreVerificationStatus.verified,
                        );
                  },
                ),
              ],

              // ========================================================
              // STAGE 3: VERIFIED LIVE DASHBOARD
              // ========================================================
              if (isVerified) ...[
                Surface(
                  onTap: onSeeRooms,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bed occupancy',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          Text(
                            '$occupiedBeds / $totalBeds beds',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: occupancy,
                          minHeight: 10,
                          backgroundColor: AppColors.secondary,
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$vacant beds vacant · tap to manage rooms & admissions',
                        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                if (totalBeds == 0) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No beds added yet. Add rooms & beds so families can see availability.',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Pending requests',
                        value: '${summary.pendingRequestCount}',
                        color: AppColors.warning,
                        bg: AppColors.warningSoft,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Admitted this month',
                        value: '${summary.admittedThisMonth}',
                        color: AppColors.primary,
                        bg: AppColors.primarySoft,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Live Placement Requests
        if (isVerified) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New placement requests',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Tappable(
                  onTap: onSeeAllRequests,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: summary.previewRequests.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "No placement requests yet. You'll see them here once families start enquiring.",
                      style: TextStyle(color: AppColors.mutedForeground),
                    ),
                  )
                : Column(
                    children: summary.previewRequests
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RequestPreviewCard(request: r, onTap: onSeeAllRequests),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],

        // Facility Management & Quick Tools Grid
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            isVerified ? 'Facility Management & Tools' : 'Manage Facility Modules',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.92,
            children: [
              ToolTile(icon: Icons.hotel_outlined, label: 'Rooms & Beds', onTap: onSeeRooms),
              ToolTile(icon: Icons.medical_services_outlined, label: 'Equipment', onTap: onOpenEquipment),
              ToolTile(icon: Icons.people_outline_rounded, label: 'Care Staff', onTap: onOpenStaff),
              ToolTile(icon: Icons.account_balance_outlined, label: 'Bank Payout', onTap: onOpenBankAccount),
              ToolTile(icon: Icons.verified_outlined, label: 'Compliance', onTap: onOpenCompliance),
              ToolTile(icon: Icons.storefront_outlined, label: 'Listing', onTap: onOpenListing),
              ToolTile(icon: Icons.account_balance_wallet_outlined, label: 'Revenue', onTap: onOpenRevenue),
              ToolTile(icon: Icons.star_outline_rounded, label: 'Reviews', onTap: onOpenReviews),
              ToolTile(icon: Icons.campaign_outlined, label: 'Promotions', onTap: onOpenPromotions),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupProgressHub extends StatelessWidget {
  final PartnerOnboardingState onboarding;
  final VoidCallback onOpenCompliance;
  final VoidCallback onOpenBankAccount;
  final VoidCallback onOpenRooms;
  final VoidCallback onOpenStaff;
  final VoidCallback onOpenEquipment;
  final VoidCallback onSubmitForReview;

  const _SetupProgressHub({
    required this.onboarding,
    required this.onOpenCompliance,
    required this.onOpenBankAccount,
    required this.onOpenRooms,
    required this.onOpenStaff,
    required this.onOpenEquipment,
    required this.onSubmitForReview,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = onboarding.centreCompletedStepsCount;
    final percentage = (onboarding.centreCompletionPercentage * 100).toInt();
    final canSubmit = onboarding.canSubmitCentreForReview;

    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Facility Activation Setup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
              value: onboarding.centreCompletionPercentage,
              minHeight: 7,
              backgroundColor: AppColors.secondary,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete mandatory statutory documents, bank details, and room/equipment inventory before sending for ALLCURO review & on-site audit.',
            style: TextStyle(fontSize: 11.5, color: AppColors.mutedForeground, height: 1.35),
          ),
          const SizedBox(height: 14),

          // Steps list
          _SetupCheckTile(
            stepNumber: 1,
            title: 'Entity & Facility Details',
            subtitle: 'Entity name, registration number & address',
            isComplete: onboarding.centreEntityDone,
            statusLabel: 'Done',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _SetupCheckTile(
            stepNumber: 2,
            title: 'Regulatory & KYC Compliance',
            subtitle: 'CEA license, Fire NOC & Bio-waste clearance',
            isComplete: onboarding.centreDocsDone,
            statusLabel: onboarding.centreDocsDone ? 'Uploaded' : 'Upload Docs',
            onTap: onOpenCompliance,
          ),
          const SizedBox(height: 8),
          _SetupCheckTile(
            stepNumber: 3,
            title: 'Bank Account & Payout Setup',
            subtitle: 'Razorpay Route split settlement bank info',
            isComplete: onboarding.centreBankDone,
            statusLabel: onboarding.centreBankDone ? 'Configured' : 'Add Bank Info',
            onTap: onOpenBankAccount,
          ),
          const SizedBox(height: 8),
          _SetupCheckTile(
            stepNumber: 4,
            title: 'Rooms & Bed Inventory',
            subtitle: '${onboarding.rooms.length} room(s) and bed capacity configured',
            isComplete: onboarding.centreRoomsDone,
            statusLabel: onboarding.centreRoomsDone ? '${onboarding.rooms.length} Rooms' : 'Add Rooms',
            onTap: onOpenRooms,
          ),
          const SizedBox(height: 8),
          _SetupCheckTile(
            stepNumber: 5,
            title: 'In-House Nursing & Care Staff',
            subtitle: '${onboarding.staffMembers.length} active duty staff in roster',
            isComplete: onboarding.centreStaffDone,
            statusLabel: onboarding.centreStaffDone ? '${onboarding.staffMembers.length} Staff' : 'Add Nurses',
            onTap: onOpenStaff,
          ),
          const SizedBox(height: 8),
          _SetupCheckTile(
            stepNumber: 6,
            title: 'Medical Equipment & Rentals',
            subtitle: '${onboarding.equipmentList.length} rental equipment items listed',
            isComplete: onboarding.centreEquipmentDone,
            statusLabel: onboarding.centreEquipmentDone ? '${onboarding.equipmentList.length} Items' : 'Add Equipment',
            onTap: onOpenEquipment,
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
                'Submit for Review & Schedule Site Visit',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteVisitTimelineCard extends StatelessWidget {
  final CentreVerificationStatus status;
  final DateTime? siteVisitAt;
  final PartnerOnboardingState onboarding;
  final VoidCallback onOpenCompliance;
  final VoidCallback onOpenRooms;
  final VoidCallback onOpenEquipment;
  final VoidCallback onAdvanceToVerified;

  const _SiteVisitTimelineCard({
    required this.status,
    required this.siteVisitAt,
    required this.onboarding,
    required this.onOpenCompliance,
    required this.onOpenRooms,
    required this.onOpenEquipment,
    required this.onAdvanceToVerified,
  });

  static String _formatVisit(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final visitScheduled = status == CentreVerificationStatus.siteVisitScheduled;
    final visitAt = siteVisitAt;
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Application Under Review',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  visitScheduled ? 'Site Visit Scheduled' : 'Under Review',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.calendar_month_rounded, size: 15, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        visitAt != null
                            ? 'Site visit: ${_formatVisit(visitAt)}'
                            : 'Site visit: not scheduled yet',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  visitAt != null
                      ? 'An ALLCURO team member will visit to check bed count, fire clearances, biomedical waste protocols and room hygiene.'
                      : 'ALLCURO will review your application and contact you to schedule an on-site inspection.',
                  style: const TextStyle(fontSize: 11, color: AppColors.mutedForeground, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Verification Checklist & Audit Trail',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 10),
          const _AuditStepRow(title: 'Application & documents submitted', isDone: true, time: 'Submitted'),
          const _AuditStepRow(
            title: 'Document & licence verification',
            isDone: false,
            time: 'Awaiting ALLCURO review',
          ),
          _AuditStepRow(
            title: 'On-site inspection',
            isDone: false,
            time: visitAt != null ? 'Scheduled for ${_formatVisit(visitAt)}' : 'Not scheduled yet',
          ),
          const _AuditStepRow(title: 'Approval & listing goes live', isDone: false, time: 'Awaiting ALLCURO review'),

          // Demo-build-only advance action (no Supabase keys).
          if (AuthService.isDemo) ...[
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
                    'Demo build only: simulate admin approval.',
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

class _SetupCheckTile extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final bool isComplete;
  final String statusLabel;
  final VoidCallback onTap;

  const _SetupCheckTile({
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestPreviewCard extends StatelessWidget {
  final PlacementRequestSummary request;
  final VoidCallback onTap;

  const _RequestPreviewCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Surface(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.careType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(
                  request.familyContact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedForeground),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../data/models/nurse_performance_model.dart';
import 'nurse_performance_view_model.dart';

class PerformanceScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const PerformanceScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(nursePerformanceViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Performance & Reviews',
              subtitle: 'Attendance, quality metrics & patient ratings',
              onBack: onBack,
            ),
            Expanded(
              child: performanceAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (perf) => !perf.hasActivity
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                        children: const [
                          EmptyState(
                            icon: Icons.analytics_outlined,
                            title: 'No performance data yet',
                            message:
                                'Your attendance, ratings and reviews will appear here after your first completed visit.',
                          ),
                        ],
                      )
                    : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _buildOverviewGrid(perf),
                    const SizedBox(height: 14),
                    _buildRatingBreakdownCard(perf),
                    const SizedBox(height: 14),
                    _buildEarningsMiniCard(perf),
                    const SizedBox(height: 14),
                    _buildComplaintsCard(perf),
                    const SizedBox(height: 18),
                    const Text(
                      'Customer Reviews & Booking Feedback',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                    ),
                    const SizedBox(height: 10),
                    if (perf.feedbacks.isEmpty)
                      const EmptyState(message: 'No reviews yet.')
                    else
                      ...perf.feedbacks.map((f) => _FeedbackTile(feedback: f)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(NursePerformance perf) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.star_rounded,
                iconColor: AppColors.amber,
                iconBg: AppColors.amberSoft,
                value: perf.hasRatings ? '${perf.averageRating.toStringAsFixed(1)} ★' : '—',
                label: 'Average Rating',
                sublabel: perf.hasRatings ? 'from ${perf.totalRatingsCount} reviews' : 'No reviews yet',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.task_alt_rounded,
                iconColor: AppColors.primary,
                iconBg: AppColors.primarySoft,
                value: '${perf.totalJobsCompleted}',
                label: 'Jobs Completed',
                sublabel: '${perf.monthlyJobsCompleted} this month',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.event_available_rounded,
                iconColor: AppColors.success,
                iconBg: AppColors.successSoft,
                value: '${perf.attendanceRate}%',
                label: 'Attendance Rate',
                sublabel: '${perf.onTimeArrivalRate}% on-time arrival',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.verified_user_outlined,
                iconColor: AppColors.coral,
                iconBg: AppColors.coralSoft,
                value: '${perf.totalComplaints - perf.resolvedComplaints} Open',
                label: 'Complaints',
                sublabel: '${perf.resolvedComplaints} of ${perf.totalComplaints} resolved',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingBreakdownCard(NursePerformance perf) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rating Distribution', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.ink)),
              Text('${perf.totalRatingsCount} ratings', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mutedForeground)),
            ],
          ),
          const SizedBox(height: 14),
          _RatingBarRow(stars: 5, count: perf.ratingDistribution[5] ?? 0, total: perf.totalRatingsCount),
          _RatingBarRow(stars: 4, count: perf.ratingDistribution[4] ?? 0, total: perf.totalRatingsCount),
          _RatingBarRow(stars: 3, count: perf.ratingDistribution[3] ?? 0, total: perf.totalRatingsCount),
          _RatingBarRow(stars: 2, count: perf.ratingDistribution[2] ?? 0, total: perf.totalRatingsCount),
          _RatingBarRow(stars: 1, count: perf.ratingDistribution[1] ?? 0, total: perf.totalRatingsCount),
        ],
      ),
    );
  }

  Widget _buildEarningsMiniCard(NursePerformance perf) {
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This Month’s Earnings', style: TextStyle(fontSize: 11, color: AppColors.mutedForeground, fontWeight: FontWeight.w600)),
                Text(
                  '₹${perf.thisMonthEarnings.toInt()}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '₹${perf.pendingPayout.toInt()} pending',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintsCard(NursePerformance perf) {
    return Surface(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              perf.totalComplaints == 0
                  ? 'No complaints on record.'
                  : '${perf.totalComplaints} complaint(s) on record, ${perf.resolvedComplaints} resolved.',
              style: const TextStyle(fontSize: 11.5, color: AppColors.ink, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final String sublabel;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: iconColor == AppColors.amber ? AppColors.ink : iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.ink)),
          Text(sublabel, style: const TextStyle(fontSize: 10.5, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _RatingBarRow extends StatelessWidget {
  final int stars;
  final int count;
  final int total;

  const _RatingBarRow({required this.stars, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$stars ★', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.mutedForeground)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: AppColors.secondary,
                valueColor: const AlwaysStoppedAnimation(AppColors.amber),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.mutedForeground)),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final CustomerFeedbackItem feedback;

  const _FeedbackTile({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Surface(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(feedback.patientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.ink)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      '${feedback.rating}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.ink),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${feedback.serviceName} · Ref: ${feedback.bookingId}',
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              feedback.comment,
              style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}

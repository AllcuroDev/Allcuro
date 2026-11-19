import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_view_model.dart';
import '../../../../core/provider_role.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../data/models/placement_request_summary.dart';
import 'centre_requests_view_model.dart';

/// List of pending placement requests a homecare centre can accept or
/// decline based on current bed availability.
class CentreRequestsScreen extends ConsumerWidget {
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;

  const CentreRequestsScreen({
    super.key,
    required this.onTabSelected,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(centreRequestsViewModelProvider);
    final notifier = ref.read(centreRequestsViewModelProvider.notifier);

    return ProviderShell(
      role: ProviderRole.centre,
      currentIndex: 1,
      onTabSelected: onTabSelected,
      onProfileTap: onProfileTap,
      initials: ref.watch(authViewModelProvider).valueOrNull?.initials ?? 'P',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ScreenHeader(
            title: 'Requests',
            subtitle: 'Placement requests waiting for your response',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: requestsAsync.when(
              data: (requests) => requests.isEmpty
                  ? const EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'No placement requests yet',
                      message: "You'll see them here once families start enquiring about your centre.",
                    )
                  : Column(
                      children: requests
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _PlacementCard(
                                request: r,
                                onAccept: () => notifier.accept(r.id),
                                onDecline: () => notifier.decline(r.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Could not load requests: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacementCard extends StatelessWidget {
  final PlacementRequestSummary request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PlacementCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            r.careType,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            r.familyContact,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.preference,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: 14,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                r.duration,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentForeground,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/provider_role.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../data/models/job_request_summary.dart';
import 'job_requests_view_model.dart';

/// List of pending shift requests a nurse can accept or decline. Tapping a
/// card opens `JobDetailScreen` for the full picture before deciding.
class JobRequestsScreen extends ConsumerWidget {
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;
  final void Function(String requestId) onOpenRequest;

  const JobRequestsScreen({
    super.key,
    required this.onTabSelected,
    required this.onProfileTap,
    required this.onOpenRequest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(jobRequestsViewModelProvider);
    final notifier = ref.read(jobRequestsViewModelProvider.notifier);

    return ProviderShell(
      role: ref.watch(authViewModelProvider).valueOrNull?.role ?? ProviderRole.nurse,
      currentIndex: 1,
      onTabSelected: onTabSelected,
      onProfileTap: onProfileTap,
      initials: 'PS',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ScreenHeader(
            title: 'Requests',
            subtitle: 'New shift requests waiting for your response',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: requestsAsync.when(
              data: (requests) => requests.isEmpty
                  ? const EmptyState(message: 'No pending requests right now')
                  : Column(
                      children: requests
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _RequestCard(
                                request: r,
                                onTap: () => onOpenRequest(r.id),
                                onAccept: () => notifier.accept(r.id),
                                onDecline: () => notifier.decline(r.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Could not load requests: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final JobRequestSummary request;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestCard({
    required this.request,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final r = request;
    return Surface(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.serviceType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${r.patientName} · ${r.locality}',
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
              Text(
                r.pay,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
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
                  Icons.schedule_outlined,
                  size: 14,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.timing,
                    maxLines: 1,
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

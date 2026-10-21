import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/provider_role.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/empty_state.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../../auth/presentation/auth_view_model.dart';
import '../../data/models/shift.dart';
import 'nurse_schedule_view_model.dart';

/// Nurse's shift calendar, filterable by status. The filter itself is
/// transient UI state; the underlying shift list comes from
/// [nurseScheduleViewModelProvider].
class NurseScheduleScreen extends ConsumerStatefulWidget {
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;

  const NurseScheduleScreen({
    super.key,
    required this.onTabSelected,
    required this.onProfileTap,
  });

  @override
  ConsumerState<NurseScheduleScreen> createState() => _NurseScheduleScreenState();
}

class _NurseScheduleScreenState extends ConsumerState<NurseScheduleScreen> {
  ShiftStatus _filter = ShiftStatus.upcoming;

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(nurseScheduleViewModelProvider);

    return ProviderShell(
      role: ref.watch(authViewModelProvider).valueOrNull?.role ?? ProviderRole.nurse,
      currentIndex: 2,
      onTabSelected: widget.onTabSelected,
      onProfileTap: widget.onProfileTap,
      initials: 'PS',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ScreenHeader(
            title: 'Schedule',
            subtitle: 'Your confirmed and past shifts',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: ShiftStatus.values.map((status) {
                final selected = status == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: switch (status) {
                      ShiftStatus.upcoming => 'Upcoming',
                      ShiftStatus.ongoing => 'Ongoing',
                      ShiftStatus.completed => 'Completed',
                    },
                    selected: selected,
                    onTap: () => setState(() => _filter = status),
                  ),
                );
              }).toList(),
            ),
          ),
          shiftsAsync.when(
            data: (shifts) {
              final filtered = shifts.where((s) => s.status == _filter).toList();
              if (filtered.isEmpty) {
                return const EmptyState(message: 'No shifts here yet');
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: filtered
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ShiftCard(shift: s),
                        ),
                      )
                      .toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Could not load your schedule: $error')),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
    return Material(
      color: selected ? AppColors.primary : AppColors.card,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.primaryForeground : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final Shift shift;

  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final s = shift;
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.status == ShiftStatus.ongoing
                  ? AppColors.primarySoft
                  : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              s.status == ShiftStatus.completed
                  ? Icons.check_circle_outline_rounded
                  : Icons.event_available_outlined,
              size: 20,
              color: s.status == ShiftStatus.ongoing
                  ? AppColors.primary
                  : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.serviceType} · ${s.patientName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(
                  s.timing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
                Text(
                  s.locality,
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          if (s.status == ShiftStatus.ongoing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

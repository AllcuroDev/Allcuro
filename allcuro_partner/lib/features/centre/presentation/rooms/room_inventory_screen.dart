import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_view_model.dart';
import '../../../../core/provider_role.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/app_shell.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';
import '../../data/models/bed_slot.dart';
import '../../data/models/room.dart';
import '../../../auth/presentation/onboarding_view_model.dart';
import 'add_edit_room_dialog.dart';

class RoomInventoryScreen extends ConsumerWidget {
  final ValueChanged<int> onTabSelected;
  final VoidCallback onProfileTap;

  const RoomInventoryScreen({
    super.key,
    required this.onTabSelected,
    required this.onProfileTap,
  });

  void _showAddRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddEditRoomDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(partnerOnboardingProvider);
    final rooms = onboardingState.rooms;

    final byWard = <String, List<Room>>{};
    for (final room in rooms) {
      byWard.putIfAbsent(room.ward, () => []).add(room);
    }

    final totalBeds = rooms.fold<int>(0, (sum, r) => sum + r.beds.length);
    final occupiedBeds = rooms.fold<int>(
      0,
      (sum, r) => sum + r.beds.where((b) => b.occupied).length,
    );
    final vacantBeds = totalBeds - occupiedBeds;

    return ProviderShell(
      role: ProviderRole.centre,
      currentIndex: 2,
      onTabSelected: onTabSelected,
      onProfileTap: onProfileTap,
      initials: ref.watch(authViewModelProvider).valueOrNull?.initials ?? 'P',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const ScreenHeader(
            title: 'Rooms & bed inventory',
            subtitle: 'Real-time bed availability & admission management',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Surface(
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
                        child: const Icon(Icons.hotel_rounded, size: 22, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalBeds Total Beds ($vacantBeds Vacant · $occupiedBeds Occupied)',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Tap any bed chip to toggle its occupied/vacant status.',
                              style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Wards & Rooms',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRoomDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Room', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentForeground,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (rooms.isEmpty)
                  Surface(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.hotel_outlined, size: 40, color: AppColors.mutedForeground),
                          const SizedBox(height: 10),
                          const Text('No rooms configured yet', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(height: 4),
                          const Text('Add your ICU, Semi-private or Deluxe rooms to make them bookable.', style: TextStyle(fontSize: 12, color: AppColors.mutedForeground)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showAddRoomDialog(context),
                            child: const Text('Add First Room'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...byWard.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...entry.value.map(
                            (room) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RoomCard(
                                room: room,
                                onToggleBed: (bedId) {
                                  ref.read(partnerOnboardingProvider.notifier).toggleBedStatus(room.id, bedId);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final ValueChanged<String> onToggleBed;

  const _RoomCard({required this.room, required this.onToggleBed});

  @override
  Widget build(BuildContext context) {
    final vacant = room.beds.where((b) => !b.occupied).length;
    return Surface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  room.roomNumber,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.ink),
                ),
              ),
              Text(
                room.ratePerDay,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            vacant > 0 ? '$vacant of ${room.beds.length} beds vacant' : 'Fully occupied',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: vacant > 0 ? AppColors.success : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: room.beds
                .map((bed) => _BedChip(
                      bed: bed,
                      onTap: () => onToggleBed(bed.id),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BedChip extends StatelessWidget {
  final BedSlot bed;
  final VoidCallback onTap;

  const _BedChip({required this.bed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: BorderSide(color: bed.occupied ? AppColors.border : AppColors.success),
    );
    return Material(
      color: bed.occupied ? AppColors.secondary : AppColors.successSoft,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bed_outlined,
                size: 14,
                color: bed.occupied ? AppColors.mutedForeground : AppColors.success,
              ),
              const SizedBox(width: 6),
              Text(
                bed.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: bed.occupied ? AppColors.secondaryForeground : AppColors.success,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                bed.occupied ? '(Occupied)' : '(Vacant)',
                style: TextStyle(
                  fontSize: 10,
                  color: bed.occupied ? AppColors.mutedForeground : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

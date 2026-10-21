import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../provider_role.dart';
import '../theme/app_theme.dart';
import 'tappable.dart';

class _TabItem {
  final String label;
  final IconData icon;

  const _TabItem({required this.label, required this.icon});
}

const _nurseTabs = [
  _TabItem(label: 'Home', icon: Icons.grid_view_rounded),
  _TabItem(label: 'Requests', icon: Icons.assignment_outlined),
  _TabItem(label: 'Schedule', icon: Icons.event_available_outlined),
];

const _centreTabs = [
  _TabItem(label: 'Home', icon: Icons.grid_view_rounded),
  _TabItem(label: 'Requests', icon: Icons.assignment_outlined),
  _TabItem(label: 'Rooms', icon: Icons.bed_outlined),
];

/// Partner-app counterpart to the customer app's `AppShell`:
/// Features a dynamic sliding gradient header that collapses on scroll.
/// - Background: Seamless full-bleed green gradient behind header & rounded corners.
/// - Expanded state: ALLCURO PARTNER brand title, small logo, Notifications bell,
///   Profile Avatar, and clean Partner Hub Address with Duty Status.
/// - Scrolled/Collapsed state: ALLCURO name and icons smoothly fade out,
///   leaving only the small ALLCURO logo and the Address neatly pinned while the
///   dashboard slides up smoothly together.
class ProviderShell extends StatelessWidget {
  final Widget child;
  final ProviderRole role;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final String initials;
  final Widget? bottomBar;
  final String address;
  final VoidCallback? onAddressTap;
  final String statusBadge;
  final int notificationCount;

  const ProviderShell({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onTabSelected,
    required this.child,
    this.onProfileTap,
    this.onNotificationsTap,
    this.initials = 'PS',
    this.bottomBar,
    this.address = 'Indiranagar Hub, Bengaluru',
    this.onAddressTap,
    this.statusBadge = '🟢 On-Duty',
    this.notificationCount = 2,
  });

  List<_TabItem> get _tabs =>
      role.usesNurseShell ? _nurseTabs : _centreTabs;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.gradientPrimary,
        ),
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverPersistentHeader(
                pinned: true,
                delegate: _CollapsiblePartnerHeaderDelegate(
                  topPadding: topPadding,
                  role: role,
                  initials: initials,
                  address: address,
                  statusBadge: statusBadge,
                  notificationCount: notificationCount,
                  onProfileTap: onProfileTap,
                  onNotificationsTap: onNotificationsTap,
                  onAddressTap: onAddressTap,
                ),
              ),
            ];
          },
          body: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxxl),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xxxl),
              ),
              child: child,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ColoredBox(
          color: AppColors.card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?bottomBar,
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                  child: Row(
                    children: _tabs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final tab = entry.value;
                      final active = index == currentIndex;
                      return Expanded(
                        child: Material(
                          type: MaterialType.transparency,
                          child: InkResponse(
                            onTap: () {
                              if (index != currentIndex) onTabSelected(index);
                            },
                            radius: 40,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? AppColors.primarySoft
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    tab.icon,
                                    size: 20,
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  tab.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsiblePartnerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final ProviderRole role;
  final String initials;
  final String address;
  final String statusBadge;
  final int notificationCount;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onAddressTap;

  _CollapsiblePartnerHeaderDelegate({
    required this.topPadding,
    required this.role,
    required this.initials,
    required this.address,
    required this.statusBadge,
    required this.notificationCount,
    this.onProfileTap,
    this.onNotificationsTap,
    this.onAddressTap,
  });

  @override
  double get minExtent => topPadding + 58.0;

  @override
  double get maxExtent => topPadding + 114.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final delta = maxExtent - minExtent;
    final progress = delta > 0 ? (shrinkOffset / delta).clamp(0.0, 1.0) : 0.0;

    // Opacities for elements that disappear as user scrolls
    final titleAndIconsOpacity = (1.0 - progress * 2.5).clamp(0.0, 1.0);
    final statusOpacity = (1.0 - progress * 2.2).clamp(0.0, 1.0);

    // Interpolated values for small logo
    final logoSize = lerpDouble(36.0, 30.0, progress)!;
    final logoTop = lerpDouble(topPadding + 12.0, topPadding + 14.0, progress)!;
    const logoLeft = 20.0;

    // Interpolated values for Address (no box/border, simple clean layout)
    final addressExpandedTop = topPadding + 65.0;
    final addressCollapsedTop = topPadding + 18.0;
    final addressTop = lerpDouble(addressExpandedTop, addressCollapsedTop, progress)!;
    final addressLeft = lerpDouble(20.0, 58.0, progress)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.gradientPrimary,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Brand Title (Fades away on scroll)
            if (titleAndIconsOpacity > 0)
              Positioned(
                left: 64,
                top: topPadding + 18,
                child: Opacity(
                  opacity: titleAndIconsOpacity,
                  child: Text(
                    switch (role) {
                      ProviderRole.nurse => 'ALLCURO NURSE',
                      ProviderRole.clinician => 'ALLCURO CLINICIAN',
                      ProviderRole.centre => 'ALLCURO PARTNER',
                    },
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: AppColors.primaryForeground,
                    ),
                  ),
                ),
              ),

            // 2. Right Action Icons: Notifications & Profile Avatar (Fade away on scroll)
            if (titleAndIconsOpacity > 0)
              Positioned(
                right: 20,
                top: topPadding + 12,
                child: Opacity(
                  opacity: titleAndIconsOpacity,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notifications Bell
                      Tappable(
                        onTap: onNotificationsTap ?? () {},
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryForeground.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryForeground.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                size: 19,
                                color: AppColors.primaryForeground,
                              ),
                            ),
                            if (notificationCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 17,
                                  height: 17,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: AppColors.destructive,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$notificationCount',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.destructiveForeground,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profile Avatar
                      Tappable(
                        onTap: onProfileTap ?? () {},
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryForeground.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryForeground.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryForeground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 3. Small Logo (ALWAYS VISIBLE, smooth scaling on scroll)
            Positioned(
              left: logoLeft,
              top: logoTop,
              child: Container(
                width: logoSize,
                height: logoSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryForeground.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.primaryForeground.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  Icons.monitor_heart_rounded,
                  size: logoSize * 0.55,
                  color: AppColors.primaryForeground,
                ),
              ),
            ),

            // 4. Simple Clean Address (No border box, clean icon + text + chevron)
            Positioned(
              left: addressLeft,
              top: addressTop,
              child: Tappable(
                onTap: onAddressTap ?? () {},
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.primaryForeground,
                      ),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: lerpDouble(180.0, 250.0, progress)!,
                        ),
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.primaryForeground,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: AppColors.primaryForeground,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Duty Status Chip (Visible in expanded state)
            if (statusOpacity > 0)
              Positioned(
                right: 20,
                top: topPadding + 62.0,
                child: Opacity(
                  opacity: statusOpacity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      statusBadge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsiblePartnerHeaderDelegate oldDelegate) {
    return oldDelegate.address != address ||
        oldDelegate.initials != initials ||
        oldDelegate.role != role ||
        oldDelegate.statusBadge != statusBadge ||
        oldDelegate.notificationCount != notificationCount ||
        oldDelegate.topPadding != topPadding;
  }
}

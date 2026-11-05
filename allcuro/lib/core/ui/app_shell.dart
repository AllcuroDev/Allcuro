import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/bookings/data/models/booking.dart';
import '../../features/bookings/presentation/bookings_view_model.dart';
import '../../features/location/presentation/location_sheet.dart';
import '../../features/location/presentation/location_view_model.dart';
import '../theme/app_theme.dart';
import 'tappable.dart';

/// The nurse visit currently under way, if any. The home screen shows it as a
/// floating card above the bottom nav (and pads its list so the card never
/// hides the last item).
final activeNurseVisitProvider = Provider<Booking?>((ref) {
  final bookings = ref.watch(bookingsViewModelProvider).valueOrNull ?? const <Booking>[];
  for (final b in bookings) {
    if (b.type == BookingType.nurse &&
        (b.status == 'In Progress' || b.status == 'Active' || b.status == 'Confirmed')) {
      return b;
    }
  }
  return null;
});

/// Space to leave under scrolling content for the floating live-visit card.
const double kLiveVisitCardInset = 84;

class _TabItem {
  final String path;
  final String label;
  final IconData icon;
  final bool exact;
  final bool isSpecial;

  const _TabItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.exact,
    this.isSpecial = false,
  });
}

const _tabs = [
  _TabItem(
    path: '/',
    label: 'Home',
    icon: Icons.grid_view_rounded,
    exact: true,
  ),
  _TabItem(
    path: '/centres',
    label: 'Care Centres',
    icon: Icons.apartment_rounded,
    exact: false,
  ),
  _TabItem(
    path: '/nurse-quick-booking',
    label: '45 Mins',
    icon: Icons.bolt_rounded,
    exact: false,
    isSpecial: true,
  ),
  _TabItem(
    path: '/equipment',
    label: 'Equipments',
    icon: Icons.medical_services_outlined,
    exact: false,
  ),
  _TabItem(
    path: '/bookings',
    label: 'Bookings',
    icon: Icons.event_available_outlined,
    exact: false,
  ),
];

/// Streamlined, Ultra-Compact Header AppShell:
/// - Shorter green gradient header with no bulky icons or top title.
/// - Top row: Location & Time (left), Notification & Profile (right).
/// - Below top row: Integrated search bar.
/// - Quick-commerce live nurse visit docked popup just above bottom nav.
/// - 5-tab flow: Home, Care Centres, 45 Mins (Quick Booking), Equipments, Bookings.
class AppShell extends ConsumerWidget {
  final Widget child;
  final Widget? bottomBar;
  final String currentPath;
  final String? address;
  final String? arrivalTime;
  final String? timeStatus;
  final VoidCallback? onAddressTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final String initials;
  final int notificationCount;
  final bool showSearch;
  final bool showQuickActions;

  const AppShell({
    super.key,
    required this.child,
    this.bottomBar,
    required this.currentPath,
    this.address,
    this.arrivalTime,
    this.timeStatus,
    this.onAddressTap,
    this.onNotificationsTap,
    this.onProfileTap,
    this.onSearchChanged,
    this.searchController,
    this.initials = 'AK',
    this.notificationCount = 2,
    this.showSearch = false,
    this.showQuickActions = false,
  });

  bool _isActive(_TabItem tab) {
    if (tab.exact) return currentPath == tab.path;
    return currentPath == tab.path || currentPath.startsWith('${tab.path}/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.paddingOf(context).top;

    final locationState = ref.watch(locationViewModelProvider);
    final effectiveAddress =
        (address != null &&
            address!.isNotEmpty &&
            address != 'Indiranagar, Bengaluru')
        ? address!
        : locationState.currentAddress.shortAddress;
    final effectiveArrivalTime =
        arrivalTime ?? locationState.currentAddress.arrivalTime;

    final activeNurseBooking = ref.watch(activeNurseVisitProvider);
    final showVisitPopup = activeNurseBooking != null && currentPath == '/';

    // Only the bottom-nav root pages carry the green location header; every
    // page opened on top of them gets a plain white surface instead. Decided
    // from the real route, since inner pages pass a tab path in [currentPath]
    // just to highlight that tab.
    final routePath = GoRouterState.of(context).uri.path;
    final isTabRoot = _tabs.any((t) => t.path == routePath);

    return Scaffold(
      backgroundColor: isTabRoot ? Colors.transparent : AppColors.card,
      // The live-visit card floats over the page, just above the bottom nav.
      body: Stack(
        children: [
          Positioned.fill(
            child: isTabRoot
                ? _buildHeaderBody(topPadding, effectiveAddress, effectiveArrivalTime)
                : _buildPlainBody(),
          ),
          if (showVisitPopup)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _MinimalActiveNurseVisitPopup(booking: activeNurseBooking),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildPlainBody() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: SafeArea(bottom: false, child: child),
    );
  }

  Widget _buildHeaderBody(
    double topPadding,
    String effectiveAddress,
    String effectiveArrivalTime,
  ) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverPersistentHeader(
              pinned: true,
              delegate: _CompactHeaderDelegate(
                topPadding: topPadding,
                textScaler: MediaQuery.textScalerOf(context),
                currentPath: currentPath,
                address: effectiveAddress,
                arrivalTime: effectiveArrivalTime,
                onAddressTap: onAddressTap,
                onNotificationsTap: onNotificationsTap,
                onProfileTap: onProfileTap,
                initials: initials,
                notificationCount: notificationCount,
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
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
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
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                child: Row(
                  children: _tabs.map((tab) {
                    final active = _isActive(tab);
                    return Expanded(
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkResponse(
                          onTap: () {
                            if (currentPath != tab.path) context.go(tab.path);
                          },
                          radius: 40,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (tab.isSpecial)
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: active
                                        ? const LinearGradient(
                                            colors: [
                                              AppColors.secondaryAccent,
                                              Color(0xFFF97316),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : LinearGradient(
                                            colors: [
                                              AppColors.secondaryAccentSoft,
                                              AppColors.secondaryAccentBorder
                                                  .withValues(alpha: 0.6),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.secondaryAccent
                                            .withValues(
                                              alpha: active ? 0.35 : 0.15,
                                            ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    tab.icon,
                                    size: 20,
                                    color: active
                                        ? Colors.white
                                        : AppColors.secondaryAccent,
                                  ),
                                )
                              else
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
                              const SizedBox(height: 2),
                              Text(
                                tab.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: active
                                      ? (tab.isSpecial
                                            ? AppColors.secondaryAccent
                                            : AppColors.primary)
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
    );
  }
}

class _CompactHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final TextScaler textScaler;
  final String currentPath;
  final String address;
  final String arrivalTime;
  final VoidCallback? onAddressTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;
  final String initials;
  final int notificationCount;

  _CompactHeaderDelegate({
    required this.topPadding,
    required this.textScaler,
    required this.currentPath,
    required this.address,
    required this.arrivalTime,
    this.onAddressTap,
    this.onNotificationsTap,
    this.onProfileTap,
    this.initials = 'AK',
    this.notificationCount = 2,
  });

  /// Height the two address lines need at the phone's font size: the 16pt
  /// arrival line + 2pt gap + the 13pt address line, with Plus Jakarta Sans'
  /// ~1.3 line height, plus the 10pt of vertical padding and a little slack.
  /// A fixed extent overflowed on phones with a larger system font.
  double get _contentExtent =>
      textScaler.scale(16) * 1.35 + 2 + textScaler.scale(13) * 1.4 + 10 + 6;

  @override
  double get minExtent =>
      topPadding + (_contentExtent < 56 ? 56.0 : _contentExtent);

  @override
  double get maxExtent => minExtent + 8.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Fill the full extent: a pinned header that paints shorter than its
    // layout extent is an invalid sliver geometry.
    return SizedBox.expand(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, topPadding + 4, 18, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. LEFT: Quick-Commerce Location & Arrival Time Header
              Expanded(
                child: Tappable(
                  onTap: onAddressTap ?? () => LocationSheet.show(context),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Line: "Allcuro in 44 mins"
                      // "Allcuro in" in small font, "44 mins" in bigger font
                      Text.rich(
                        TextSpan(
                          text: '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                            color: Colors.white.withValues(alpha: 0.90),
                          ),
                          children: [
                            TextSpan(
                              text: "In $arrivalTime",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // Second Line: Address with medium size (slightly larger than "Allcuro" word)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. RIGHT: Notification Bell & Profile Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Notifications Icon
                  Tappable(
                    onTap:
                        onNotificationsTap ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🔔 No new clinical alerts. All bookings normal.',
                              ),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primaryForeground.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryForeground.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 18,
                            color: AppColors.primaryForeground,
                          ),
                        ),
                        if (notificationCount > 0)
                          Positioned(
                            right: -1,
                            top: -1,
                            child: Container(
                              width: 15,
                              height: 15,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.destructive,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$notificationCount',
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.destructiveForeground,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Profile / Avatar Icon
                  Tappable(
                    onTap: onProfileTap ?? () => context.go('/profile'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryForeground.withValues(
                          alpha: 0.18,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryForeground.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryForeground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CompactHeaderDelegate oldDelegate) {
    return oldDelegate.address != address ||
        oldDelegate.arrivalTime != arrivalTime ||
        oldDelegate.currentPath != currentPath ||
        oldDelegate.notificationCount != notificationCount ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.textScaler != textScaler ||
        oldDelegate.initials != initials;
  }
}

/// Minimal Quick-Commerce style Active Nurse Visit Popup pinned right above bottom navigation.
class _MinimalActiveNurseVisitPopup extends StatelessWidget {
  final Booking booking;

  const _MinimalActiveNurseVisitPopup({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () {
            context.push('/nurse-tracker/${booking.id}');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Clean static nurse icon with online indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),

                // Nurse Name & Quick visit status
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              booking.providerName.isNotEmpty
                                  ? booking.providerName
                                  : 'Sister Priya Sharma',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Live Nurse Visit · In Progress',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // OTP badge
                if (booking.otp.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'OTP: ${booking.otp}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),

                const SizedBox(width: 6),

                // Minimal Track Button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 8.5,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

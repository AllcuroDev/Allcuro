import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_view_model.dart';
import '../../features/auth/presentation/bank_account_screen.dart';
import '../../features/auth/presentation/phone_auth_screen.dart';
import '../../features/auth/presentation/role_select_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/centre/presentation/compliance/compliance_screen.dart';
import '../../features/centre/presentation/equipment/equipment_management_screen.dart';
import '../../features/centre/presentation/home/centre_home_screen.dart';
import '../../features/centre/presentation/listing/listing_management_screen.dart';
import '../../features/centre/presentation/promotions/promotions_screen.dart';
import '../../features/centre/presentation/requests/centre_requests_screen.dart';
import '../../features/centre/presentation/revenue/revenue_screen.dart';
import '../../features/centre/presentation/reviews/reviews_screen.dart';
import '../../features/centre/presentation/rooms/room_inventory_screen.dart';
import '../../features/centre/presentation/signup/centre_signup_screen.dart';
import '../../features/centre/presentation/staff/staff_management_screen.dart';
import '../../features/clinician/presentation/signup/clinician_signup_screen.dart';
import '../../features/nurse/presentation/availability/availability_screen.dart';
import '../../features/nurse/presentation/documents/document_vault_screen.dart';
import '../../features/nurse/presentation/earnings/earnings_screen.dart';
import '../../features/nurse/presentation/home/nurse_home_screen.dart';
import '../../features/nurse/presentation/ratings/performance_screen.dart';
import '../../features/nurse/presentation/referral/referral_screen.dart';
import '../../features/nurse/presentation/requests/job_detail_screen.dart';
import '../../features/nurse/presentation/requests/job_requests_screen.dart';
import '../../features/nurse/presentation/requests/nurse_visit_execution_screen.dart';
import '../../features/nurse/presentation/schedule/nurse_schedule_screen.dart';
import '../../features/nurse/presentation/signup/nurse_signup_screen.dart';
import '../../features/nurse/presentation/support/support_screen.dart';
import '../../features/nurse/presentation/training/training_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../provider_role.dart';
import 'app_routes.dart';
import 'shell_navigation.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Bridges Riverpod's [authViewModelProvider] to go_router's imperative
/// `refreshListenable` so `redirect` re-runs whenever login/role/
/// verification-status state changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authViewModelProvider, (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authViewModelProvider).valueOrNull;
      final path = state.matchedLocation;

      // Allow splash screen to display its animation on launch
      if (path == AppRoutes.splash) {
        return null;
      }

      // Still reading the persisted session from disk — park on the splash screen
      if (session == null) {
        return AppRoutes.splash;
      }
      if (!session.isLoggedIn) {
        final onPreAuthRoute =
            path == AppRoutes.welcome || path == AppRoutes.phoneAuth;
        return onPreAuthRoute ? null : AppRoutes.welcome;
      }
      if (session.role == null) {
        return path == AppRoutes.roleSelect ? null : AppRoutes.roleSelect;
      }

      final role = session.role!;
      final home = role.usesNurseShell ? AppRoutes.nurseHome : AppRoutes.centreHome;
      final ownShellPrefix = role.usesNurseShell ? '/nurse' : '/centre';

      // A brand-new account for this role hasn't completed the 3-step basic sign-up
      final signupIncomplete = session.signupIncomplete;
      final signupRoute = switch (role) {
        ProviderRole.nurse => AppRoutes.nurseSignup,
        ProviderRole.clinician => AppRoutes.clinicianSignup,
        ProviderRole.centre => AppRoutes.centreSignup,
      };
      if (signupIncomplete) {
        return path == signupRoute ? null : signupRoute;
      }

      if (path == AppRoutes.welcome ||
          path == AppRoutes.phoneAuth ||
          path == AppRoutes.roleSelect ||
          path == signupRoute) {
        return home;
      }

      // Guard against cross-role route mismatch
      if (!path.startsWith(ownShellPrefix) &&
          path != AppRoutes.profile &&
          path != AppRoutes.bankAccount) {
        return home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => WelcomeScreen(
          onGetStarted: () => context.go(AppRoutes.phoneAuth),
        ),
      ),
      GoRoute(
        path: AppRoutes.phoneAuth,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PhoneAuthScreen(onBack: () => context.go(AppRoutes.welcome)),
      ),
      GoRoute(
        path: AppRoutes.roleSelect,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => RoleSelectScreen(
            onSelect: (role) => ref.read(authViewModelProvider.notifier).selectRole(role),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ProfileScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.bankAccount,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BankAccountScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.nurseSignup,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NurseSignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.clinicianSignup,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ClinicianSignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.centreSignup,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CentreSignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.nurseRequestDetailPattern,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => JobDetailScreen(
          requestId: state.pathParameters['id']!,
          onBack: () => context.pop(),
        ),
      ),
      GoRoute(
        path: AppRoutes.nurseAvailability,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AvailabilityScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.nurseEarnings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => EarningsScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.nurseTraining,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TrainingScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.nurseRatings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PerformanceScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.nurseVisitExecution,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => NurseVisitExecutionScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.nurseDocuments,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => DocumentVaultScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.nurseReferral,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ReferralScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.nurseSupport,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SupportScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.centreListing,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ListingManagementScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.centreEquipment,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => EquipmentManagementScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.centreRevenue,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RevenueScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.centreReviews,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ReviewsScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.centreCompliance,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ComplianceScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.centreStaff,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => StaffManagementScreen(onBack: () => context.pop()),
      ),
      GoRoute(
        path: AppRoutes.centrePromotions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PromotionsScreen(onBack: () => context.pop()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellNavigation(navigationShell: navigationShell, child: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.nurseHome,
                builder: (context, state) {
                  final shell = ShellNavigation.of(context);
                  return NurseHomeScreen(
                    onTabSelected: shell.goBranch,
                    onProfileTap: () => context.push(AppRoutes.profile),
                    onSeeAllRequests: () => shell.goBranch(1),
                    onSeeSchedule: () => shell.goBranch(2),
                    onOpenRequest: (id) =>
                        context.push(AppRoutes.nurseRequestDetail(id)),
                    onOpenAvailability: () => context.push(AppRoutes.nurseAvailability),
                    onOpenEarnings: () => context.push(AppRoutes.nurseEarnings),
                    onOpenTraining: () => context.push(AppRoutes.nurseTraining),
                    onOpenRatings: () => context.push(AppRoutes.nurseRatings),
                    onOpenDocuments: () => context.push(AppRoutes.nurseDocuments),
                    onOpenReferral: () => context.push(AppRoutes.nurseReferral),
                    onOpenSupport: () => context.push(AppRoutes.nurseSupport),
                    onOpenBankAccount: () => context.push(AppRoutes.bankAccount),
                    onOpenActiveVisit: () => context.push(AppRoutes.nurseVisitExecution),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.nurseRequests,
                builder: (context, state) {
                  final shell = ShellNavigation.of(context);
                  return JobRequestsScreen(
                    onTabSelected: shell.goBranch,
                    onProfileTap: () => context.push(AppRoutes.profile),
                    onOpenRequest: (id) =>
                        context.push(AppRoutes.nurseRequestDetail(id)),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.nurseSchedule,
                builder: (context, state) {
                  final shell = ShellNavigation.of(context);
                  return NurseScheduleScreen(
                    onTabSelected: shell.goBranch,
                    onProfileTap: () => context.push(AppRoutes.profile),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellNavigation(navigationShell: navigationShell, child: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.centreHome,
                builder: (context, state) {
                  final shell = ShellNavigation.of(context);
                  return CentreHomeScreen(
                    onTabSelected: shell.goBranch,
                    onProfileTap: () => context.push(AppRoutes.profile),
                    onSeeAllRequests: () => shell.goBranch(1),
                    onSeeRooms: () => shell.goBranch(2),
                    onOpenListing: () => context.push(AppRoutes.centreListing),
                    onOpenEquipment: () => context.push(AppRoutes.centreEquipment),
                    onOpenBankAccount: () => context.push(AppRoutes.bankAccount),
                    onOpenRevenue: () => context.push(AppRoutes.centreRevenue),
                    onOpenReviews: () => context.push(AppRoutes.centreReviews),
                    onOpenCompliance: () => context.push(AppRoutes.centreCompliance),
                    onOpenStaff: () => context.push(AppRoutes.centreStaff),
                    onOpenPromotions: () => context.push(AppRoutes.centrePromotions),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.centreRequests,
                builder: (context, state) {
                  final shell = ShellNavigation.of(context);
                  return CentreRequestsScreen(
                    onTabSelected: shell.goBranch,
                    onProfileTap: () => context.push(AppRoutes.profile),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.centreRooms,
                builder: (context, state) {
                  final shell = ShellNavigation.of(context);
                  return RoomInventoryScreen(
                    onTabSelected: shell.goBranch,
                    onProfileTap: () => context.push(AppRoutes.profile),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

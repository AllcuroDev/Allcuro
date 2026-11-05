import 'package:go_router/go_router.dart';

import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/phone_auth_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/bookings/presentation/bookings_screen.dart';
import '../features/centres/presentation/booking/centre_booking_screen.dart';
import '../features/centres/presentation/centre_detail/centre_detail_screen.dart';
import '../features/centres/presentation/centres_list/centres_list_screen.dart';
import '../features/centres/presentation/pass/centre_visit_pass_screen.dart';
import '../features/checkout/presentation/checkout_screen.dart';
import '../features/equipment/presentation/equipment_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/medicines/presentation/medicine_cart_screen.dart';
import '../features/medicines/presentation/medicine_order_screen.dart';
import '../features/medicines/presentation/medicines_screen.dart';
import '../features/nurses/presentation/nurse_detail/nurse_detail_screen.dart';
import '../features/nurses/presentation/nurses_list/nurses_list_screen.dart';
import '../features/nurses/presentation/quick_booking/nurse_quick_booking_screen.dart';
import '../features/nurses/presentation/tracker/nurse_booking_tracker_screen.dart';
import '../features/profile/presentation/faq_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/services/presentation/category_services_screen.dart';
import '../features/services/presentation/service_detail_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => WelcomeScreen(
        onGetStarted: () => context.push('/auth/phone'),
        onExploreGuest: () => context.go('/'),
      ),
    ),
    GoRoute(
      path: '/auth/phone',
      builder: (context, state) => PhoneAuthScreen(
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/welcome');
          }
        },
        onAuthenticated: () => context.go('/onboarding'),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(
        onCompleted: () => context.go('/'),
      ),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/category-services/:category',
      builder: (context, state) => CategoryServicesScreen(
        category: state.pathParameters['category'] ?? 'nursing',
      ),
    ),
    GoRoute(
      path: '/nurse-services',
      builder: (context, state) => const CategoryServicesScreen(
        category: 'nursing',
      ),
    ),
    GoRoute(
      path: '/services/:serviceId',
      builder: (context, state) => ServiceDetailScreen(
        serviceId: state.pathParameters['serviceId'] ?? 'quick-care',
      ),
    ),
    GoRoute(
      path: '/nurses',
      builder: (context, state) => NursesListScreen(
        initialService: state.uri.queryParameters['service'],
      ),
    ),
    GoRoute(
      path: '/nurse-quick-booking',
      builder: (context, state) => const NurseQuickBookingScreen(),
    ),
    GoRoute(
      path: '/nurse-tracker/:id',
      builder: (context, state) => NurseBookingTrackerScreen(
        bookingId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/nurses/:nurseId',
      builder: (context, state) => NurseDetailScreen(
        nurseId: state.pathParameters['nurseId']!,
      ),
    ),
    GoRoute(
      path: '/centres',
      builder: (context, state) => const CentresListScreen(),
    ),
    GoRoute(
      path: '/centre-booking/:centreId',
      builder: (context, state) => CentreBookingScreen(
        centreId: state.pathParameters['centreId']!,
      ),
    ),
    GoRoute(
      path: '/centre-pass/:id',
      builder: (context, state) => CentreVisitPassScreen(
        bookingId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/centres/:centreId',
      builder: (context, state) => CentreDetailScreen(
        centreId: state.pathParameters['centreId']!,
      ),
    ),
    GoRoute(
      path: '/equipment',
      builder: (context, state) => const EquipmentScreen(),
    ),
    GoRoute(
      path: '/medicines',
      builder: (context, state) => MedicinesScreen(
        openUpload: state.uri.queryParameters['upload'] == '1',
      ),
    ),
    GoRoute(
      path: '/medicines/cart',
      builder: (context, state) => const MedicineCartScreen(),
    ),
    GoRoute(
      path: '/medicine-order/:id',
      builder: (context, state) => MedicineOrderScreen(
        orderId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/bookings',
      builder: (context, state) => const BookingsScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => CheckoutScreen(
        item: state.uri.queryParameters['item'],
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/faq',
      builder: (context, state) => const FaqScreen(),
    ),
  ],
);

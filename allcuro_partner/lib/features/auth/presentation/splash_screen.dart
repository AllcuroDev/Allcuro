import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/provider_role.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'auth_view_model.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate to appropriate partner screen after entrance animation completes
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      final session = ref.read(authViewModelProvider).valueOrNull;

      if (session == null || !session.isLoggedIn) {
        context.go(AppRoutes.welcome);
      } else if (session.role == null) {
        context.go(AppRoutes.roleSelect);
      } else {
        final role = session.role!;
        if (session.signupIncomplete) {
          context.go(switch (role) {
            ProviderRole.nurse => AppRoutes.nurseSignup,
            ProviderRole.clinician => AppRoutes.clinicianSignup,
            ProviderRole.centre => AppRoutes.centreSignup,
          });
        } else {
          context.go(role.usesNurseShell ? AppRoutes.nurseHome : AppRoutes.centreHome);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryForeground.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xxl),
                    border: Border.all(
                      color: AppColors.primaryForeground.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.monitor_heart_rounded,
                    size: 48,
                    color: AppColors.primaryForeground,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'ALLCURO PARTNER',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.5,
                        color: AppColors.primaryForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Care Partner Ecosystem',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: AppColors.primaryForeground.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

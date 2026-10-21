import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/wizard_scaffold.dart';
import '../../../auth/presentation/auth_view_model.dart';
import 'clinician_signup_steps.dart';
import 'clinician_signup_view_model.dart';

/// 3-step doctor / physiotherapist sign-up wizard — the counterpart of
/// `NurseSignupScreen`. Documents, bank payout and availability are completed
/// progressively from the Home & Profile screens without blocking access.
class ClinicianSignupScreen extends ConsumerWidget {
  const ClinicianSignupScreen({super.key});

  bool _canContinue(ClinicianSignupState s) {
    final d = s.data;
    switch (s.stepIndex) {
      case 0:
        return d.profession != null &&
            d.fullName.trim().isNotEmpty &&
            d.gender != null &&
            d.city.trim().isNotEmpty;
      case 1:
        return d.qualification != null &&
            d.registrationNumber.trim().isNotEmpty &&
            d.experienceYears.trim().isNotEmpty;
      case 2:
        return d.backgroundConsent;
      default:
        return false;
    }
  }

  Widget _stepContent(int index) {
    return switch (index) {
      0 => const ClinicianBasicDetailsStep(),
      1 => const ClinicianQualificationStep(),
      _ => const ClinicianVerificationStep(),
    };
  }

  Future<void> _confirmExit(BuildContext context, WidgetRef ref) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit sign-up?'),
        content: const Text(
          "You'll need to log in again to pick up where you left off.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      await ref.read(authViewModelProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clinicianSignupViewModelProvider);
    final notifier = ref.read(clinicianSignupViewModelProvider.notifier);
    final isLastStep = state.stepIndex == ClinicianSignupViewModel.stepCount - 1;
    final canContinue = _canContinue(state);

    return WizardScaffold(
      onBack: () {
        if (state.stepIndex > 0) {
          notifier.back();
        } else {
          _confirmExit(context, ref);
        }
      },
      stepIndex: state.stepIndex,
      stepCount: ClinicianSignupViewModel.stepCount,
      step: _stepContent(state.stepIndex),
      bottomBar: WizardPrimaryButton(
        label: isLastStep ? 'Submit & Enter Dashboard' : 'Continue',
        loading: state.isSubmitting,
        onPressed: canContinue
            ? () {
                if (isLastStep) {
                  notifier.submit();
                } else {
                  notifier.next();
                }
              }
            : null,
      ),
    );
  }
}

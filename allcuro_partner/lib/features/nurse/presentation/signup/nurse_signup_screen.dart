import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/wizard_scaffold.dart';
import '../../../auth/presentation/auth_view_model.dart';
import 'nurse_signup_steps_a.dart';
import 'nurse_signup_view_model.dart';

/// Streamlined 3-step nurse sign-up wizard, shown after identity verification.
/// Collects core details required to create the account (or skip straight to
/// the dashboard), and allows completing
/// the Document Vault, Medical fitness, References, Bank payout, and Skills setup
/// progressively from the Home & Profile screen without blocking dashboard access.
class NurseSignupScreen extends ConsumerWidget {
  const NurseSignupScreen({super.key});

  bool _canContinue(NurseSignupState s) {
    final d = s.data;
    switch (s.stepIndex) {
      case 0:
        return d.fullName.trim().isNotEmpty &&
            d.dob != null &&
            d.gender != null &&
            d.city.trim().isNotEmpty;
      case 1:
        return d.qualification != null && d.experienceYears.trim().isNotEmpty;
      case 2:
        return d.policeConsent;
      default:
        return false;
    }
  }

  Widget _stepContent(int index) {
    return switch (index) {
      0 => const BasicDetailsStep(),
      1 => const QualificationStep(),
      _ => const PoliceVerificationStep(),
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
    final state = ref.watch(nurseSignupViewModelProvider);
    final notifier = ref.read(nurseSignupViewModelProvider.notifier);
    final isLastStep = state.stepIndex == NurseSignupViewModel.stepCount - 1;
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
      stepCount: NurseSignupViewModel.stepCount,
      step: _stepContent(state.stepIndex),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WizardPrimaryButton(
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
          WizardSecondaryButton(
            label: 'Skip for now',
            onPressed: state.isSubmitting ? null : notifier.submit,
          ),
        ],
      ),
    );
  }
}

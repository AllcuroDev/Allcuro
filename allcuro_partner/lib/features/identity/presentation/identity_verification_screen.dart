import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/wizard_scaffold.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'identity_verification_steps.dart';
import 'identity_verification_view_model.dart';

/// First thing a new nurse / doctor does after picking their role: verify
/// their registration with the council register (NUID → INC NRTS, doctor →
/// NMC), then complete Aadhaar KYC (number + card photo). Only once both are
/// done does the router let them into the sign-up wizard, which prefills
/// (and locks) the verified details.
class IdentityVerificationScreen extends ConsumerWidget {
  const IdentityVerificationScreen({super.key});

  /// The bottom button's label and action for the current step. A null
  /// action renders the button disabled.
  (String, VoidCallback?) _primaryAction(IdentityVerificationState s, IdentityVerificationViewModel vm) {
    if (s.stepIndex == 0) {
      if (s.data.registry != null) return ('Continue to Aadhaar KYC', vm.next);
      final label = vm.isDoctor ? 'Verify with NMC' : 'Verify NUID';
      return (label, vm.registrationReady ? vm.verifyRegistration : null);
    }
    return ('Complete KYC', vm.kycReady ? vm.completeKyc : null);
  }

  Future<void> _confirmExit(BuildContext context, WidgetRef ref) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit verification?'),
        content: const Text("You'll need to log in again and verify to continue setting up your account."),
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
    final state = ref.watch(identityVerificationViewModelProvider);
    final vm = ref.read(identityVerificationViewModelProvider.notifier);
    final (label, action) = _primaryAction(state, vm);

    return WizardScaffold(
      onBack: () {
        if (state.stepIndex > 0) {
          vm.back();
        } else {
          _confirmExit(context, ref);
        }
      },
      stepIndex: state.stepIndex,
      stepCount: IdentityVerificationViewModel.stepCount,
      step: state.stepIndex == 0 ? const RegistrationStep() : const AadhaarStep(),
      bottomBar: WizardPrimaryButton(label: label, loading: state.isBusy, onPressed: action),
    );
  }
}

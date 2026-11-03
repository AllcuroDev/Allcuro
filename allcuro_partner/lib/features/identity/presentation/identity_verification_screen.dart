import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/wizard_scaffold.dart';
import '../../auth/presentation/auth_view_model.dart';
import 'identity_verification_steps.dart';
import 'identity_verification_view_model.dart';

/// First thing a new nurse / doctor / physiotherapist does after picking
/// their role: verify their professional registration, then their Aadhaar.
/// Only once both pass does the router let them into the sign-up wizard,
/// which prefills (and locks) the verified details.
class IdentityVerificationScreen extends ConsumerWidget {
  const IdentityVerificationScreen({super.key});

  /// The bottom button's label and action for the current step and how far
  /// through it the user is. A null action renders the button disabled.
  (String, VoidCallback?) _primaryAction(IdentityVerificationState s, IdentityVerificationViewModel vm) {
    final d = s.data;
    if (s.stepIndex == 0) {
      if (d.registry != null) return ('Continue', vm.next);
      final ready =
          d.registrationNumber.trim().isNotEmpty && (!vm.isClinician || (d.profession != null && d.council != null));
      final label = vm.isClinician ? 'Verify registration' : 'Verify NUID';
      return (label, ready ? vm.verifyRegistration : null);
    }
    if (!d.otpSent) {
      final ready = d.aadhaar.length == 12 && d.aadhaarConsent;
      return ('Send OTP', ready ? vm.sendOtp : null);
    }
    if (d.aadhaarProfile == null) {
      return ('Verify OTP', d.otp.length == 6 ? vm.verifyOtp : null);
    }
    return ('Continue to profile', vm.finish);
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

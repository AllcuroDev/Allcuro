import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/wizard_scaffold.dart';
import '../../clinician/presentation/signup/clinician_signup_view_model.dart';
import '../data/identity_service.dart';
import 'identity_verification_view_model.dart';

const councilOptions = {
  ClinicianProfession.doctor: [
    'National Medical Commission (IMR)',
    'Karnataka Medical Council',
    'Maharashtra Medical Council',
    'Delhi Medical Council',
    'Tamil Nadu Medical Council',
    'Telangana State Medical Council',
    'Other state medical council',
  ],
  ClinicianProfession.physiotherapist: [
    'State Allied & Healthcare Council',
    'State Physiotherapy Council',
    'Indian Association of Physiotherapists',
  ],
};

String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Step 1: NUID for nurses; profession + council + registration number for
/// doctors / physiotherapists. Looks the number up and shows what the
/// register holds.
class RegistrationStep extends ConsumerStatefulWidget {
  const RegistrationStep({super.key});

  @override
  ConsumerState<RegistrationStep> createState() => _RegistrationStepState();
}

class _RegistrationStepState extends ConsumerState<RegistrationStep> {
  late final _number = TextEditingController(
    text: ref.read(identityVerificationViewModelProvider).data.registrationNumber,
  );

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(identityVerificationViewModelProvider);
    final vm = ref.read(identityVerificationViewModelProvider.notifier);
    final data = state.data;
    final registry = data.registry;
    final isClinician = vm.isClinician;
    final isPhysio = data.profession == ClinicianProfession.physiotherapist;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardStepHeader(
          title: isClinician ? 'Verify your registration' : 'Verify your NUID',
          subtitle: isClinician
              ? 'We check your registration number against the council register before you can practise on ALLCURO.'
              : 'Enter your Nurse Unique ID (NUID) from the Indian Nursing Council\'s NRTS. '
                    'We fetch your registration from the council\'s records.',
        ),
        if (isClinician) ...[
          const WizardSectionLabel('I am a'),
          Wrap(
            spacing: 8,
            children: [
              for (final (profession, label) in [
                (ClinicianProfession.doctor, 'Doctor'),
                (ClinicianProfession.physiotherapist, 'Physiotherapist'),
              ])
                WizardChoiceChip(
                  label: label,
                  selected: data.profession == profession,
                  onTap: () => vm.editRegistration((d) {
                    if (d.profession != profession) d.council = null;
                    d.profession = profession;
                  }),
                ),
            ],
          ),
          if (data.profession != null) ...[
            const SizedBox(height: 16),
            WizardSectionLabel(isPhysio ? 'Registered with' : 'Medical council'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: councilOptions[data.profession]!.map((c) {
                return WizardChoiceChip(
                  label: c,
                  selected: data.council == c,
                  onTap: () => vm.editRegistration((d) => d.council = c),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
        ],
        WizardTextField(
          controller: _number,
          label: isClinician
              ? (isPhysio ? 'Physiotherapy registration number' : 'Doctor registration number')
              : 'NUID (Nurse Unique ID)',
          hint: isClinician ? 'e.g. KMC-123456' : 'As shown on your NRTS registration',
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(isClinician ? r'[A-Za-z0-9/\-]' : r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(20),
          ],
          onChanged: (v) => vm.editRegistration((d) => d.registrationNumber = v),
        ),
        if (state.error != null) ...[const SizedBox(height: 14), _ErrorBanner(state.error!)],
        if (registry != null) ...[
          const SizedBox(height: 20),
          WizardVerifiedCard(
            title: isClinician ? 'Registration verified' : 'NUID verified',
            rows: [
              ('Name', registry.registeredName),
              ('Council', registry.council),
              ('Qualification', registry.qualification),
              ('Registered since', '${registry.registeredSince}'),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Step 2: Aadhaar number + e-KYC consent, OTP to the Aadhaar-linked
/// mobile, then the fetched demographic details.
class AadhaarStep extends ConsumerStatefulWidget {
  const AadhaarStep({super.key});

  @override
  ConsumerState<AadhaarStep> createState() => _AadhaarStepState();
}

class _AadhaarStepState extends ConsumerState<AadhaarStep> {
  late final _aadhaar = TextEditingController(
    text: _AadhaarFormatter.group(ref.read(identityVerificationViewModelProvider).data.aadhaar),
  );
  final _otp = TextEditingController();

  @override
  void dispose() {
    _aadhaar.dispose();
    _otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(identityVerificationViewModelProvider);
    final vm = ref.read(identityVerificationViewModelProvider.notifier);
    final data = state.data;
    final profile = data.aadhaarProfile;
    final verified = profile != null;
    final last4 = data.aadhaar.length == 12 ? data.aadhaar.substring(8) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Aadhaar verification',
          subtitle:
              'We confirm your identity with Aadhaar e-KYC. Your name, date of birth, '
              'gender and address are taken from Aadhaar and can\'t be edited later.',
        ),
        WizardTextField(
          controller: _aadhaar,
          label: 'Aadhaar number',
          hint: 'XXXX XXXX XXXX',
          keyboardType: TextInputType.number,
          locked: verified,
          inputFormatters: [_AadhaarFormatter()],
          onChanged: (v) {
            _otp.clear();
            vm.editAadhaar(v.replaceAll(' ', ''));
          },
        ),
        const SizedBox(height: 14),
        if (!verified)
          _ConsentTile(
            checked: data.aadhaarConsent,
            onTap: () {
              data.aadhaarConsent = !data.aadhaarConsent;
              vm.touch();
            },
          ),
        if (data.otpSent && !verified) ...[
          const SizedBox(height: 16),
          WizardTextField(
            controller: _otp,
            label: 'OTP sent to your Aadhaar-linked mobile',
            hint: '6-digit OTP',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
            onChanged: (v) {
              data.otp = v;
              vm.touch();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sent for Aadhaar XXXX XXXX $last4 · Demo OTP: ${IdentityService.demoOtp}',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryForeground.withValues(alpha: 0.65)),
                ),
              ),
              TextButton(
                onPressed: state.isBusy
                    ? null
                    : () {
                        _otp.clear();
                        vm.sendOtp();
                      },
                child: const Text(
                  'Resend',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primarySoft),
                ),
              ),
            ],
          ),
        ],
        if (state.error != null) ...[const SizedBox(height: 14), _ErrorBanner(state.error!)],
        if (verified) ...[
          const SizedBox(height: 6),
          WizardVerifiedCard(
            title: 'Aadhaar verified',
            rows: [
              ('Name', profile.name),
              ('Date of birth', _formatDate(profile.dob)),
              ('Gender', profile.gender),
              ('Address', profile.address),
              ('Aadhaar', 'XXXX XXXX $last4'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primarySoft),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Name matches your ${vm.registrationLabel()} record',
                  style: TextStyle(fontSize: 12.5, color: AppColors.primaryForeground.withValues(alpha: 0.8)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;

  const _ConsentTile({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryForeground.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                color: checked ? AppColors.accent : AppColors.primaryForeground.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'I consent to ALLCURO using my Aadhaar number to fetch my e-KYC details '
                  'from UIDAI for identity verification.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryForeground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.primaryForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.primaryForeground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Digits only, max 12, shown in groups of four ("1234 5678 9012").
class _AadhaarFormatter extends TextInputFormatter {
  static String group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    final text = group(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

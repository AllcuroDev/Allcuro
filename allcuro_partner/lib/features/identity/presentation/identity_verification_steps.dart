import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/pick_photo.dart';
import '../../../core/ui/wizard_scaffold.dart';
import '../data/identity_service.dart';
import 'identity_verification_view_model.dart';

/// Step 1: NUID for nurses (checked against INC NRTS); name + registration
/// number (+ optional State Medical Council and year) for doctors (checked
/// against the NMC Indian Medical Register). Shows what the register holds.
class RegistrationStep extends ConsumerStatefulWidget {
  const RegistrationStep({super.key});

  @override
  ConsumerState<RegistrationStep> createState() => _RegistrationStepState();
}

class _RegistrationStepState extends ConsumerState<RegistrationStep> {
  late final TextEditingController _name;
  late final TextEditingController _number;

  @override
  void initState() {
    super.initState();
    final data = ref.read(identityVerificationViewModelProvider).data;
    _name = TextEditingController(text: data.registeredName);
    _number = TextEditingController(text: data.registrationNumber);
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _pickCouncil(IdentityVerificationState state, IdentityVerificationViewModel vm) async {
    final picked = await _showOptions<MedicalCouncil?>(
      context,
      title: 'State Medical Council',
      options: [(null, 'Any council'), for (final c in state.councils) (c, c.name)],
      searchable: true,
    );
    if (picked == null) return;
    vm.editRegistration((d) => d.council = picked.$1);
  }

  Future<void> _pickYear(IdentityVerificationState state, IdentityVerificationViewModel vm) async {
    final picked = await _showOptions<int?>(
      context,
      title: 'Year of registration',
      options: [(null, 'Any year'), for (final y in state.years) (y, '$y')],
    );
    if (picked == null) return;
    vm.editRegistration((d) => d.year = picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(identityVerificationViewModelProvider);
    final vm = ref.read(identityVerificationViewModelProvider.notifier);
    final data = state.data;
    final registry = data.registry;
    final isDoctor = vm.isDoctor;
    final showName = isDoctor || data.portalDown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardStepHeader(
          title: isDoctor ? 'Verify your NMC registration' : 'Verify your NUID',
          subtitle: isDoctor
              ? 'We check your name and registration number against the National Medical Commission\'s '
                    'Indian Medical Register.'
              : 'Enter your Nurse Unique ID (NUID). We fetch your registration from the Indian Nursing '
                    'Council\'s NRTS register.',
        ),
        if (showName) ...[
          WizardTextField(
            key: const ValueKey('registered-name'),
            controller: _name,
            label: 'Full name (as registered)',
            hint: isDoctor ? 'As on your NMC / council registration' : 'As on your nursing council registration',
            locked: registry != null,
            onChanged: (v) => vm.editRegistration((d) => d.registeredName = v),
          ),
          const SizedBox(height: 14),
        ],
        WizardTextField(
          key: const ValueKey('registration-number'),
          controller: _number,
          label: isDoctor ? 'Medical registration number' : 'NUID (Nurse Unique ID)',
          hint: isDoctor ? 'Exactly as on your registration certificate' : 'e.g. ABC123456',
          locked: registry != null,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(isDoctor ? r'[A-Za-z0-9/\-]' : r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(isDoctor ? 20 : 12),
          ],
          onChanged: (v) => vm.editRegistration((d) => d.registrationNumber = v),
        ),
        if (isDoctor) ...[
          const SizedBox(height: 14),
          _SelectField(
            label: 'State Medical Council (optional)',
            value: data.council?.name,
            placeholder: state.councils.isEmpty ? 'Loading councils…' : 'Any council',
            onTap: registry != null || state.councils.isEmpty ? null : () => _pickCouncil(state, vm),
          ),
          const SizedBox(height: 14),
          _SelectField(
            label: 'Year of registration (optional)',
            value: data.year?.toString(),
            placeholder: state.years.isEmpty ? 'Loading years…' : 'Any year',
            onTap: registry != null || state.years.isEmpty ? null : () => _pickYear(state, vm),
          ),
        ],
        if (state.error != null) ...[const SizedBox(height: 14), _ErrorBanner(state.error!)],
        if (data.portalDown && registry == null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: state.isBusy ? null : vm.continueWithoutCheck,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primarySoft),
              label: const Text(
                'Continue — ALLCURO will verify manually',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primarySoft),
              ),
            ),
          ),
        ],
        if (registry != null) ...[
          const SizedBox(height: 20),
          WizardVerifiedCard(
            title: registry.autoVerified
                ? (isDoctor ? 'Found in the Indian Medical Register' : 'NUID verified with INC')
                : 'Saved — ALLCURO will verify',
            rows: registry.fields,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: state.isBusy ? null : () => vm.editRegistration((_) {}),
              child: const Text(
                'Not you? Edit details',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primarySoft),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Step 2: Aadhaar KYC — the Aadhaar number plus a photo of the card (front
/// required, back optional), reviewed by ALLCURO before approval.
class AadhaarStep extends ConsumerStatefulWidget {
  const AadhaarStep({super.key});

  @override
  ConsumerState<AadhaarStep> createState() => _AadhaarStepState();
}

class _AadhaarStepState extends ConsumerState<AadhaarStep> {
  late final TextEditingController _aadhaar;

  @override
  void initState() {
    super.initState();
    _aadhaar = TextEditingController(
      text: _AadhaarFormatter.group(ref.read(identityVerificationViewModelProvider).data.aadhaar),
    );
  }

  @override
  void dispose() {
    _aadhaar.dispose();
    super.dispose();
  }

  Future<void> _pick(IdentityVerificationViewModel vm, {required bool front}) async {
    final photo = await pickPhoto(context, title: front ? 'Aadhaar card — front' : 'Aadhaar card — back');
    if (photo != null) vm.setAadhaarPhoto(front: front, photo: photo);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(identityVerificationViewModelProvider);
    final vm = ref.read(identityVerificationViewModelProvider.notifier);
    final data = state.data;
    final registry = data.registry;
    final invalid = data.aadhaar.length == 12 && !IdentityService.isValidAadhaar(data.aadhaar);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Aadhaar KYC',
          subtitle:
              'Enter your Aadhaar number and upload a clear photo of your Aadhaar card. ALLCURO '
              'matches it with your registration before your profile goes live.',
        ),
        if (registry != null) ...[
          _InfoPill(text: 'KYC for ${registry.registeredName.isEmpty ? data.registeredName : registry.registeredName}'),
          const SizedBox(height: 16),
        ],
        WizardTextField(
          controller: _aadhaar,
          label: 'Aadhaar number',
          hint: 'XXXX XXXX XXXX',
          keyboardType: TextInputType.number,
          inputFormatters: [_AadhaarFormatter()],
          onChanged: (v) {
            data.aadhaar = v.replaceAll(' ', '');
            vm.touch();
          },
        ),
        if (invalid) ...[
          const SizedBox(height: 8),
          const Text(
            'This doesn\'t look like a valid Aadhaar number. Check the digits.',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.warning),
          ),
        ],
        const SizedBox(height: 18),
        const WizardSectionLabel('Aadhaar card photo'),
        _PhotoSlot(
          label: 'Front side (required)',
          photo: data.aadhaarFront,
          uploading: state.isBusy && data.aadhaarFront != null,
          onTap: state.isBusy ? null : () => _pick(vm, front: true),
        ),
        const SizedBox(height: 10),
        _PhotoSlot(
          label: 'Back side (optional — has your address)',
          photo: data.aadhaarBack,
          uploading: state.isBusy && data.aadhaarBack != null,
          onTap: state.isBusy ? null : () => _pick(vm, front: false),
        ),
        const SizedBox(height: 16),
        _ConsentTile(
          checked: data.aadhaarConsent,
          onTap: () {
            data.aadhaarConsent = !data.aadhaarConsent;
            vm.touch();
          },
        ),
        if (state.error != null) ...[const SizedBox(height: 14), _ErrorBanner(state.error!)],
        const SizedBox(height: 24),
      ],
    );
  }
}

/// A picked Aadhaar photo with a thumbnail, or an upload row before one is picked.
class _PhotoSlot extends StatelessWidget {
  final String label;
  final PickedPhoto? photo;
  final bool uploading;
  final VoidCallback? onTap;

  const _PhotoSlot({required this.label, required this.photo, required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final picked = photo;
    if (picked == null) return WizardUploadTile(label: label, onTap: onTap);
    return Material(
      color: AppColors.primaryForeground.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.memory(picked.bytes, width: 88, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryForeground)),
                    Text(
                      picked.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.primaryForeground.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
              if (uploading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primaryForeground),
                )
              else
                const Text(
                  'Replace',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primarySoft),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A read-only field that opens a picker — styled like [WizardTextField].
class _SelectField extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  const _SelectField({required this.label, required this.value, required this.placeholder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.primaryForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: fg.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 8),
        Material(
          color: fg.withValues(alpha: onTap == null ? 0.06 : 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: fg.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
                        color: fg.withValues(alpha: value == null ? 0.5 : 1),
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, color: fg.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom-sheet list picker. Returns a 1-tuple so "Any" (null) can be told
/// apart from a dismissed sheet.
Future<(T,)?> _showOptions<T>(
  BuildContext context, {
  required String title,
  required List<(T, String)> options,
  bool searchable = false,
}) {
  return showModalBottomSheet<(T,)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
    builder: (ctx) {
      var query = '';
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          final shown = options.where((o) => o.$2.toLowerCase().contains(query.toLowerCase())).toList();
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SafeArea(
            child: SizedBox(
              height: MediaQuery.of(ctx).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
                  ),
                  if (searchable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: TextField(
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search'),
                        onChanged: (v) => setSheet(() => query = v),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: shown.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(shown[i].$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                        onTap: () => Navigator.pop(ctx, (shown[i].$1,)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      );
    },
  );
}

class _InfoPill extends StatelessWidget {
  final String text;

  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryForeground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_outlined, size: 16, color: AppColors.primarySoft),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryForeground),
            ),
          ),
        ],
      ),
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
                  'I consent to ALLCURO storing my Aadhaar card photo and the last 4 digits of my '
                  'Aadhaar number to verify my identity.',
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

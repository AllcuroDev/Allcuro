import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/wizard_scaffold.dart';

const genderOptions = ['Female', 'Male', 'Other'];

String formatDob(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Date of birth, gender and address inputs for the sign-up wizards — shown
/// for whichever of these Aadhaar e-KYC didn't return (each `show…` flag),
/// so the partner enters their own details instead of the app inventing
/// them.
class PersonalDetailsFields extends StatefulWidget {
  final bool showDob;
  final bool showGender;
  final bool showAddress;
  final DateTime? dob;
  final String? gender;
  final String address;
  final ValueChanged<DateTime> onDobChanged;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onAddressChanged;

  const PersonalDetailsFields({
    super.key,
    required this.showDob,
    required this.showGender,
    required this.showAddress,
    required this.dob,
    required this.gender,
    required this.address,
    required this.onDobChanged,
    required this.onGenderChanged,
    required this.onAddressChanged,
  });

  @override
  State<PersonalDetailsFields> createState() => _PersonalDetailsFieldsState();
}

class _PersonalDetailsFieldsState extends State<PersonalDetailsFields> {
  late final _address = TextEditingController(text: widget.address);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.dob ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked != null) widget.onDobChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showDob) ...[
          const WizardSectionLabel('Date of birth'),
          Material(
            color: AppColors.primaryForeground.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xxxl),
              side: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
            ),
            child: InkWell(
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xxxl)),
              onTap: _pickDob,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.cake_outlined, size: 18, color: AppColors.primaryForeground),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.dob == null ? 'Select your date of birth' : formatDob(widget.dob!),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryForeground),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.showGender) ...[
          const WizardSectionLabel('Gender'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genderOptions
                .map(
                  (g) => WizardChoiceChip(
                    label: g,
                    selected: widget.gender == g,
                    onTap: () => widget.onGenderChanged(g),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.showAddress) ...[
          WizardTextField(
            controller: _address,
            label: 'Home address',
            maxLines: 2,
            onChanged: widget.onAddressChanged,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

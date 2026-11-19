import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/screen_header.dart';
import '../../../../core/ui/surface.dart';

/// Editable view of what families see on the centre's public listing.
/// Everything starts empty — the centre fills it in. Edits only update local
/// state for now (ALLCURO sets the final published price). Pushed from the centre home screen's "More tools"
/// grid.
class ListingManagementScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ListingManagementScreen({super.key, required this.onBack});

  @override
  State<ListingManagementScreen> createState() => _ListingManagementScreenState();
}

class _ListingManagementScreenState extends State<ListingManagementScreen> {
  late final _price = TextEditingController();
  late final _ratio = TextEditingController();
  int _photoCount = 0;
  bool _accepting = true;

  @override
  void dispose() {
    _price.dispose();
    _ratio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: 'Listing management',
              subtitle: 'What families see on your public listing',
              onBack: widget.onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _LabeledField(
                    label: 'Price per package (₹/day)',
                    controller: _price,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _LabeledField(
                    label: 'Staff-to-patient ratio',
                    controller: _ratio,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Photos'),
                  Surface(
                    onTap: () => setState(() => _photoCount += 1),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _photoCount == 0 ? 'No photos yet' : '$_photoCount photo${_photoCount == 1 ? '' : 's'} added',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                        const Text(
                          'Add more',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Availability'),
                  Surface(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Accepting new placements',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                        Switch(
                          value: _accepting,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setState(() => _accepting = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Listing changes saved. ALLCURO reviews them before they go live.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.accentForeground,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save changes',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.mutedForeground,
        ),
      ),
    );
  }
}

/// Local text-field wrapper matching the house style (label above, hairline
/// border, [AppRadius.lg] corners) without pulling in the sign-up wizard's
/// `WizardTextField`, since this screen isn't part of a wizard flow.
class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

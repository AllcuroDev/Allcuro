import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/wizard_scaffold.dart';
import 'nurse_signup_view_model.dart';

const skillTags = [
  'ICU',
  'Palliative care',
  'Pediatric',
  'Geriatric',
  'Wound care',
  'Ventilator',
  'Dialysis-assist',
  'Diabetic care',
];

/// Preferred interview windows — ALLCURO confirms the exact time.
const interviewSlots = [
  'Weekday morning (10 AM – 1 PM)',
  'Weekday afternoon (2 PM – 5 PM)',
  'Saturday morning (10 AM – 1 PM)',
];

/// Step 7: 1–2 previous employer/supervisor references.
class ReferenceCheckStep extends ConsumerStatefulWidget {
  const ReferenceCheckStep({super.key});

  @override
  ConsumerState<ReferenceCheckStep> createState() => _ReferenceCheckStepState();
}

class _ReferenceCheckStepState extends ConsumerState<ReferenceCheckStep> {
  late final List<Map<String, TextEditingController>> _controllers = _data.references
      .map(
        (r) => {
          'name': TextEditingController(text: r.name),
          'relation': TextEditingController(text: r.relation),
          'phone': TextEditingController(text: r.phone),
        },
      )
      .toList();

  NurseSignupData get _data => ref.read(nurseSignupViewModelProvider).data;

  @override
  void dispose() {
    for (final c in _controllers) {
      for (final controller in c.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(nurseSignupViewModelProvider).data;
    final notifier = ref.read(nurseSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Reference check',
          subtitle: 'ALLCURO ops will call these contacts. The second one is optional.',
        ),
        for (var i = 0; i < data.references.length; i++) ...[
          WizardSectionLabel(i == 0 ? 'Reference 1 (required)' : 'Reference 2 (optional)'),
          WizardTextField(
            controller: _controllers[i]['name']!,
            label: 'Name',
            hint: 'Full name',
            onChanged: (v) {
              data.references[i].name = v;
              notifier.touch();
            },
          ),
          const SizedBox(height: 12),
          WizardTextField(
            controller: _controllers[i]['relation']!,
            label: 'Relation',
            hint: 'e.g. Ward supervisor, Head nurse',
            onChanged: (v) {
              data.references[i].relation = v;
              notifier.touch();
            },
          ),
          const SizedBox(height: 12),
          WizardTextField(
            controller: _controllers[i]['phone']!,
            label: 'Phone number',
            hint: '10-digit mobile number',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            onChanged: (v) {
              data.references[i].phone = v;
              notifier.touch();
            },
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

/// Step 8: multi-select specialisation tags.
class SkillsStep extends ConsumerWidget {
  const SkillsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(nurseSignupViewModelProvider).data;
    final notifier = ref.read(nurseSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Skills & specialisation',
          subtitle: 'Pick everything you\'re experienced in — this drives which requests you see.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skillTags.map((tag) {
            final selected = data.skills.contains(tag);
            return WizardChoiceChip(
              label: tag,
              selected: selected,
              onTap: () {
                if (selected) {
                  data.skills.remove(tag);
                } else {
                  data.skills.add(tag);
                }
                notifier.touch();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Step 9: payout bank details.
class BankDetailsStep extends ConsumerStatefulWidget {
  const BankDetailsStep({super.key});

  @override
  ConsumerState<BankDetailsStep> createState() => _BankDetailsStepState();
}

class _BankDetailsStepState extends ConsumerState<BankDetailsStep> {
  late final _holder = TextEditingController(text: _data.bankAccountHolder);
  late final _number = TextEditingController(text: _data.bankAccountNumber);
  late final _ifsc = TextEditingController(text: _data.bankIfsc);

  NurseSignupData get _data => ref.read(nurseSignupViewModelProvider).data;

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _ifsc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(nurseSignupViewModelProvider).data;
    final notifier = ref.read(nurseSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Bank details',
          subtitle: 'For shift payouts via Razorpay Route — never shared with families.',
        ),
        WizardTextField(
          controller: _holder,
          label: 'Account holder name',
          onChanged: (v) {
            data.bankAccountHolder = v;
            notifier.touch();
          },
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _number,
          label: 'Account number',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            data.bankAccountNumber = v;
            notifier.touch();
          },
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _ifsc,
          label: 'IFSC code',
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
          onChanged: (v) {
            data.bankIfsc = v.toUpperCase();
            notifier.touch();
          },
        ),
      ],
    );
  }
}

/// Step 10: pick a video-interview / orientation slot.
class InterviewBookingStep extends ConsumerWidget {
  const InterviewBookingStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(nurseSignupViewModelProvider).data;
    final notifier = ref.read(nurseSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Book your orientation call',
          subtitle: 'A short video interview — the final human step before activation.',
        ),
        ...interviewSlots.map((slot) {
          final selected = data.interviewSlot == slot;
          final shape = RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            side: BorderSide(
              color: selected ? AppColors.primarySoft : AppColors.primaryForeground.withValues(alpha: 0.25),
            ),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected
                  ? AppColors.primaryForeground.withValues(alpha: 0.2)
                  : AppColors.primaryForeground.withValues(alpha: 0.08),
              shape: shape,
              child: InkWell(
                customBorder: shape,
                onTap: () {
                  data.interviewSlot = slot;
                  notifier.touch();
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: 18,
                        color: selected
                            ? AppColors.primaryForeground
                            : AppColors.primaryForeground.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.primaryForeground
                                : AppColors.primaryForeground.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Icon(
                        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: selected
                            ? AppColors.primaryForeground
                            : AppColors.primaryForeground.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Step 11: summary before the profile enters the admin review queue.
class ReviewSubmitStep extends ConsumerWidget {
  const ReviewSubmitStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(nurseSignupViewModelProvider).data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Review & submit',
          subtitle: 'Once submitted, your profile enters our verification queue.',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryForeground.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            border: Border.all(color: AppColors.primaryForeground.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _SummaryRow(label: 'Name', value: data.fullName),
              _SummaryRow(label: 'Employment type', value: data.employmentType ?? '—'),
              _SummaryRow(label: 'Qualification', value: data.qualification ?? '—'),
              _SummaryRow(label: 'Experience', value: '${data.experienceYears} years'),
              _SummaryRow(label: 'Skills', value: data.skills.isEmpty ? '—' : data.skills.join(', ')),
              _SummaryRow(label: 'Interview slot', value: data.interviewSlot ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Verification usually takes 2–4 working days. You can still '
                  'explore the dashboard while your profile is under review.',
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: AppColors.primaryForeground.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryForeground),
            ),
          ),
        ],
      ),
    );
  }
}

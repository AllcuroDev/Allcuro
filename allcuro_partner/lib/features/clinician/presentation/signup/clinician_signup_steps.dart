import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/wizard_scaffold.dart';
import 'clinician_signup_view_model.dart';

const qualificationOptions = {
  ClinicianProfession.doctor: ['MBBS', 'MD', 'MS', 'DNB', 'BAMS', 'BHMS'],
  ClinicianProfession.physiotherapist: ['BPT', 'MPT', 'DPT', 'Diploma in Physiotherapy'],
};

const specialisationOptions = {
  ClinicianProfession.doctor: [
    'General Physician',
    'Geriatrics',
    'Internal Medicine',
    'Paediatrics',
    'Palliative care',
    'Wound care',
  ],
  ClinicianProfession.physiotherapist: [
    'Orthopaedic',
    'Neuro rehab',
    'Cardio-pulmonary',
    'Geriatric',
    'Post-surgical rehab',
    'Sports',
  ],
};

const registrationLabels = {
  ClinicianProfession.doctor: 'NMC / State Medical Council reg. no.',
  ClinicianProfession.physiotherapist: 'State Physiotherapy Council / IAP reg. no.',
};

/// Step 1: profession, name, gender, city.
class ClinicianBasicDetailsStep extends ConsumerStatefulWidget {
  const ClinicianBasicDetailsStep({super.key});

  @override
  ConsumerState<ClinicianBasicDetailsStep> createState() => _ClinicianBasicDetailsStepState();
}

class _ClinicianBasicDetailsStepState extends ConsumerState<ClinicianBasicDetailsStep> {
  late final _name = TextEditingController(text: _data.fullName);
  late final _city = TextEditingController(text: _data.city);

  ClinicianSignupData get _data => ref.read(clinicianSignupViewModelProvider).data;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(clinicianSignupViewModelProvider).data;
    final notifier = ref.read(clinicianSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Tell us about yourself',
          subtitle: 'These details go on your public profile once verified.',
        ),
        const WizardSectionLabel('I am a'),
        Row(
          children: [
            Expanded(
              child: _ProfessionCard(
                icon: Icons.medical_information_outlined,
                label: 'Doctor',
                selected: data.profession == ClinicianProfession.doctor,
                onTap: () => notifier.setProfession(ClinicianProfession.doctor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfessionCard(
                icon: Icons.accessibility_new_rounded,
                label: 'Physiotherapist',
                selected: data.profession == ClinicianProfession.physiotherapist,
                onTap: () => notifier.setProfession(ClinicianProfession.physiotherapist),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        WizardTextField(controller: _name, label: 'Full name', hint: 'As per your govt ID', onChanged: (v) {
          data.fullName = v;
          notifier.touch();
        }),
        const SizedBox(height: 16),
        const WizardSectionLabel('Gender'),
        Wrap(
          spacing: 8,
          children: ['Female', 'Male', 'Other'].map((g) {
            return WizardChoiceChip(
              label: g,
              selected: data.gender == g,
              onTap: () {
                data.gender = g;
                notifier.touch();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        WizardTextField(controller: _city, label: 'City', hint: 'Bengaluru', onChanged: (v) {
          data.city = v;
          notifier.touch();
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ProfessionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProfessionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      side: BorderSide(
        color: selected ? AppColors.primarySoft : AppColors.primaryForeground.withValues(alpha: 0.25),
        width: selected ? 1.5 : 1,
      ),
    );
    return Material(
      color: selected
          ? AppColors.primaryForeground.withValues(alpha: 0.2)
          : AppColors.primaryForeground.withValues(alpha: 0.08),
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 26, color: AppColors.primaryForeground),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 2: qualification, specialisations, council registration, experience.
class ClinicianQualificationStep extends ConsumerStatefulWidget {
  const ClinicianQualificationStep({super.key});

  @override
  ConsumerState<ClinicianQualificationStep> createState() => _ClinicianQualificationStepState();
}

class _ClinicianQualificationStepState extends ConsumerState<ClinicianQualificationStep> {
  late final _registration = TextEditingController(text: _data.registrationNumber);
  late final _years = TextEditingController(text: _data.experienceYears);

  ClinicianSignupData get _data => ref.read(clinicianSignupViewModelProvider).data;

  @override
  void dispose() {
    _registration.dispose();
    _years.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(clinicianSignupViewModelProvider).data;
    final notifier = ref.read(clinicianSignupViewModelProvider.notifier);
    final profession = data.profession ?? ClinicianProfession.doctor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Qualification & registration',
          subtitle: 'This decides which home-visit requests you\'re eligible for.',
        ),
        const WizardSectionLabel('Highest qualification'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: qualificationOptions[profession]!.map((q) {
            return WizardChoiceChip(
              label: q,
              selected: data.qualification == q,
              onTap: () {
                data.qualification = q;
                notifier.touch();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const WizardSectionLabel('Specialisations'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specialisationOptions[profession]!.map((tag) {
            final selected = data.specialisations.contains(tag);
            return WizardChoiceChip(
              label: tag,
              selected: selected,
              onTap: () {
                if (selected) {
                  data.specialisations.remove(tag);
                } else {
                  data.specialisations.add(tag);
                }
                notifier.touch();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _registration,
          label: registrationLabels[profession]!,
          hint: 'e.g. KMC-123456',
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9/\-]'))],
          onChanged: (v) {
            data.registrationNumber = v;
            notifier.touch();
          },
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _years,
          label: 'Years of experience',
          hint: 'e.g. 4',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) {
            data.experienceYears = v;
            notifier.touch();
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Step 3: consent for council-registration & background verification.
class ClinicianVerificationStep extends ConsumerWidget {
  const ClinicianVerificationStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(clinicianSignupViewModelProvider).data;
    final notifier = ref.read(clinicianSignupViewModelProvider.notifier);
    final council = data.profession == ClinicianProfession.physiotherapist
        ? 'physiotherapy council'
        : 'medical council';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Verification',
          subtitle: 'Mandatory before your profile is visible to families.',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We verify your registration with the $council and run a '
                  'background check through a third-party partner. This usually '
                  'takes 2–4 working days and happens automatically.',
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Material(
          color: AppColors.primaryForeground.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: () {
              data.backgroundConsent = !data.backgroundConsent;
              notifier.touch();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Icon(
                    data.backgroundConsent ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    color: data.backgroundConsent
                        ? AppColors.accent
                        : AppColors.primaryForeground.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I consent to ALLCURO verifying my registration and running a '
                      'background check on my behalf.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryForeground),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

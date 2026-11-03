import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/wizard_scaffold.dart';
import 'clinician_signup_view_model.dart';

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

String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Step 1: profession, name, DOB, gender and address (locked — from Aadhaar
/// and the council register), plus the city they'll work in.
class ClinicianBasicDetailsStep extends ConsumerStatefulWidget {
  const ClinicianBasicDetailsStep({super.key});

  @override
  ConsumerState<ClinicianBasicDetailsStep> createState() => _ClinicianBasicDetailsStepState();
}

class _ClinicianBasicDetailsStepState extends ConsumerState<ClinicianBasicDetailsStep> {
  late final _city = TextEditingController(text: ref.read(clinicianSignupViewModelProvider).data.city);

  @override
  void dispose() {
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
          subtitle: "Your identity details come from Aadhaar and can't be changed.",
        ),
        WizardVerifiedCard(
          title: 'Verified from Aadhaar',
          rows: [
            if (data.profession != null)
              ('I am a', data.profession == ClinicianProfession.doctor ? 'Doctor' : 'Physiotherapist'),
            ('Full name', data.fullName),
            if (data.dob != null) ('Date of birth', _formatDate(data.dob!)),
            if (data.gender != null) ('Gender', data.gender!),
            ('Address', data.address),
          ],
        ),
        const SizedBox(height: 16),
        WizardTextField(controller: _city, label: "City you'll work in", hint: 'Bengaluru', onChanged: (v) {
          data.city = v;
          notifier.touch();
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Step 2: qualification and registration number (locked — from the council
/// register), specialisations, experience.
class ClinicianQualificationStep extends ConsumerStatefulWidget {
  const ClinicianQualificationStep({super.key});

  @override
  ConsumerState<ClinicianQualificationStep> createState() => _ClinicianQualificationStepState();
}

class _ClinicianQualificationStepState extends ConsumerState<ClinicianQualificationStep> {
  late final _qualification = TextEditingController(text: _data.qualification);
  late final _registration = TextEditingController(text: _data.registrationNumber);
  late final _years = TextEditingController(text: _data.experienceYears);

  ClinicianSignupData get _data => ref.read(clinicianSignupViewModelProvider).data;

  @override
  void dispose() {
    _qualification.dispose();
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
        WizardStepHeader(
          title: 'Qualification & registration',
          subtitle: data.council.isEmpty
              ? "This decides which home-visit requests you're eligible for."
              : 'Qualification and registration are as recorded with the ${data.council}.',
        ),
        WizardTextField(controller: _qualification, label: 'Highest qualification', locked: true),
        const SizedBox(height: 16),
        WizardTextField(controller: _registration, label: registrationLabels[profession]!, locked: true),
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

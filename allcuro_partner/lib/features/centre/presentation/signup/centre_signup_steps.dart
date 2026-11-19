import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/wizard_scaffold.dart';
import 'centre_signup_view_model.dart';

const centreTypeOptions = ['Elderly care', 'Rehab', 'Day-care', 'Physiotherapy', 'Palliative'];
const ownershipTypeOptions = ['Individual', 'Partnership', 'Trust', 'Company'];

const legalDocumentLabels = {
  'business_registration': 'Business registration certificate',
  'clinical_establishment_licence': 'Clinical Establishment Act licence',
  'fire_noc': 'Fire NOC / building safety certificate',
  'gst_registration': 'GST registration',
  'pan_aadhaar': 'PAN of entity + owner Aadhaar',
  'biomedical_waste_authorisation': 'Biomedical waste management authorisation',
  'fire_safety_photos': 'Fire & safety compliance photos',
  'ambulance_tie_up': 'Ambulance tie-up proof (if claimed)',
};

const siteVisitSlots = [
  'Weekday morning (10 AM – 1 PM)',
  'Weekday afternoon (2 PM – 5 PM)',
  'Saturday morning (10 AM – 1 PM)',
];

const roomTypeOptions = ['General Ward', 'Private Room', 'ICU'];

/// Step 1: business email (mobile + OTP already happened globally).
class BusinessEmailStep extends ConsumerStatefulWidget {
  const BusinessEmailStep({super.key});

  @override
  ConsumerState<BusinessEmailStep> createState() => _BusinessEmailStepState();
}

class _BusinessEmailStepState extends ConsumerState<BusinessEmailStep> {
  late final _email = TextEditingController(text: _data.businessEmail);

  CentreSignupData get _data => ref.read(centreSignupViewModelProvider).data;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(centreSignupViewModelProvider).data;
    final notifier = ref.read(centreSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: "What's your business email?",
          subtitle: "We'll send verification updates and settlement statements here.",
        ),
        WizardTextField(
          controller: _email,
          label: 'Business email',
          hint: 'ops@yourcentre.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) {
            data.businessEmail = v;
            notifier.touch();
          },
        ),
      ],
    );
  }
}

/// Step 2: centre name, type, year established, ownership type.
class EntityDetailsStep extends ConsumerStatefulWidget {
  const EntityDetailsStep({super.key});

  @override
  ConsumerState<EntityDetailsStep> createState() => _EntityDetailsStepState();
}

class _EntityDetailsStepState extends ConsumerState<EntityDetailsStep> {
  late final _name = TextEditingController(text: _data.centreName);
  late final _year = TextEditingController(text: _data.yearEstablished);

  CentreSignupData get _data => ref.read(centreSignupViewModelProvider).data;

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(centreSignupViewModelProvider).data;
    final notifier = ref.read(centreSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(title: 'Tell us about your centre'),
        WizardTextField(
          controller: _name,
          label: 'Centre name',
          onChanged: (v) {
            data.centreName = v;
            notifier.touch();
          },
        ),
        const SizedBox(height: 16),
        const WizardSectionLabel('Centre type'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: centreTypeOptions.map((t) {
            return WizardChoiceChip(
              label: t,
              selected: data.centreType == t,
              onTap: () {
                data.centreType = t;
                notifier.touch();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _year,
          label: 'Year established',
          hint: 'e.g. 2018',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            data.yearEstablished = v;
            notifier.touch();
          },
        ),
        const SizedBox(height: 16),
        const WizardSectionLabel('Ownership type'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ownershipTypeOptions.map((o) {
            return WizardChoiceChip(
              label: o,
              selected: data.ownershipType == o,
              onTap: () {
                data.ownershipType = o;
                notifier.touch();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Step 3: the "legitimacy filter" — 8 mandatory legal documents.
class LegalDocumentsStep extends ConsumerWidget {
  const LegalDocumentsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(centreSignupViewModelProvider);
    final notifier = ref.read(centreSignupViewModelProvider.notifier);
    final docs = state.data.documents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Legal documents',
          subtitle: 'The core legitimacy filter — most unlicensed setups can\'t produce all of these.',
        ),
        ...legalDocumentLabels.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WizardUploadTile(
              label: entry.value,
              fileName: docs[entry.key],
              uploading: state.uploadingIds.contains(entry.key),
              onTap: () => notifier.mockUpload(docs, entry.key, '${entry.value}.pdf'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 4: staff roster with qualifications.
class StaffListStep extends ConsumerWidget {
  const StaffListStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(centreSignupViewModelProvider).data;
    final notifier = ref.read(centreSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Staff on payroll',
          subtitle: 'Every nurse, doctor, or attendant working at your centre.',
        ),
        for (var i = 0; i < data.staff.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StaffRow(
              index: i,
              staff: data.staff[i],
              canRemove: data.staff.length > 1,
              onRemove: () => notifier.removeStaffMember(i),
              onChanged: notifier.touch,
            ),
          ),
        Material(
          color: AppColors.primaryForeground.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: notifier.addStaffMember,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  '+ Add staff member',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryForeground),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffRow extends StatefulWidget {
  final int index;
  final StaffMember staff;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _StaffRow({
    required this.index,
    required this.staff,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_StaffRow> createState() => _StaffRowState();
}

class _StaffRowState extends State<_StaffRow> {
  late final _name = TextEditingController(text: widget.staff.name);
  late final _qualification = TextEditingController(text: widget.staff.qualification);

  @override
  void dispose() {
    _name.dispose();
    _qualification.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryForeground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.primaryForeground.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Staff ${widget.index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryForeground.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (widget.canRemove)
                InkWell(
                  onTap: widget.onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.primaryForeground.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          WizardTextField(
            controller: _name,
            label: 'Name',
            onChanged: (v) {
              widget.staff.name = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          WizardTextField(
            controller: _qualification,
            label: 'Qualification',
            hint: 'e.g. GNM, MBBS, Certified Attendant',
            onChanged: (v) {
              widget.staff.qualification = v;
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }
}

/// Step 5: schedule the mandatory on-site verification visit.
class SiteVisitStep extends ConsumerWidget {
  const SiteVisitStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(centreSignupViewModelProvider).data;
    final notifier = ref.read(centreSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'On-site verification',
          subtitle: 'A field agent visits before you go live — non-negotiable, like a hotel-onboarding audit.',
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_searching_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Our field agent will photograph and inspect the premises '
                  'during the visit. Please have a centre representative available.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const WizardSectionLabel('Pick a visit slot'),
        ...siteVisitSlots.map((slot) {
          final selected = data.siteVisitSlot == slot;
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
                  data.siteVisitSlot = slot;
                  notifier.touch();
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
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

/// Step 6: settlement bank account + GST.
class SettlementDetailsStep extends ConsumerStatefulWidget {
  const SettlementDetailsStep({super.key});

  @override
  ConsumerState<SettlementDetailsStep> createState() => _SettlementDetailsStepState();
}

class _SettlementDetailsStepState extends ConsumerState<SettlementDetailsStep> {
  late final _holder = TextEditingController(text: _data.bankAccountHolder);
  late final _number = TextEditingController(text: _data.bankAccountNumber);
  late final _ifsc = TextEditingController(text: _data.bankIfsc);
  late final _gst = TextEditingController(text: _data.gstNumber);

  CentreSignupData get _data => ref.read(centreSignupViewModelProvider).data;

  @override
  void dispose() {
    _holder.dispose();
    _number.dispose();
    _ifsc.dispose();
    _gst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(centreSignupViewModelProvider).data;
    final notifier = ref.read(centreSignupViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Settlement details',
          subtitle: 'Payouts settle to this account via a Razorpay Route sub-account.',
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
          onChanged: (v) {
            data.bankIfsc = v.toUpperCase();
            notifier.touch();
          },
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _gst,
          label: 'GST number',
          onChanged: (v) {
            data.gstNumber = v.toUpperCase();
            notifier.touch();
          },
        ),
      ],
    );
  }
}

/// Step 7: the public listing — photos, pricing, services, room types.
class ListingCreationStep extends ConsumerStatefulWidget {
  const ListingCreationStep({super.key});

  @override
  ConsumerState<ListingCreationStep> createState() => _ListingCreationStepState();
}

class _ListingCreationStepState extends ConsumerState<ListingCreationStep> {
  late final _price = TextEditingController(text: _data.pricePerPackage);
  late final _ratio = TextEditingController(text: _data.staffRatio);
  late final _menu = TextEditingController(text: _data.sampleFoodMenu);

  CentreSignupData get _data => ref.read(centreSignupViewModelProvider).data;

  @override
  void dispose() {
    _price.dispose();
    _ratio.dispose();
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(centreSignupViewModelProvider).data;
    final notifier = ref.read(centreSignupViewModelProvider.notifier);
    const minPhotos = 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Create your listing',
          subtitle: 'What families see once you\'re live.',
        ),
        const WizardSectionLabel('Photos'),
        Material(
          color: AppColors.primaryForeground.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
            side: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xxxl),
              side: BorderSide(color: AppColors.primaryForeground.withValues(alpha: 0.25)),
            ),
            onTap: () {
              data.photoCount += 1;
              notifier.touch();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.primaryForeground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      data.photoCount == 0
                          ? 'Tap to add photos (minimum $minPhotos)'
                          : '${data.photoCount} photo${data.photoCount == 1 ? '' : 's'} added',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryForeground),
                    ),
                  ),
                  Text(
                    data.photoCount >= minPhotos ? 'Enough ✓' : '${data.photoCount}/$minPhotos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: data.photoCount >= minPhotos ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _price,
          label: 'Pricing per package (₹/day)',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            data.pricePerPackage = v;
            notifier.touch();
          },
        ),
        const SizedBox(height: 16),
        const WizardSectionLabel('Services included'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: centreTypeOptions.map((s) {
            final selected = data.servicesIncluded.contains(s);
            return WizardChoiceChip(
              label: s,
              selected: selected,
              onTap: () {
                if (selected) {
                  data.servicesIncluded.remove(s);
                } else {
                  data.servicesIncluded.add(s);
                }
                notifier.touch();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _ratio,
          label: 'Staff-to-patient ratio',
          hint: 'e.g. 1:4',
          onChanged: (v) {
            data.staffRatio = v;
            notifier.touch();
          },
        ),
        const SizedBox(height: 16),
        const WizardSectionLabel('Room types offered'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roomTypeOptions.map((r) {
            final selected = data.roomTypes.contains(r);
            return WizardChoiceChip(
              label: r,
              selected: selected,
              onTap: () {
                if (selected) {
                  data.roomTypes.remove(r);
                } else {
                  data.roomTypes.add(r);
                }
                notifier.touch();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        WizardTextField(
          controller: _menu,
          label: 'Sample food menu',
          maxLines: 3,
          onChanged: (v) {
            data.sampleFoodMenu = v;
            notifier.touch();
          },
        ),
      ],
    );
  }
}

/// Step 8: summary before entering the admin review queue.
class CentreReviewSubmitStep extends ConsumerWidget {
  const CentreReviewSubmitStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(centreSignupViewModelProvider).data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WizardStepHeader(
          title: 'Review & submit',
          subtitle: 'Next: Pending Admin Review → Site-Visit → Verified & Live.',
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
              _SummaryRow(label: 'Centre name', value: data.centreName),
              _SummaryRow(label: 'Type', value: data.centreType ?? '—'),
              _SummaryRow(label: 'Ownership', value: data.ownershipType ?? '—'),
              _SummaryRow(label: 'Staff on payroll', value: '${data.staff.where((m) => m.isComplete).length}'),
              _SummaryRow(label: 'Site visit', value: data.siteVisitSlot ?? '—'),
              _SummaryRow(label: 'Photos', value: '${data.photoCount}'),
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
                  'You can explore the dashboard while your documents are '
                  'reviewed and the site visit is scheduled.',
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
            width: 130,
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

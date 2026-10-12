import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Colour pair for a care icon: a soft [wash] for the tile and a deep [ink]
/// for the glyph. Every icon in `assets/icons/care/` draws both its stroke and
/// its duotone fill in `currentColor`, so the fill always lands as a deeper
/// shade of the wash and the glyph melts into its tile.
class CareTone {
  final Color ink;
  final Color wash;

  const CareTone(this.ink, this.wash);

  static const nursing = CareTone(Color(0xFF26593B), Color(0xFFE7F4EB));
  static const mother = CareTone(Color(0xFFBE185D), Color(0xFFFDEEF4));
  static const elder = CareTone(Color(0xFFB45309), Color(0xFFFEF3E2));
  static const physio = CareTone(Color(0xFF1D4ED8), Color(0xFFEAF0FE));
  static const doctor = CareTone(Color(0xFF6D28D9), Color(0xFFF2EDFE));
  static const diagnostics = CareTone(Color(0xFF0E7490), Color(0xFFE4F5F9));
  static const wellness = CareTone(Color(0xFF0F766E), Color(0xFFE3F5F2));
  static const centre = CareTone(Color(0xFF0369A1), Color(0xFFE6F3FB));
  static const caregiver = CareTone(Color(0xFFC2410C), Color(0xFFFFEFE6));
  static const neutral = CareTone(Color(0xFF334155), Color(0xFFF1F5F9));

  /// Tone for a `MasterServiceItem.mainCategory`.
  static CareTone forCategory(String mainCategory) {
    final c = mainCategory.toLowerCase();
    if (c.contains('nurs')) return nursing;
    if (c.contains('mother') || c.contains('baby')) return mother;
    if (c.contains('elder')) return elder;
    if (c.contains('physio')) return physio;
    if (c.contains('doctor')) return doctor;
    if (c.contains('diag')) return diagnostics;
    if (c.contains('well')) return wellness;
    return nursing;
  }
}

/// ALLCURO care icon pack — 24×24 duotone line icons (see `assets/icons/care/`).
class CareIcons {
  CareIcons._();

  static const _dir = 'assets/icons/care';

  // Categories
  static const nursing = '$_dir/nursing.svg';
  static const motherBaby = '$_dir/mother_baby.svg';
  static const elderCare = '$_dir/elder_care.svg';
  static const physio = '$_dir/physio.svg';
  static const doctor = '$_dir/doctor.svg';
  static const careCentre = '$_dir/care_centre.svg';
  static const caregiver = '$_dir/caregiver.svg';
  static const seeAll = '$_dir/see_all.svg';
  static const wheelchair = '$_dir/wheelchair.svg';
  static const diagnostics = '$_dir/diagnostics.svg';
  static const nutrition = '$_dir/nutrition.svg';
  static const quick = '$_dir/quick.svg';

  // Services
  static const bath = '$_dir/bath.svg';
  static const spongeBath = '$_dir/sponge_bath.svg';
  static const toilet = '$_dir/toilet.svg';
  static const diaper = '$_dir/diaper.svg';
  static const grooming = '$_dir/grooming.svg';
  static const feeding = '$_dir/feeding.svg';
  static const walker = '$_dir/walker.svg';
  static const companionship = '$_dir/companionship.svg';
  static const medReminder = '$_dir/med_reminder.svg';
  static const vitals = '$_dir/vitals.svg';
  static const bpSugar = '$_dir/bp_sugar.svg';
  static const memory = '$_dir/memory.svg';
  static const bed = '$_dir/bed.svg';
  static const homeNurse = '$_dir/home_nurse.svg';
  static const injection = '$_dir/injection.svg';
  static const ivDrip = '$_dir/iv_drip.svg';
  static const bandage = '$_dir/bandage.svg';
  static const patch = '$_dir/patch.svg';
  static const urineBag = '$_dir/urine_bag.svg';
  static const catheter = '$_dir/catheter.svg';
  static const nasalTube = '$_dir/nasal_tube.svg';
  static const scissors = '$_dir/scissors.svg';
  static const nebulizer = '$_dir/nebulizer.svg';
  static const ecg = '$_dir/ecg.svg';
  static const bloodDrop = '$_dir/blood_drop.svg';
  static const lungs = '$_dir/lungs.svg';
  static const airflow = '$_dir/airflow.svg';
  static const pouch = '$_dir/pouch.svg';
  static const clipboard = '$_dir/clipboard.svg';
  static const dumbbell = '$_dir/dumbbell.svg';
  static const brain = '$_dir/brain.svg';
  static const medKit = '$_dir/med_kit.svg';
  static const mother = '$_dir/mother.svg';
  static const pregnancy = '$_dir/pregnancy.svg';
  static const heartbeat = '$_dir/heartbeat.svg';
  static const clean = '$_dir/clean.svg';
  static const baby = '$_dir/baby.svg';
  static const babyBath = '$_dir/baby_bath.svg';
  static const onesie = '$_dir/onesie.svg';
  static const bottle = '$_dir/bottle.svg';
  static const brush = '$_dir/brush.svg';

  static const _byService = <String, String>{
    'assisted-bathing': bath,
    'sponge-bath': spongeBath,
    'toileting-assistance': toilet,
    'diaper-change-hygiene': diaper,
    'hair-wash-grooming': grooming,
    'feeding-assistance': feeding,
    'mobility-assistance': wheelchair,
    'companionship-visit': companionship,
    'medication-reminder': medReminder,
    'vital-signs-check': vitals,
    'bp-blood-sugar-check': bpSugar,
    'dementia-support-visit': memory,
    'bedridden-care-visit': bed,
    'nurse-home-visit': homeNurse,
    'injection-administration': injection,
    'iv-medication-administration': ivDrip,
    'iv-infusion': ivDrip,
    'wound-dressing': bandage,
    'pressure-injury-dressing': patch,
    'catheter-care': urineBag,
    'foley-catheter-insertion': catheter,
    'ryle-s-tube-care': nasalTube,
    'ryle-s-tube-insertion': nasalTube,
    'suture-staple-removal': scissors,
    'nebulization': nebulizer,
    'ecg-at-home': ecg,
    'blood-sample-collection': bloodDrop,
    'tracheostomy-care': lungs,
    'suctioning': airflow,
    'colostomy-care': pouch,
    'physiotherapy-assessment': clipboard,
    'general-physiotherapy': dumbbell,
    'elder-mobility-therapy': walker,
    'stroke-rehabilitation': brain,
    'doctor-home-consultation': doctor,
    'geriatric-home-consultation': medKit,
    'dietitian-consultation': nutrition,
    'lactation-consultation': mother,
    'antenatal-home-visit': pregnancy,
    'pregnancy-bp-monitoring': vitals,
    'fetal-heart-rate-check': heartbeat,
    'postnatal-mother-care': caregiver,
    'c-section-recovery-visit': bandage,
    'breastfeeding-support': mother,
    'postnatal-hygiene-support': clean,
    'newborn-home-assessment': baby,
    'baby-bath': babyBath,
    'newborn-hygiene-care': diaper,
    'umbilical-cord-care-education': onesie,
    'baby-feeding-support': bottle,
    'baby-grooming': brush,
    'mother-baby-2-hour-support': motherBaby,
  };

  /// Icon for a `MasterServiceItem.id`; falls back to the nursing glyph.
  static String forService(String serviceId) => _byService[serviceId] ?? nursing;
}

/// A single care glyph tinted with [color].
class CareIcon extends StatelessWidget {
  final String asset;
  final Color color;
  final double size;

  const CareIcon(this.asset, {super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: color),
    );
  }
}

/// Soft-washed rounded tile holding a care glyph — used by every service grid.
class CareIconTile extends StatelessWidget {
  final String asset;
  final CareTone tone;
  final double width;
  final double height;
  final double iconSize;
  final double radius;

  const CareIconTile({
    super.key,
    required this.asset,
    required this.tone,
    this.width = 64,
    this.height = 60,
    this.iconSize = 30,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tone.wash,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: CareIcon(asset, color: tone.ink, size: iconSize),
    );
  }
}

/// Realistic category photography and illustrations (see `assets/images/categories/`).
class CareIllustrations {
  CareIllustrations._();

  static const _dir = 'assets/images/categories';

  static const nursing = '$_dir/nursing.jpg';
  static const motherBaby = '$_dir/mother_baby.jpg';
  static const elderCare = '$_dir/elder_care.jpg';
  static const physio = '$_dir/physio.jpg';
  static const doctor = '$_dir/doctor.jpg';
  static const careCentre = '$_dir/care_centre.jpg';
  static const caregiver = '$_dir/caregiver.jpg';
  static const diagnostics = '$_dir/diagnostics.jpg';
  static const wellness = '$_dir/wellness.jpg';
  static const equipment = '$_dir/equipment.jpg';
  static const seeAll = '$_dir/see_all.jpg';
}

/// Neutral tile holding a realistic category image or illustration — used by the home category grid.
class CareIllustrationTile extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final double artSize;
  final double radius;

  const CareIllustrationTile({
    super.key,
    required this.asset,
    this.width = 64,
    this.height = 60,
    this.artSize = 52,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isSvg = asset.endsWith('.svg');
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: isSvg
            ? Center(child: SvgPicture.asset(asset, width: artSize, height: artSize))
            : Image.asset(
                asset,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.medical_services_outlined, color: AppColors.primary),
                ),
              ),
      ),
    );
  }
}

import '../../partners/data/partners_source.dart';
import 'models/nurse.dart';
import 'models/shift_option.dart';

/// Maps approved individual partners (nurses, doctors, physiotherapists,
/// caregivers) from `partners_public` + `partner_offerings_public` into
/// [Nurse]s. Empty when there are no approved partners or no Supabase.
class NursesService {
  final Future<PartnerRows> Function() _load;

  NursesService(this._load);

  Future<List<Nurse>> fetchAll() async {
    final rows = await _load();
    return [
      for (final p in rows.partners)
        if (rowText(p, 'kind') != 'centre') nurseFromRow(p, rows.offeringsByPartner[rowText(p, 'id')] ?? const []),
    ];
  }
}

Nurse nurseFromRow(Map<String, dynamic> p, List<Map<String, dynamic>> offers) {
  final available = p['is_available'] as bool? ?? true;
  final skills = rowList(p, 'skills');
  final place = [rowText(p, 'locality'), rowText(p, 'city')].where((s) => s.isNotEmpty).join(', ');
  final headline = rowText(p, 'headline');
  return Nurse(
    id: rowText(p, 'slug').isNotEmpty ? rowText(p, 'slug') : rowText(p, 'id'),
    partnerId: rowText(p, 'id'),
    kind: rowText(p, 'kind').isEmpty ? 'nurse' : rowText(p, 'kind'),
    name: rowText(p, 'display_name'),
    photo: rowText(p, 'photo_url'),
    allcuroId: rowText(p, 'allcuro_code'),
    level: headline.isNotEmpty ? headline : rowText(p, 'qualification'),
    experience: rowInt(p, 'experience_years'),
    city: place,
    languages: rowList(p, 'languages'),
    tags: [...skills, ...rowList(p, 'specialisations').where((s) => !skills.contains(s))],
    rating: rowDouble(p, 'rating'),
    reviews: rowInt(p, 'review_count'),
    highlights: rowList(p, 'highlights'),
    bio: rowText(p, 'bio'),
    available: available,
    shifts: [
      for (final o in offers)
        ShiftOption(
          label: rowText(o, 'label'),
          unit: rowText(o, 'unit'),
          serviceId: o['service_id'] as String?,
          mrp: rowInt(o, 'price'),
          price: rowInt(o, 'final_price'),
          available: available,
        ),
    ],
    employment: switch (rowText(p, 'employment_type').toLowerCase()) {
      'part-time' => Employment.partTime,
      'live-in' => Employment.liveIn,
      _ => Employment.fullTime,
    },
  );
}

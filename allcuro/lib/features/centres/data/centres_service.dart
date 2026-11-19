import '../../partners/data/partners_source.dart';
import 'models/centre.dart';

/// Maps approved care-centre partners (`partners_public`, kind = 'centre')
/// into [Centre]s. Empty when there are none or no Supabase.
class CentresService {
  final Future<PartnerRows> Function() _load;

  CentresService(this._load);

  Future<List<Centre>> fetchAll() async {
    final rows = await _load();
    return [
      for (final p in rows.partners)
        if (rowText(p, 'kind') == 'centre') centreFromRow(p),
    ];
  }
}

Centre centreFromRow(Map<String, dynamic> p) {
  final photos = rowList(p, 'photos');
  final discount = p['discount_percent'] as num?;
  final day = p['price_per_day'] as num?;
  final month = p['price_per_month'] as num?;
  final type = rowText(p, 'centre_type');
  return Centre(
    id: rowText(p, 'slug').isNotEmpty ? rowText(p, 'slug') : rowText(p, 'id'),
    partnerId: rowText(p, 'id'),
    name: rowText(p, 'display_name'),
    type: type.isNotEmpty ? type : rowText(p, 'headline'),
    locality: rowText(p, 'locality'),
    city: rowText(p, 'city'),
    photo: photos.isNotEmpty ? photos.first : rowText(p, 'photo_url'),
    photos: photos,
    photoCount: photos.length,
    rating: rowDouble(p, 'rating'),
    reviews: rowInt(p, 'review_count'),
    since: rowInt(p, 'year_established'),
    licence: rowText(p, 'licence_no'),
    staffRatio: rowText(p, 'staff_ratio'),
    pricePerDay: day == null ? 0 : discounted(day, discount),
    pricePerMonth: month == null ? 0 : discounted(month, discount),
    bedsLeft: rowInt(p, 'beds_available'),
    services: rowList(p, 'services_included'),
    roomTypes: rowList(p, 'room_types'),
    about: rowText(p, 'bio'),
    phone: rowText(p, 'public_phone'),
    scores: const [],
  );
}

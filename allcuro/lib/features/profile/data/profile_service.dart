import 'models/profile.dart';
import 'models/profile_menu_row.dart';

/// Local data source for the signed-in member's profile. Stands in for a
/// future call through [ApiClient] — the repository above it doesn't care
/// whether this comes from here or from the network.
class ProfileService {
  const ProfileService();

  Future<Profile> fetchCurrent() async => _profile;
}

const _profile = Profile(
  name: '',
  initials: '',
  phone: '',
  email: '',
  verified: false,
  menuRows: [
    ProfileMenuRow(iconKey: 'location', label: 'Saved addresses', hint: 'Home, family and work'),
    ProfileMenuRow(iconKey: 'badge', label: 'ID verification', hint: 'Unlocks live-in bookings'),
    ProfileMenuRow(iconKey: 'wallet', label: 'ALLCURO credits', hint: 'Offers and refunds'),
    ProfileMenuRow(iconKey: 'gift', label: 'Refer a family', hint: 'Share ALLCURO'),
    ProfileMenuRow(iconKey: 'support', label: 'Help & SOS', hint: '24/7'),
    ProfileMenuRow(iconKey: 'faq', label: 'FAQs', hint: 'Common questions about home care'),
  ],
);

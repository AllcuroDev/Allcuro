import 'models/placement_request_summary.dart';
import 'models/room.dart';

/// Centre-side data source. There is no placement-requests / admissions
/// backend yet, so everything starts (and stays) empty — screens show
/// honest empty states. Rooms & beds the centre enters live in
/// `partnerOnboardingProvider`. Swap this class for Supabase calls once
/// there's a backend — `CentreRepository`'s surface can stay the same.
class CentreService {
  final List<PlacementRequestSummary> _requests = [];
  final List<Room> _rooms = [];
  int _admittedThisMonth = 0;

  Future<List<PlacementRequestSummary>> fetchPendingRequests() async => List.unmodifiable(_requests);

  Future<List<Room>> fetchRooms() async => List.unmodifiable(_rooms);

  Future<int> fetchAdmittedThisMonth() async => _admittedThisMonth;

  Future<void> acceptRequest(String id) async {
    final before = _requests.length;
    _requests.removeWhere((r) => r.id == id);
    if (_requests.length < before) _admittedThisMonth++;
  }

  Future<void> declineRequest(String id) async {
    _requests.removeWhere((r) => r.id == id);
  }
}

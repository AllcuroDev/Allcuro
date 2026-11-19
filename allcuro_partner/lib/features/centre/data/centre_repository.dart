import 'centre_service.dart';
import 'models/placement_request_summary.dart';
import 'models/room.dart';

/// Thin domain layer over [CentreService] — view models talk to this,
/// never to the data source directly. This is the seam a real API
/// client slots into later.
class CentreRepository {
  final CentreService _service;

  CentreRepository(this._service);

  Future<List<PlacementRequestSummary>> pendingRequests() =>
      _service.fetchPendingRequests();

  Future<List<Room>> rooms() => _service.fetchRooms();

  Future<int> admittedThisMonth() => _service.fetchAdmittedThisMonth();

  Future<void> acceptRequest(String id) => _service.acceptRequest(id);

  Future<void> declineRequest(String id) => _service.declineRequest(id);
}

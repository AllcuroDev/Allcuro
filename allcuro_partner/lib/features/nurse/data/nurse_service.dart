import 'models/job_request_detail.dart';
import 'models/job_request_summary.dart';
import 'models/nurse_performance_model.dart';
import 'models/nurse_visit_model.dart';
import 'models/shift.dart';

/// Nurse-side data source. There is no bookings / visit-requests / earnings
/// / reviews backend yet, so every list starts (and stays) empty and there
/// is no active visit — screens show honest empty states. The in-memory
/// state and mutators are kept so the screens' flows keep working once a
/// real API feeds them; swap this class for Supabase calls then —
/// `NurseRepository`'s surface can stay the same.
class NurseService {
  bool _isOnDuty = false;
  String _currentShiftTiming = 'Not set';

  bool get isOnDuty => _isOnDuty;
  String get currentShiftTiming => _currentShiftTiming;

  final List<JobRequestSummary> _requests = [];
  final Map<String, JobRequestDetail> _requestDetails = {};
  final List<Shift> _shifts = [];
  NurseVisit? _activeVisit;
  NursePerformance _performance = NursePerformance.empty;

  Future<bool> setDutyStatus(bool onDuty, String timing) async {
    _isOnDuty = onDuty;
    _currentShiftTiming = timing;
    return _isOnDuty;
  }

  Future<List<JobRequestSummary>> fetchPendingRequests() async => List.unmodifiable(_requests);

  Future<JobRequestDetail> fetchRequestDetail(String id) async {
    final detail = _requestDetails[id];
    if (detail == null) {
      throw StateError('This request is no longer available.');
    }
    return detail;
  }

  Future<List<Shift>> fetchShifts() async => List.unmodifiable(_shifts);

  /// The visit the nurse is currently on, or null when there is none.
  Future<NurseVisit?> fetchActiveVisit() async => _activeVisit;

  Future<NursePerformance> fetchPerformance() async => _performance;

  NurseVisit _requireVisit() {
    final visit = _activeVisit;
    if (visit == null) throw StateError('No active visit');
    return visit;
  }

  Future<NurseVisit> updateVisitStatus(VisitStatus newStatus) async {
    return _activeVisit = _requireVisit().copyWith(status: newStatus);
  }

  Future<NurseVisit> verifyArrivalGpsAndSelfie() async {
    return _activeVisit = _requireVisit().copyWith(
      isGpsVerified: true,
      isSelfieVerified: true,
      status: VisitStatus.reached,
    );
  }

  Future<NurseVisit> checkInVisit() async {
    return _activeVisit = _requireVisit().copyWith(
      status: VisitStatus.inProgress,
      checkInTime: DateTime.now(),
    );
  }

  Future<NurseVisit> logVitals(VitalSignsLog vitals) async {
    final visit = _requireVisit();
    return _activeVisit = visit.copyWith(
      vitalsLog: vitals,
      checklist: visit.checklist.copyWith(vitalsLogged: true),
    );
  }

  Future<NurseVisit> updateChecklist(ClinicalChecklist checklist) async {
    return _activeVisit = _requireVisit().copyWith(checklist: checklist);
  }

  /// Completes the active visit when [enteredOtp] matches the family's OTP.
  Future<bool> completeVisitWithOtp(String enteredOtp) async {
    final visit = _activeVisit;
    if (visit == null || enteredOtp.trim() != visit.expectedOtp) return false;
    _activeVisit = visit.copyWith(
      status: VisitStatus.completed,
      checkOutTime: DateTime.now(),
    );
    _performance = NursePerformance(
      totalJobsCompleted: _performance.totalJobsCompleted + 1,
      monthlyJobsCompleted: _performance.monthlyJobsCompleted + 1,
      weeklyJobsCompleted: _performance.weeklyJobsCompleted + 1,
      attendanceRate: _performance.attendanceRate,
      onTimeArrivalRate: _performance.onTimeArrivalRate,
      averageRating: _performance.averageRating,
      totalRatingsCount: _performance.totalRatingsCount,
      ratingDistribution: _performance.ratingDistribution,
      totalComplaints: _performance.totalComplaints,
      resolvedComplaints: _performance.resolvedComplaints,
      thisMonthEarnings: _performance.thisMonthEarnings,
      thisWeekEarnings: _performance.thisWeekEarnings,
      pendingPayout: _performance.pendingPayout,
      feedbacks: _performance.feedbacks,
    );
    return true;
  }

  Future<void> acceptRequest(String id) async {
    _requests.removeWhere((r) => r.id == id);
  }

  Future<void> declineRequest(String id) async {
    _requests.removeWhere((r) => r.id == id);
  }
}

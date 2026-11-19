import 'models/job_request_detail.dart';
import 'models/job_request_summary.dart';
import 'models/nurse_performance_model.dart';
import 'models/nurse_visit_model.dart';
import 'models/shift.dart';
import 'nurse_service.dart';

class NurseRepository {
  final NurseService _service;

  NurseRepository(this._service);

  bool get isOnDuty => _service.isOnDuty;
  String get currentShiftTiming => _service.currentShiftTiming;

  Future<bool> setDutyStatus(bool onDuty, String timing) =>
      _service.setDutyStatus(onDuty, timing);

  Future<List<JobRequestSummary>> getPendingRequests() =>
      _service.fetchPendingRequests();
  Future<List<JobRequestSummary>> pendingRequests() =>
      _service.fetchPendingRequests();

  Future<JobRequestDetail> getRequestDetail(String id) =>
      _service.fetchRequestDetail(id);
  Future<JobRequestDetail> requestDetail(String id) =>
      _service.fetchRequestDetail(id);

  Future<List<Shift>> getShifts() => _service.fetchShifts();
  Future<List<Shift>> shifts() => _service.fetchShifts();

  Future<NurseVisit?> getActiveVisit() => _service.fetchActiveVisit();

  Future<NursePerformance> getPerformance() => _service.fetchPerformance();

  Future<NurseVisit> updateVisitStatus(VisitStatus newStatus) =>
      _service.updateVisitStatus(newStatus);

  Future<NurseVisit> verifyArrivalGpsAndSelfie() =>
      _service.verifyArrivalGpsAndSelfie();

  Future<NurseVisit> checkInVisit() => _service.checkInVisit();

  Future<NurseVisit> logVitals(VitalSignsLog vitals) =>
      _service.logVitals(vitals);

  Future<NurseVisit> updateChecklist(ClinicalChecklist checklist) =>
      _service.updateChecklist(checklist);

  Future<bool> completeVisitWithOtp(String enteredOtp) =>
      _service.completeVisitWithOtp(enteredOtp);

  Future<void> acceptRequest(String id) => _service.acceptRequest(id);

  Future<void> declineRequest(String id) => _service.declineRequest(id);
}

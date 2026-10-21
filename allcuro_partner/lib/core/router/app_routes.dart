/// Central catalogue of route paths, so `app_router.dart` and the route
/// builders inside it never duplicate a path string by hand.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const phoneAuth = '/phone-auth';
  static const roleSelect = '/role-select';
  static const profile = '/profile';

  static const nurseSignup = '/nurse/signup';
  static const nurseHome = '/nurse/home';
  static const nurseRequests = '/nurse/requests';
  static const nurseSchedule = '/nurse/schedule';
  static const nurseRequestDetailPattern = '/nurse/requests/:id';
  static String nurseRequestDetail(String id) => '/nurse/requests/$id';
  static const nurseAvailability = '/nurse/availability';
  static const nurseEarnings = '/nurse/earnings';
  static const nurseTraining = '/nurse/training';
  static const nurseRatings = '/nurse/ratings';
  static const nurseVisitExecution = '/nurse/visit-execution';
  static const nurseDocuments = '/nurse/documents';
  static const nurseReferral = '/nurse/referral';
  static const nurseSupport = '/nurse/support';

  static const clinicianSignup = '/clinician/signup';

  static const centreSignup = '/centre/signup';
  static const centreHome = '/centre/home';
  static const centreRequests = '/centre/requests';
  static const centreRooms = '/centre/rooms';
  static const centreListing = '/centre/listing';
  static const centreRevenue = '/centre/revenue';
  static const centreReviews = '/centre/reviews';
  static const centreCompliance = '/centre/compliance';
  static const bankAccount = '/bank-account';
  static const centreEquipment = '/centre/equipment';
  static const centreStaff = '/centre/staff';
  static const centrePromotions = '/centre/promotions';
}

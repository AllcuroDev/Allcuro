// Route paths for the partner portal — the partner app's AppRoutes
// (allcuro_partner/lib/core/router/app_routes.dart) under a /partner prefix.

const P = '/partner'

export const PR = {
  root: P,
  welcome: `${P}/welcome`,
  phoneAuth: `${P}/phone-auth`,
  roleSelect: `${P}/role-select`,
  identityVerification: `${P}/verify-identity`,
  profile: `${P}/profile`,
  publicProfile: `${P}/public-profile`,
  bankAccount: `${P}/bank-account`,

  nurseSignup: `${P}/nurse/signup`,
  nurseHome: `${P}/nurse/home`,
  nurseRequests: `${P}/nurse/requests`,
  nurseRequestDetail: (id: string) => `${P}/nurse/requests/${id}`,
  nurseSchedule: `${P}/nurse/schedule`,
  nurseAvailability: `${P}/nurse/availability`,
  nurseEarnings: `${P}/nurse/earnings`,
  nurseTraining: `${P}/nurse/training`,
  nurseRatings: `${P}/nurse/ratings`,
  nurseVisitExecution: `${P}/nurse/visit-execution`,
  nurseDocuments: `${P}/nurse/documents`,
  nurseReferral: `${P}/nurse/referral`,
  nurseSupport: `${P}/nurse/support`,

  clinicianSignup: `${P}/clinician/signup`,

  centreSignup: `${P}/centre/signup`,
  centreHome: `${P}/centre/home`,
  centreRequests: `${P}/centre/requests`,
  centreRooms: `${P}/centre/rooms`,
  centreListing: `${P}/centre/listing`,
  centreRevenue: `${P}/centre/revenue`,
  centreReviews: `${P}/centre/reviews`,
  centreCompliance: `${P}/centre/compliance`,
  centreEquipment: `${P}/centre/equipment`,
  centreStaff: `${P}/centre/staff`,
  centrePromotions: `${P}/centre/promotions`,
} as const

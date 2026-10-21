/// Where a nurse's (or doctor's / physiotherapist's) onboarding &
/// activation has gotten to.
enum NurseVerificationStatus {
  incomplete, // Has not finished 3-step basic signup
  onboarding, // Basic signup done; completing Document Vault, Bank & Skills on Home setup hub
  underReview, // Submitted for state nursing council & automated background check
  verified, // Admin approved & live for shift bookings
}

/// Mirrors ALLCURO's stated progression for homecare centres:
/// Basic Setup -> Pending Admin Review & Site-Visit Scheduled -> Verified & Live.
enum CentreVerificationStatus {
  incomplete, // Has not finished 3-step basic signup
  onboarding, // Basic signup done; completing Compliance, Bank, Beds, Care Staff & Equipment
  pendingReview, // Submitted for review
  siteVisitScheduled, // Physical field audit scheduled by city operations
  verified, // Verified & Live for admissions & bookings
}

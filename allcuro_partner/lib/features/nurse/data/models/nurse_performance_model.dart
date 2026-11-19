import 'package:flutter/foundation.dart';

@immutable
class CustomerFeedbackItem {
  final String id;
  final String bookingId;
  final String patientName;
  final String serviceName;
  final double rating;
  final String comment;
  final DateTime date;

  const CustomerFeedbackItem({
    required this.id,
    required this.bookingId,
    required this.patientName,
    required this.serviceName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

@immutable
class NursePerformance {
  final int totalJobsCompleted;
  final int monthlyJobsCompleted;
  final int weeklyJobsCompleted;
  final double attendanceRate; // e.g. 98.5
  final double onTimeArrivalRate; // e.g. 96.2
  final double averageRating; // e.g. 4.92
  final int totalRatingsCount;
  final Map<int, int> ratingDistribution; // {5: 76, 4: 7, 3: 1, 2: 0, 1: 0}
  final int totalComplaints;
  final int resolvedComplaints;
  final double thisMonthEarnings;
  final double thisWeekEarnings;
  final double pendingPayout;
  final List<CustomerFeedbackItem> feedbacks;

  const NursePerformance({
    required this.totalJobsCompleted,
    required this.monthlyJobsCompleted,
    required this.weeklyJobsCompleted,
    required this.attendanceRate,
    required this.onTimeArrivalRate,
    required this.averageRating,
    required this.totalRatingsCount,
    required this.ratingDistribution,
    required this.totalComplaints,
    required this.resolvedComplaints,
    required this.thisMonthEarnings,
    required this.thisWeekEarnings,
    required this.pendingPayout,
    required this.feedbacks,
  });

  /// A partner with no completed visits and no reviews — what every partner
  /// sees until there's a bookings / reviews backend.
  static const empty = NursePerformance(
    totalJobsCompleted: 0,
    monthlyJobsCompleted: 0,
    weeklyJobsCompleted: 0,
    attendanceRate: 0,
    onTimeArrivalRate: 0,
    averageRating: 0,
    totalRatingsCount: 0,
    ratingDistribution: {},
    totalComplaints: 0,
    resolvedComplaints: 0,
    thisMonthEarnings: 0,
    thisWeekEarnings: 0,
    pendingPayout: 0,
    feedbacks: [],
  );

  /// Whether there's anything real to show (completed visits or reviews).
  bool get hasActivity => totalJobsCompleted > 0 || totalRatingsCount > 0;

  bool get hasRatings => totalRatingsCount > 0;
}

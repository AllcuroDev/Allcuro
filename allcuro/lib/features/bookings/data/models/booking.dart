import 'package:flutter/foundation.dart';

enum BookingType {
  nurse,
  careCentre,
  equipment,
  medicine,
}

enum BookingLiveStatus {
  assigned,
  enRoute,
  reached,
  inProgress,
  completed,
}

@immutable
class Booking {
  final String id;
  final BookingType type;
  final String title;
  final String when;
  final String status;
  final int amount;
  final String otp;
  final BookingLiveStatus liveStatus;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String address;
  final String locality;
  final String providerName;
  final String providerPhone;
  final double providerRating;
  final String providerQualifications;
  final String? vitalsSummary;
  final String? condition;
  final String? roomType;
  final List<String> formalities;

  /// Medicine orders: one line per item, e.g. 'Metformin 500 mg SR Tablet × 2 · ₹82'.
  final List<String> items;

  /// Medicine orders: the prescription file sent to the pharmacist, if any.
  final String? prescriptionName;

  const Booking({
    required this.id,
    this.type = BookingType.nurse,
    required this.title,
    required this.when,
    required this.status,
    required this.amount,
    this.otp = '4829',
    this.liveStatus = BookingLiveStatus.inProgress,
    this.patientName = 'Ramesh Iyer',
    this.patientAge = 68,
    this.patientGender = 'Male',
    this.address = 'Flat 402, Green Glen Palms, 12th Main, Indiranagar, Bengaluru',
    this.locality = 'Indiranagar, Bengaluru',
    this.providerName = 'Priya Sharma',
    this.providerPhone = '+91 98450 12345',
    this.providerRating = 4.92,
    this.providerQualifications = 'GNM · 4 yrs exp · HPR Verified',
    this.vitalsSummary = 'BP: 120/80 mmHg · Sugar: 112 mg/dL · Pulse: 74 bpm · Temp: 98.4 °F',
    this.condition = 'Post-Op Knee Replacement Care & IV Infusion',
    this.roomType,
    this.formalities = const [
      'Govt Photo ID (Aadhaar / Passport) of patient',
      'Hospital Discharge Summary & Doctor Prescription',
      'Digital Admission Pass & Check-In OTP',
      'Emergency Contact Verification',
    ],
    this.items = const [],
    this.prescriptionName,
  });

  Booking copyWith({
    String? id,
    BookingType? type,
    String? title,
    String? when,
    String? status,
    int? amount,
    String? otp,
    BookingLiveStatus? liveStatus,
    String? patientName,
    int? patientAge,
    String? patientGender,
    String? address,
    String? locality,
    String? providerName,
    String? providerPhone,
    double? providerRating,
    String? providerQualifications,
    String? vitalsSummary,
    String? condition,
    String? roomType,
    List<String>? formalities,
    List<String>? items,
    String? prescriptionName,
  }) {
    return Booking(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      when: when ?? this.when,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      otp: otp ?? this.otp,
      liveStatus: liveStatus ?? this.liveStatus,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientGender: patientGender ?? this.patientGender,
      address: address ?? this.address,
      locality: locality ?? this.locality,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      providerRating: providerRating ?? this.providerRating,
      providerQualifications: providerQualifications ?? this.providerQualifications,
      vitalsSummary: vitalsSummary ?? this.vitalsSummary,
      condition: condition ?? this.condition,
      roomType: roomType ?? this.roomType,
      formalities: formalities ?? this.formalities,
      items: items ?? this.items,
      prescriptionName: prescriptionName ?? this.prescriptionName,
    );
  }
}

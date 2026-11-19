import 'dart:math';

import 'models/booking.dart';

/// Bookings made on this device in this session. There is no bookings table
/// yet, so every user starts with an empty list — nothing is seeded.
class BookingsService {
  final List<Booking> _bookings;

  /// [initial] is for tests only; the app always starts empty.
  BookingsService([List<Booking> initial = const []]) : _bookings = [...initial];

  Future<List<Booking>> fetchAll() async => List.unmodifiable(_bookings);

  Future<Booking?> fetchById(String id) async {
    for (final b in _bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<Booking> addBooking(Booking newBooking) async {
    _bookings.insert(0, newBooking);
    return newBooking;
  }
}

final _rng = Random();

/// A fresh booking reference such as 'ALC-NUR-48213'.
String newBookingId(String prefix) => 'ALC-$prefix-${10000 + _rng.nextInt(90000)}';

/// A 4-digit visit / handover code.
String newVisitOtp() => (1000 + _rng.nextInt(9000)).toString();

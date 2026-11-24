import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/user_address.dart';

class LocationState {
  final UserAddress currentAddress;
  final List<UserAddress> savedAddresses;
  final bool isGpsDetecting;

  const LocationState({
    required this.currentAddress,
    required this.savedAddresses,
    this.isGpsDetecting = false,
  });

  LocationState copyWith({
    UserAddress? currentAddress,
    List<UserAddress>? savedAddresses,
    bool? isGpsDetecting,
  }) {
    return LocationState(
      currentAddress: currentAddress ?? this.currentAddress,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      isGpsDetecting: isGpsDetecting ?? this.isGpsDetecting,
    );
  }
}

/// Shown until the member adds an address or uses their location.
const _unsetAddress = UserAddress(
  id: 'unset',
  title: 'Set your location',
  addressLine: 'Add your address',
  locality: '',
  arrivalTime: '',
  tag: AddressTag.other,
);

class LocationViewModel extends StateNotifier<LocationState> {
  LocationViewModel()
    : super(
        LocationState(currentAddress: _unsetAddress, savedAddresses: const []),
      );

  void selectAddress(UserAddress address) {
    state = state.copyWith(currentAddress: address);
  }

  /// Detects the phone's location as soon as the app opens, unless the member
  /// already picked an address. Fails quietly: they can still set it by hand.
  Future<void> autoDetect() async {
    if (state.currentAddress.id != _unsetAddress.id) return;
    try {
      await useCurrentGpsLocation(requestPermission: true);
    } catch (_) {}
  }

  /// Reads the real GPS position and turns it into a locality name.
  /// Throws a readable message when location is off or denied.
  Future<void> useCurrentGpsLocation({bool requestPermission = true}) async {
    state = state.copyWith(isGpsDetecting: true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Location is turned off. Turn it on, or add the address instead.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission denied. Allow it, or add the address instead.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      var addressLine = 'Current location';
      var locality =
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      // Reverse geocoding is not available on Flutter web; keep coordinates there.
      if (!kIsWeb) {
        try {
          final marks = await Geocoding().placemarkFromCoordinates(
            pos.latitude,
            pos.longitude,
          );
          if (marks.isNotEmpty) {
            final p = marks.first;
            bool filled(String? e) => e != null && e.trim().isNotEmpty;
            final area = <String?>[
              p.subLocality,
              p.locality,
            ].where(filled).join(', ');
            final street = <String?>[
              p.street,
              p.thoroughfare,
              p.name,
            ].firstWhere(filled, orElse: () => null);
            if (area.isNotEmpty) locality = area;
            if (street != null) addressLine = street;
          }
        } catch (_) {}
      }

      final gpsAddress = UserAddress(
        id: 'gps',
        title: 'Current Location',
        addressLine: addressLine,
        locality: locality,
        arrivalTime: '',
        tag: AddressTag.other,
      );
      state = state.copyWith(
        currentAddress: gpsAddress,
        savedAddresses: [
          gpsAddress,
          ...state.savedAddresses.where((a) => a.id != gpsAddress.id),
        ],
        isGpsDetecting: false,
      );
    } catch (e) {
      state = state.copyWith(isGpsDetecting: false);
      rethrow;
    }
  }

  void addNewAddress({
    required String houseNo,
    required String landmark,
    required String locality,
    required AddressTag tag,
  }) {
    final title = tag == AddressTag.home
        ? 'Home'
        : tag == AddressTag.work
        ? 'Work'
        : tag == AddressTag.parents
        ? "Parents' Home"
        : 'Other';

    final cleanLocality = locality.trim();
    final cleanAddressLine = landmark.trim().isEmpty
        ? houseNo.trim()
        : '${houseNo.trim()}, ${landmark.trim()}';

    final newAddr = UserAddress(
      id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      addressLine: cleanAddressLine,
      locality: cleanLocality,
      arrivalTime: '',
      tag: tag,
    );

    state = state.copyWith(
      currentAddress: newAddr,
      savedAddresses: [newAddr, ...state.savedAddresses],
    );
  }
}

final locationViewModelProvider =
    StateNotifierProvider<LocationViewModel, LocationState>((ref) {
      final vm = LocationViewModel();
      // Auto-detect location as soon as the app opens.
      vm.autoDetect();
      return vm;
    });

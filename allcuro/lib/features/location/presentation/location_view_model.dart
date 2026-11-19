import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        LocationState(
          currentAddress: _unsetAddress,
          savedAddresses: const [],
        ),
      );

  void selectAddress(UserAddress address) {
    state = state.copyWith(currentAddress: address);
  }

  Future<void> useCurrentGpsLocation() async {
    state = state.copyWith(isGpsDetecting: true);
    await Future.delayed(const Duration(milliseconds: 700));
    final gpsAddress = UserAddress(
      id: 'gps-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Current Location',
      addressLine: '12th Main Road, HAL 2nd Stage',
      locality: 'Indiranagar, Bengaluru',
      arrivalTime: '44 mins',
      tag: AddressTag.other,
    );

    // Keep unique
    final updatedList = [
      gpsAddress,
      ...state.savedAddresses.where((a) => a.id != gpsAddress.id),
    ];

    state = state.copyWith(
      currentAddress: gpsAddress,
      savedAddresses: updatedList,
      isGpsDetecting: false,
    );
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
      return LocationViewModel();
    });

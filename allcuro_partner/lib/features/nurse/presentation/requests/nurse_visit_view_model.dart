import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/nurse_visit_model.dart';
import '../../data/nurse_repository.dart';
import '../home/nurse_home_view_model.dart';
import '../nurse_providers.dart';

final nurseVisitViewModelProvider =
    AsyncNotifierProvider<NurseVisitViewModel, NurseVisit?>(
      NurseVisitViewModel.new,
    );

/// The nurse's active visit — null when there is none (the execution
/// screen then shows a "No active visit" empty state).
class NurseVisitViewModel extends AsyncNotifier<NurseVisit?> {
  NurseRepository get _repository => ref.read(nurseRepositoryProvider);

  @override
  Future<NurseVisit?> build() async {
    return _repository.getActiveVisit();
  }

  Future<void> startTravel() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.updateVisitStatus(VisitStatus.enRoute);
    });
    ref.invalidate(nurseHomeViewModelProvider);
  }

  Future<void> verifyArrivalAndSelfie() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.verifyArrivalGpsAndSelfie();
    });
    ref.invalidate(nurseHomeViewModelProvider);
  }

  Future<void> checkIn() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.checkInVisit();
    });
    ref.invalidate(nurseHomeViewModelProvider);
  }

  Future<void> logVitals(VitalSignsLog vitals) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.logVitals(vitals);
    });
  }

  Future<void> updateChecklist(ClinicalChecklist checklist) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return _repository.updateChecklist(checklist);
    });
  }

  Future<bool> verifyAndCompleteWithOtp(String enteredOtp) async {
    final current = state.valueOrNull;
    if (current == null) return false;
    final success = await _repository.completeVisitWithOtp(enteredOtp);
    if (success) {
      state = AsyncValue.data(
        current.copyWith(
          status: VisitStatus.completed,
          checkOutTime: DateTime.now(),
        ),
      );
      ref.invalidate(nurseHomeViewModelProvider);
    }
    return success;
  }
}

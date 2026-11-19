import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/nurse_repository.dart';
import '../data/nurse_service.dart';

/// Kept alive for the app session (not `.autoDispose`) since [NurseService]
/// holds the mutable request / visit state — recreating it on every rebuild
/// would make accept/decline forget what happened.
final nurseServiceProvider = Provider<NurseService>((ref) => NurseService());

final nurseRepositoryProvider = Provider<NurseRepository>((ref) {
  return NurseRepository(ref.watch(nurseServiceProvider));
});

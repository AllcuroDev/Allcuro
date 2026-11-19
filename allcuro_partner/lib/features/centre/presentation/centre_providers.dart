import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/centre_repository.dart';
import '../data/centre_service.dart';

/// Kept alive for the app session (not `.autoDispose`) since [CentreService]
/// holds the mutable request/room state — recreating it on every
/// rebuild would make accept/decline forget what happened.
final centreServiceProvider = Provider<CentreService>((ref) => CentreService());

final centreRepositoryProvider = Provider<CentreRepository>((ref) {
  return CentreRepository(ref.watch(centreServiceProvider));
});

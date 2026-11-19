import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../partners/data/partners_source.dart';
import 'models/nurse.dart';
import 'nurses_service.dart';

class NursesRepository {
  final NursesService _service;

  const NursesRepository(this._service);

  Future<List<Nurse>> getAll() => _service.fetchAll();

  Future<Nurse?> getById(String id) async {
    final nurses = await _service.fetchAll();
    for (final nurse in nurses) {
      if (nurse.id == id || nurse.partnerId == id) return nurse;
    }
    return null;
  }
}

final nursesServiceProvider = Provider<NursesService>(
  (ref) => NursesService(() => ref.read(partnerRowsProvider.future)),
);

final nursesRepositoryProvider = Provider<NursesRepository>(
  (ref) => NursesRepository(ref.watch(nursesServiceProvider)),
);

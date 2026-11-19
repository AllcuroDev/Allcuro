import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../partners/data/partners_source.dart';
import 'centres_service.dart';
import 'models/centre.dart';

class CentresRepository {
  final CentresService _service;

  const CentresRepository(this._service);

  Future<List<Centre>> getAll() => _service.fetchAll();

  Future<Centre?> getById(String id) async {
    final centres = await _service.fetchAll();
    for (final centre in centres) {
      if (centre.id == id || centre.partnerId == id) return centre;
    }
    return null;
  }
}

final centresServiceProvider = Provider<CentresService>(
  (ref) => CentresService(() => ref.read(partnerRowsProvider.future)),
);

final centresRepositoryProvider = Provider<CentresRepository>(
  (ref) => CentresRepository(ref.watch(centresServiceProvider)),
);

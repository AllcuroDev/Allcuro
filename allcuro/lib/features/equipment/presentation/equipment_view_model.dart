import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/equipment_repository.dart';
import '../data/equipment_service.dart';
import '../data/models/equipment.dart';

class EquipmentListData {
  final List<Equipment> equipment;
  final List<String> categories;

  const EquipmentListData({required this.equipment, required this.categories});
}

class EquipmentViewModel extends AsyncNotifier<EquipmentListData> {
  @override
  Future<EquipmentListData> build() async {
    final equipment = await ref.watch(equipmentRepositoryProvider).getAll();
    return EquipmentListData(equipment: equipment, categories: EquipmentService.categoriesOf(equipment));
  }
}

final equipmentViewModelProvider =
    AsyncNotifierProvider<EquipmentViewModel, EquipmentListData>(EquipmentViewModel.new);

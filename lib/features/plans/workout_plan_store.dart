import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'workout_plan_models.dart';

class WorkoutPlanStore {
  WorkoutPlanStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _cacheKey = 'workout_plans_cache_v1';
  static const _operationsKey = 'workout_plan_operations_v1';
  static const _tempPlanIdKey = 'workout_plan_next_temp_id';
  static const _tempItemIdKey = 'workout_plan_next_temp_item_id';

  final SharedPreferencesAsync _preferences;

  Future<List<WorkoutPlan>> readPlans() async {
    final raw = await _preferences.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(WorkoutPlan.fromJson)
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }

  Future<void> writePlans(List<WorkoutPlan> plans) async {
    await _preferences.setString(
      _cacheKey,
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }

  Future<void> upsertPlan(WorkoutPlan plan) async {
    final plans = await readPlans();
    final index = plans.indexWhere((item) => item.id == plan.id);
    if (index >= 0) {
      plans[index] = plan;
    } else {
      plans.insert(0, plan);
    }
    await writePlans(plans);
  }

  Future<void> removePlan(int id) async {
    final plans = await readPlans();
    await writePlans(plans.where((plan) => plan.id != id).toList());
  }

  Future<void> replacePlanId(int previousId, WorkoutPlan nextPlan) async {
    final plans = await readPlans();
    await writePlans([
      for (final plan in plans)
        if (plan.id == previousId) nextPlan else plan,
    ]);
  }

  Future<int> nextTempPlanId() async {
    final current = await _preferences.getInt(_tempPlanIdKey) ?? -1;
    await _preferences.setInt(_tempPlanIdKey, current - 1);
    return current;
  }

  Future<int> nextTempItemId() async {
    final current = await _preferences.getInt(_tempItemIdKey) ?? -1;
    await _preferences.setInt(_tempItemIdKey, current - 1);
    return current;
  }

  Future<List<PlanOperation>> readOperations() async {
    final raw = await _preferences.getString(_operationsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PlanOperation.fromJson)
        .toList();
  }

  Future<void> writeOperations(List<PlanOperation> operations) async {
    await _preferences.setString(
      _operationsKey,
      jsonEncode(operations.map((operation) => operation.toJson()).toList()),
    );
  }

  Future<void> addOperation(PlanOperation operation) async {
    final operations = await readOperations();
    operations.add(operation);
    await writeOperations(operations);
  }

  Future<void> removeOperation(String clientId) async {
    final operations = await readOperations();
    await writeOperations(
      operations.where((operation) => operation.clientId != clientId).toList(),
    );
  }

  Future<void> discardOperationsForPlan(int planId) async {
    final operations = await readOperations();
    await writeOperations(
      operations
          .where(
            (operation) =>
                operation.planId != planId && operation.localPlanId != planId,
          )
          .toList(),
    );
  }
}

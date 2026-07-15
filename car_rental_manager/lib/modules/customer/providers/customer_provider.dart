import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/customer_model.dart';
import '../models/customer_state.dart';
import '../repository/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(databaseHelperProvider));
});

/// Customer list + search query.
final customerListProvider =
    AsyncNotifierProvider<CustomerListNotifier, CustomerState>(
  CustomerListNotifier.new,
);

class CustomerListNotifier extends AsyncNotifier<CustomerState> {
  @override
  Future<CustomerState> build() async {
    final customers =
        await ref.read(customerRepositoryProvider).getCustomers();
    return CustomerState(customers: customers);
  }

  Future<void> refresh() async {
    final previous = state;
    state = const AsyncLoading<CustomerState>().copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      final customers =
          await ref.read(customerRepositoryProvider).getCustomers();
      final query = previous.valueOrNull?.query ?? '';
      return CustomerState(customers: customers, query: query);
    });
  }

  void setQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: query));
  }

  Future<CustomerModel> addCustomer({
    required String name,
    required String phone,
    String? cnic,
    String? address,
  }) async {
    final created = await ref.read(customerRepositoryProvider).addCustomer(
          name: name,
          phone: phone,
          cnic: cnic,
          address: address,
        );
    await _reloadRelated();
    return created;
  }

  Future<CustomerModel> updateCustomer({
    required int id,
    required String name,
    required String phone,
    String? cnic,
    String? address,
  }) async {
    final updated = await ref.read(customerRepositoryProvider).updateCustomer(
          id: id,
          name: name,
          phone: phone,
          cnic: cnic,
          address: address,
        );
    await _reloadRelated();
    return updated;
  }

  Future<void> deleteCustomer(int id) async {
    await ref.read(customerRepositoryProvider).deleteCustomer(id);
    await _reloadRelated();
  }

  Future<void> _reloadRelated() async {
    await refresh();
    await ref.read(dashboardProvider.notifier).refresh();
  }
}

/// Single customer details keyed by id.
final customerDetailProvider =
    FutureProvider.autoDispose.family<CustomerModel, int>((ref, id) async {
  // Re-fetch when the list mutates.
  ref.watch(customerListProvider);
  return ref.watch(customerRepositoryProvider).getCustomer(id);
});

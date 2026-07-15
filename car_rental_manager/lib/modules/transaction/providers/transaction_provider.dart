import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';
import '../../backup/providers/data_change_bus.dart';
import '../../customer/providers/customer_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../models/transaction_model.dart';
import '../models/transaction_state.dart';
import '../repository/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseHelperProvider));
});

final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, TransactionState>(
  TransactionListNotifier.new,
);

class TransactionListNotifier extends AsyncNotifier<TransactionState> {
  @override
  Future<TransactionState> build() async {
    final items = await ref.read(transactionRepositoryProvider).getAll();
    return TransactionState(transactions: items);
  }

  Future<void> refresh() async {
    final previous = state;
    state = const AsyncLoading<TransactionState>().copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      final items = await ref.read(transactionRepositoryProvider).getAll();
      final current = previous.valueOrNull;
      return TransactionState(
        transactions: items,
        query: current?.query ?? '',
        filterDate: current?.filterDate,
      );
    });
  }

  void setQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: query));
  }

  void setFilterDate(DateTime? date) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        filterDate: date,
        clearFilterDate: date == null,
      ),
    );
  }

  Future<TransactionModel> add({
    required int customerId,
    required DateTime date,
    required String description,
    required double totalAmount,
    required double receivedAmount,
    String? notes,
  }) async {
    final created = await ref.read(transactionRepositoryProvider).add(
          customerId: customerId,
          date: date,
          description: description,
          totalAmount: totalAmount,
          receivedAmount: receivedAmount,
          notes: notes,
        );
    await _reloadRelated();
    return created;
  }

  Future<TransactionModel> updateTransaction({
    required int id,
    required int customerId,
    required DateTime date,
    required String description,
    required double totalAmount,
    required double receivedAmount,
    String? notes,
  }) async {
    final updated = await ref.read(transactionRepositoryProvider).update(
          id: id,
          customerId: customerId,
          date: date,
          description: description,
          totalAmount: totalAmount,
          receivedAmount: receivedAmount,
          notes: notes,
        );
    await _reloadRelated();
    return updated;
  }

  Future<void> delete(int id) async {
    await ref.read(transactionRepositoryProvider).delete(id);
    await _reloadRelated();
  }

  Future<void> _reloadRelated() async {
    await refresh();
    await ref.read(customerListProvider.notifier).refresh();
    await ref.read(dashboardProvider.notifier).refresh();
    ref.read(dataChangeBusProvider.notifier).markDirty();
  }
}

final transactionDetailProvider =
    FutureProvider.autoDispose.family<TransactionModel, int>((ref, id) async {
  ref.watch(transactionListProvider);
  return ref.watch(transactionRepositoryProvider).getById(id);
});

final openTransactionsProvider = FutureProvider.autoDispose
    .family<List<TransactionModel>, int>((ref, customerId) async {
  ref.watch(transactionListProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .getOpenByCustomer(customerId);
});

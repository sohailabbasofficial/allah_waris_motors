import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';
import '../../backup/providers/data_change_bus.dart';
import '../../customer/providers/customer_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../models/payment_model.dart';
import '../models/payment_state.dart';
import '../repository/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(databaseHelperProvider));
});

final paymentListProvider =
    AsyncNotifierProvider<PaymentListNotifier, PaymentState>(
  PaymentListNotifier.new,
);

class PaymentListNotifier extends AsyncNotifier<PaymentState> {
  @override
  Future<PaymentState> build() async {
    final items = await ref.read(paymentRepositoryProvider).getAll();
    return PaymentState(payments: items);
  }

  Future<void> refresh() async {
    final previous = state;
    state = const AsyncLoading<PaymentState>().copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      final items = await ref.read(paymentRepositoryProvider).getAll();
      final current = previous.valueOrNull;
      return PaymentState(
        payments: items,
        query: current?.query ?? '',
        filterDate: current?.filterDate,
        customerIdFilter: current?.customerIdFilter,
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
      current.copyWith(filterDate: date, clearFilterDate: date == null),
    );
  }

  void setCustomerFilter(int? customerId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        customerIdFilter: customerId,
        clearCustomerFilter: customerId == null,
      ),
    );
  }

  Future<PaymentModel> add({
    required int transactionId,
    required DateTime paymentDate,
    required double paymentAmount,
    String? notes,
  }) async {
    final created = await ref.read(paymentRepositoryProvider).add(
          transactionId: transactionId,
          paymentDate: paymentDate,
          paymentAmount: paymentAmount,
          notes: notes,
        );
    await _reloadRelated();
    return created;
  }

  Future<PaymentModel> updatePayment({
    required int id,
    required DateTime paymentDate,
    required double paymentAmount,
    String? notes,
  }) async {
    final updated = await ref.read(paymentRepositoryProvider).updatePayment(
          id: id,
          paymentDate: paymentDate,
          paymentAmount: paymentAmount,
          notes: notes,
        );
    await _reloadRelated();
    return updated;
  }

  Future<void> deletePayment(int id) async {
    await ref.read(paymentRepositoryProvider).delete(id);
    await _reloadRelated();
  }

  Future<void> _reloadRelated() async {
    await refresh();
    await ref.read(customerListProvider.notifier).refresh();
    await ref.read(transactionListProvider.notifier).refresh();
    await ref.read(dashboardProvider.notifier).refresh();
    ref.read(dataChangeBusProvider.notifier).markDirty();
  }
}

final paymentDetailProvider =
    FutureProvider.autoDispose.family<PaymentModel, int>((ref, id) async {
  ref.watch(paymentListProvider);
  return ref.watch(paymentRepositoryProvider).getById(id);
});

final customerAvailableBalanceProvider =
    FutureProvider.autoDispose.family<double, int>((ref, customerId) async {
  ref.watch(paymentListProvider);
  ref.watch(customerListProvider);
  return ref.watch(paymentRepositoryProvider).availableBalance(customerId);
});

final transactionAvailableBalanceProvider =
    FutureProvider.autoDispose.family<double, int>((ref, transactionId) async {
  ref.watch(paymentListProvider);
  ref.watch(transactionListProvider);
  return ref
      .watch(paymentRepositoryProvider)
      .availableForTransaction(transactionId);
});

/// Available balance when editing a payment (excludes that payment amount).
final editableAvailableBalanceProvider = FutureProvider.autoDispose
    .family<double, ({int transactionId, int excludePaymentId})>((ref, args) async {
  ref.watch(paymentListProvider);
  return ref.watch(paymentRepositoryProvider).availableForTransaction(
        args.transactionId,
        excludePaymentId: args.excludePaymentId,
      );
});


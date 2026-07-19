import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_contact_suggestion.dart';
import '../models/matched_contact_model.dart';
import '../services/contact_sync_service.dart';
import 'customer_provider.dart';

final contactSyncServiceProvider = Provider<ContactSyncService>((ref) {
  return const ContactSyncService();
});

/// Cached phone-book entries for Add Customer autocomplete (device contacts).
final deviceContactsCacheProvider =
    FutureProvider.autoDispose<List<DeviceContactSuggestion>>((ref) async {
  return ref.watch(contactSyncServiceProvider).loadDeviceContactSuggestions();
});

/// Device-contact phone suggestions for typed digits.
final devicePhoneSuggestionsProvider = FutureProvider.autoDispose
    .family<List<DeviceContactSuggestion>, String>((ref, query) async {
  final digits = query.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 3) return const [];
  final all = await ref.watch(deviceContactsCacheProvider.future);
  return ref
      .watch(contactSyncServiceProvider)
      .filterByPhoneDigits(all, digits);
});

class ContactSyncState {
  const ContactSyncState({
    this.matches = const [],
    this.query = '',
    this.contactsScanned = 0,
    this.permission = ContactSyncPermissionStatus.granted,
    this.errorMessage,
    this.lastSyncedAt,
  });

  final List<MatchedContactModel> matches;
  final String query;
  final int contactsScanned;
  final ContactSyncPermissionStatus permission;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  List<MatchedContactModel> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return matches;
    return matches.where((m) {
      return m.contactName.toLowerCase().contains(q) ||
          m.phoneNumber.toLowerCase().contains(q) ||
          m.customer.name.toLowerCase().contains(q);
    }).toList();
  }

  ContactSyncState copyWith({
    List<MatchedContactModel>? matches,
    String? query,
    int? contactsScanned,
    ContactSyncPermissionStatus? permission,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool clearError = false,
  }) {
    return ContactSyncState(
      matches: matches ?? this.matches,
      query: query ?? this.query,
      contactsScanned: contactsScanned ?? this.contactsScanned,
      permission: permission ?? this.permission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  bool get isPermissionDenied =>
      permission == ContactSyncPermissionStatus.denied ||
      permission == ContactSyncPermissionStatus.permanentlyDenied;

  bool get isUnsupported =>
      permission == ContactSyncPermissionStatus.unsupported;
}

final contactSyncProvider =
    AsyncNotifierProvider<ContactSyncNotifier, ContactSyncState>(
  ContactSyncNotifier.new,
);

class ContactSyncNotifier extends AsyncNotifier<ContactSyncState> {
  @override
  Future<ContactSyncState> build() async {
    // Keep in sync when customer list changes.
    ref.watch(customerListProvider);
    return _sync(keepQuery: false);
  }

  Future<void> refresh() async {
    final previous = state;
    final query = previous.valueOrNull?.query ?? '';
    state = const AsyncLoading<ContactSyncState>().copyWithPrevious(previous);
    state = await AsyncValue.guard(() async {
      final next = await _sync(keepQuery: true);
      return next.copyWith(query: query);
    });
  }

  void setQuery(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(query: query));
  }

  Future<ContactSyncState> _sync({required bool keepQuery}) async {
    final customers =
        await ref.read(customerRepositoryProvider).getCustomers();
    final result =
        await ref.read(contactSyncServiceProvider).syncMatchedCustomers(
              customers,
            );

    return ContactSyncState(
      matches: result.matches,
      query: keepQuery ? (state.valueOrNull?.query ?? '') : '',
      contactsScanned: result.contactsScanned,
      permission: result.permission,
      errorMessage: result.errorMessage,
      lastSyncedAt: DateTime.now(),
    );
  }
}

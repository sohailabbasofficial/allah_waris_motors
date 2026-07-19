import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/utils/phone_normalizer.dart';
import '../models/customer_model.dart';
import '../models/device_contact_suggestion.dart';
import '../models/matched_contact_model.dart';

enum ContactSyncPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unsupported,
}

class ContactSyncResult {
  const ContactSyncResult({
    required this.permission,
    required this.matches,
    this.contactsScanned = 0,
    this.errorMessage,
  });

  final ContactSyncPermissionStatus permission;
  final List<MatchedContactModel> matches;
  final int contactsScanned;
  final String? errorMessage;

  bool get isPermissionDenied =>
      permission == ContactSyncPermissionStatus.denied ||
      permission == ContactSyncPermissionStatus.permanentlyDenied;

  bool get isUnsupported =>
      permission == ContactSyncPermissionStatus.unsupported;
}

/// Reads device contacts and intersects them with app customers by phone.
class ContactSyncService {
  const ContactSyncService();

  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    final status =
        await FlutterContacts.permissions.check(PermissionType.read);
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final status =
        await FlutterContacts.permissions.request(PermissionType.read);
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  /// Loads phone-book entries (name + phone) for Add Customer autocomplete.
  Future<List<DeviceContactSuggestion>> loadDeviceContactSuggestions() async {
    if (kIsWeb) return const [];
    final allowed = await requestPermission();
    if (!allowed) return const [];

    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );

    final suggestions = <DeviceContactSuggestion>[];
    final seenPhones = <String>{};

    for (final contact in contacts) {
      if (contact.phones.isEmpty) continue;
      final name = (contact.displayName ?? '').trim().isEmpty
          ? 'Unknown'
          : contact.displayName!.trim();

      for (final phone in contact.phones) {
        final raw = phone.number.trim();
        if (raw.isEmpty) continue;
        final normalized = PhoneNormalizer.normalize(raw);
        if (normalized.isEmpty) continue;
        if (!seenPhones.add(normalized)) continue;

        suggestions.add(
          DeviceContactSuggestion(
            name: name,
            phone: raw,
            normalizedPhone: normalized,
          ),
        );
      }
    }

    suggestions.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return suggestions;
  }

  /// Filters device contacts by typed digits (partial match).
  List<DeviceContactSuggestion> filterByPhoneDigits(
    List<DeviceContactSuggestion> all,
    String queryDigits, {
    int limit = 12,
  }) {
    final digits = queryDigits.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 2) return const [];

    final starts = <DeviceContactSuggestion>[];
    final contains = <DeviceContactSuggestion>[];

    for (final item in all) {
      final phoneDigits = item.normalizedPhone;
      if (phoneDigits.startsWith(digits)) {
        starts.add(item);
      } else if (phoneDigits.contains(digits)) {
        contains.add(item);
      }
      if (starts.length >= limit) break;
    }

    return [...starts, ...contains].take(limit).toList();
  }

  Future<ContactSyncResult> syncMatchedCustomers(
    List<CustomerModel> customers,
  ) async {
    if (kIsWeb) {
      return const ContactSyncResult(
        permission: ContactSyncPermissionStatus.unsupported,
        matches: [],
        errorMessage: 'Contact sync is not available on web.',
      );
    }

    final allowed = await requestPermission();
    if (!allowed) {
      final status =
          await FlutterContacts.permissions.check(PermissionType.read);
      return ContactSyncResult(
        permission: status == PermissionStatus.permanentlyDenied ||
                status == PermissionStatus.restricted
            ? ContactSyncPermissionStatus.permanentlyDenied
            : ContactSyncPermissionStatus.denied,
        matches: const [],
        errorMessage:
            'Contacts permission was denied. Enable it in system settings to sync.',
      );
    }

    try {
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );

      final index = _buildCustomerPhoneIndex(customers);
      final matches = <MatchedContactModel>[];
      final seenCustomerIds = <int>{};

      for (final contact in contacts) {
        if (contact.phones.isEmpty) continue;
        final contactName = (contact.displayName ?? '').trim().isEmpty
            ? 'Unknown'
            : contact.displayName!.trim();

        for (final phone in contact.phones) {
          final rawPhone = phone.number.trim();
          if (rawPhone.isEmpty) continue;

          final customer = _findCustomer(index, rawPhone) ??
              _findCustomer(index, phone.normalizedNumber);
          if (customer == null) continue;
          if (!seenCustomerIds.add(customer.id)) continue;

          matches.add(
            MatchedContactModel(
              contactId: contact.id ?? customer.id.toString(),
              contactName: contactName,
              phoneNumber: rawPhone,
              customer: customer,
            ),
          );
          break;
        }
      }

      matches.sort(
        (a, b) => a.contactName.toLowerCase().compareTo(
              b.contactName.toLowerCase(),
            ),
      );

      return ContactSyncResult(
        permission: ContactSyncPermissionStatus.granted,
        matches: matches,
        contactsScanned: contacts.length,
      );
    } catch (e) {
      return ContactSyncResult(
        permission: ContactSyncPermissionStatus.granted,
        matches: const [],
        errorMessage: 'Failed to read contacts: $e',
      );
    }
  }

  Map<String, CustomerModel> _buildCustomerPhoneIndex(
    List<CustomerModel> customers,
  ) {
    final index = <String, CustomerModel>{};
    for (final customer in customers) {
      for (final key in PhoneNormalizer.matchKeys(customer.phone)) {
        index.putIfAbsent(key, () => customer);
      }
    }
    return index;
  }

  CustomerModel? _findCustomer(
    Map<String, CustomerModel> index,
    String? rawPhone,
  ) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return null;
    for (final key in PhoneNormalizer.matchKeys(rawPhone)) {
      final customer = index[key];
      if (customer != null) return customer;
    }
    return null;
  }
}

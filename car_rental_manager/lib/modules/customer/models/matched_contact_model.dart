import '../models/customer_model.dart';

/// A phone contact that matches an existing app customer.
class MatchedContactModel {
  const MatchedContactModel({
    required this.contactId,
    required this.contactName,
    required this.phoneNumber,
    required this.customer,
  });

  final String contactId;
  final String contactName;
  final String phoneNumber;
  final CustomerModel customer;

  String get statusLabel => 'Existing Customer';

  int get customerId => customer.id;
}

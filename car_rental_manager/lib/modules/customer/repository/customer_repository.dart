import '../../../core/database/database_helper.dart';
import '../data/customer_local_data_source.dart';
import '../models/customer_model.dart';

class DuplicatePhoneException implements Exception {
  DuplicatePhoneException(this.phone);
  final String phone;

  @override
  String toString() => 'Phone number already exists: $phone';
}

class CustomerNotFoundException implements Exception {
  CustomerNotFoundException(this.id);
  final int id;

  @override
  String toString() => 'Customer not found: $id';
}

class DatabaseUnavailableException implements Exception {
  @override
  String toString() => 'SQLite is unavailable on this platform.';
}

/// Customer CRUD against local SQLite.
class CustomerRepository {
  CustomerRepository(this._helper);

  final DatabaseHelper _helper;

  Future<CustomerLocalDataSource> _source() async {
    final db = await _helper.databaseOrNull;
    if (db == null) throw DatabaseUnavailableException();
    return CustomerLocalDataSource(db);
  }

  Future<List<CustomerModel>> getCustomers() async {
    final db = await _helper.databaseOrNull;
    if (db == null) return [];
    return CustomerLocalDataSource(db).getAll();
  }

  Future<CustomerModel> getCustomer(int id) async {
    final source = await _source();
    final customer = await source.getById(id);
    if (customer == null) throw CustomerNotFoundException(id);
    return customer;
  }

  Future<CustomerModel> addCustomer({
    required String name,
    required String phone,
    String? cnic,
    String? address,
  }) async {
    final source = await _source();
    final cleanPhone = phone.trim();
    if (await source.phoneExists(cleanPhone)) {
      throw DuplicatePhoneException(cleanPhone);
    }

    final now = DateTime.now();
    final id = await source.insert(
      CustomerModel(
        id: 0,
        name: name.trim(),
        phone: cleanPhone,
        cnic: _nullableTrim(cnic),
        address: _nullableTrim(address),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await source.getById(id))!;
  }

  Future<CustomerModel> updateCustomer({
    required int id,
    required String name,
    required String phone,
    String? cnic,
    String? address,
  }) async {
    final source = await _source();
    final existing = await source.getById(id);
    if (existing == null) throw CustomerNotFoundException(id);

    final cleanPhone = phone.trim();
    if (await source.phoneExists(cleanPhone, excludeId: id)) {
      throw DuplicatePhoneException(cleanPhone);
    }

    final updated = existing.copyWith(
      name: name.trim(),
      phone: cleanPhone,
      cnic: _nullableTrim(cnic),
      address: _nullableTrim(address),
      updatedAt: DateTime.now(),
    );
    await source.update(updated);
    return (await source.getById(id))!;
  }

  Future<void> deleteCustomer(int id) async {
    final source = await _source();
    final deleted = await source.delete(id);
    if (deleted == 0) throw CustomerNotFoundException(id);
  }

  String? _nullableTrim(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

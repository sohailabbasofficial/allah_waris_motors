import 'package:sqflite/sqflite.dart';

import '../models/customer_model.dart';

/// SQLite CRUD for the customers table.
class CustomerLocalDataSource {
  CustomerLocalDataSource(this._db);

  final Database _db;

  Future<List<CustomerModel>> getAll() async {
    final rows = await _db.query(
      'customers',
      orderBy: 'datetime(created_at) DESC',
    );
    return rows.map(CustomerModel.fromMap).toList();
  }

  Future<CustomerModel?> getById(int id) async {
    final rows = await _db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CustomerModel.fromMap(rows.first);
  }

  Future<bool> phoneExists(String phone, {int? excludeId}) async {
    final rows = excludeId == null
        ? await _db.query(
            'customers',
            columns: ['id'],
            where: 'phone = ?',
            whereArgs: [phone],
            limit: 1,
          )
        : await _db.query(
            'customers',
            columns: ['id'],
            where: 'phone = ? AND id != ?',
            whereArgs: [phone, excludeId],
            limit: 1,
          );
    return rows.isNotEmpty;
  }

  Future<int> insert(CustomerModel customer) async {
    return _db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> update(CustomerModel customer) async {
    return _db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> delete(int id) async {
    return _db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

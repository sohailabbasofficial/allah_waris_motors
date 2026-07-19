import 'package:sqflite/sqflite.dart';

import '../models/customer_model.dart';

/// Shared select that computes customer financial totals from child tables.
const String customerSelectWithBalances = '''
SELECT
  c.id AS id,
  c.name AS name,
  c.phone AS phone,
  c.cnic AS cnic,
  c.address AS address,
  c.created_at AS created_at,
  c.updated_at AS updated_at,
  COALESCE((
    SELECT SUM(t.total_amount) FROM transactions t WHERE t.customer_id = c.id
  ), 0) AS total_udhaar,
  COALESCE((
    SELECT SUM(t.received_amount) FROM transactions t WHERE t.customer_id = c.id
  ), 0) + COALESCE((
    SELECT SUM(p.payment_amount)
    FROM payments p
    INNER JOIN transactions t2 ON t2.id = p.transaction_id
    WHERE t2.customer_id = c.id
  ), 0) AS total_received,
  COALESCE((
    SELECT SUM(t.remaining_amount) FROM transactions t WHERE t.customer_id = c.id
  ), 0) AS remaining_balance
FROM customers c
''';

/// SQLite CRUD for the customers table.
class CustomerLocalDataSource {
  CustomerLocalDataSource(this._db);

  final Database _db;

  Future<List<CustomerModel>> getAll() async {
    final rows = await _db.rawQuery(
      '$customerSelectWithBalances ORDER BY datetime(c.created_at) DESC',
    );
    return rows.map(CustomerModel.fromMap).toList();
  }

  Future<CustomerModel?> getById(int id) async {
    final rows = await _db.rawQuery(
      '$customerSelectWithBalances WHERE c.id = ? LIMIT 1',
      [id],
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

  /// Fast partial phone lookup for autocomplete (no balance subqueries).
  ///
  /// Matches digits contained in [phone], case-insensitive on [name] sort.
  Future<List<CustomerModel>> searchByPhone(
    String query, {
    int limit = 10,
    int? excludeId,
  }) async {
    final digits = query.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 2) return [];

    final likeContains = '%$digits%';
    final likeStarts = '$digits%';
    final excludeClause = excludeId == null ? '' : 'AND id != ?';
    final args = <Object?>[
      likeContains,
      if (excludeId != null) excludeId,
      likeStarts,
      limit,
    ];

    final rows = await _db.rawQuery(
      '''
SELECT
  id,
  name,
  phone,
  cnic,
  address,
  created_at,
  updated_at,
  0 AS total_udhaar,
  0 AS total_received,
  0 AS remaining_balance
FROM customers
WHERE REPLACE(REPLACE(REPLACE(REPLACE(phone, ' ', ''), '-', ''), '+', ''), '(', '')
      LIKE ?
  $excludeClause
ORDER BY
  CASE
    WHEN REPLACE(REPLACE(REPLACE(REPLACE(phone, ' ', ''), '-', ''), '+', ''), '(', '')
         LIKE ? THEN 0
    ELSE 1
  END,
  name COLLATE NOCASE ASC
LIMIT ?
''',
      args,
    );
    return rows.map(CustomerModel.fromMap).toList();
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

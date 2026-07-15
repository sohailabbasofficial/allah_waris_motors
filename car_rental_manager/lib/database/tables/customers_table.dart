/// SQL DDL and metadata for the `customers` table.
class CustomersTable {
  CustomersTable._();

  static const String name = 'customers';

  static const String id = 'id';
  static const String nameCol = 'name';
  static const String phone = 'phone';
  static const String cnic = 'cnic';
  static const String address = 'address';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const String createSql = '''
CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  phone TEXT NOT NULL UNIQUE,
  cnic TEXT,
  address TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''';

  static const List<String> indexes = [
    'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_phone ON customers (phone)',
    'CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers (created_at)',
  ];
}

/// SQL DDL and metadata for the `payments` table.
class PaymentsTable {
  PaymentsTable._();

  static const String name = 'payments';

  static const String id = 'id';
  static const String transactionId = 'transaction_id';
  static const String paymentAmount = 'payment_amount';
  static const String paymentDate = 'payment_date';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';

  static const String createSql = '''
CREATE TABLE IF NOT EXISTS payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  payment_amount REAL NOT NULL,
  payment_date TEXT NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
)
''';

  static const List<String> indexes = [
    'CREATE INDEX IF NOT EXISTS idx_payments_transaction_id ON payments (transaction_id)',
    'CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON payments (payment_date)',
  ];
}

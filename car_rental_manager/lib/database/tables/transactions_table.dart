/// SQL DDL and metadata for the `transactions` table.
class TransactionsTable {
  TransactionsTable._();

  static const String name = 'transactions';

  static const String id = 'id';
  static const String customerId = 'customer_id';
  static const String description = 'description';
  static const String totalAmount = 'total_amount';
  static const String receivedAmount = 'received_amount';
  static const String remainingAmount = 'remaining_amount';
  static const String transactionDate = 'transaction_date';
  static const String notes = 'notes';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const String createSql = '''
CREATE TABLE IF NOT EXISTS transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  description TEXT NOT NULL,
  total_amount REAL NOT NULL,
  received_amount REAL NOT NULL DEFAULT 0,
  remaining_amount REAL NOT NULL,
  transaction_date TEXT NOT NULL,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
)
''';

  static const List<String> indexes = [
    'CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions (customer_id)',
    'CREATE INDEX IF NOT EXISTS idx_transactions_transaction_date ON transactions (transaction_date)',
  ];
}

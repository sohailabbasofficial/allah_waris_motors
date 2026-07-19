/// SQL DDL for `transaction_amount_additions` — ledger of amounts added
/// onto an existing transaction without overwriting the original total.
class TransactionAmountAdditionsTable {
  TransactionAmountAdditionsTable._();

  static const String name = 'transaction_amount_additions';

  static const String id = 'id';
  static const String transactionId = 'transaction_id';
  static const String amount = 'amount';
  static const String previousTotal = 'previous_total';
  static const String newTotal = 'new_total';
  static const String notes = 'notes';
  static const String addedBy = 'added_by';
  static const String createdAt = 'created_at';

  static const String createSql = '''
CREATE TABLE IF NOT EXISTS transaction_amount_additions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  previous_total REAL NOT NULL,
  new_total REAL NOT NULL,
  notes TEXT,
  added_by TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
)
''';

  static const List<String> indexes = [
    'CREATE INDEX IF NOT EXISTS idx_tx_amount_additions_tx_id '
        'ON transaction_amount_additions (transaction_id)',
    'CREATE INDEX IF NOT EXISTS idx_tx_amount_additions_created '
        'ON transaction_amount_additions (created_at)',
  ];
}

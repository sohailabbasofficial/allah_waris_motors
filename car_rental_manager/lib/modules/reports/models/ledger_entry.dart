/// A single chronological line in a customer ledger.
enum LedgerEntryType { transaction, payment }

class LedgerEntry {
  const LedgerEntry({
    required this.type,
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    this.referenceId,
    this.notes,
  });

  final LedgerEntryType type;
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double runningBalance;
  final int? referenceId;
  final String? notes;
}

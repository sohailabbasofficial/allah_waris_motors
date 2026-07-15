import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../routes/app_routes.dart';
import '../../customer/providers/customer_provider.dart';
import '../models/customer_ledger.dart';
import '../providers/reports_provider.dart';
import '../widgets/customer_ledger_card.dart';
import '../widgets/empty_report_widget.dart';
import '../widgets/report_filter_widget.dart';
import '../widgets/report_header.dart';
import '../widgets/report_summary_card.dart';

class CustomerLedgerScreen extends ConsumerStatefulWidget {
  const CustomerLedgerScreen({super.key, this.preselectedCustomerId});

  final int? preselectedCustomerId;

  @override
  ConsumerState<CustomerLedgerScreen> createState() =>
      _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends ConsumerState<CustomerLedgerScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    final id = widget.preselectedCustomerId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reportsUiProvider.notifier).setCustomerId(id);
      });
    }
  }

  Future<void> _export(CustomerLedger ledger) async {
    final service = ref.read(reportPdfServiceProvider);
    final text = await service.customerLedgerText(ledger);
    await service.copyToClipboard(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Customer ledger copied. PDF export is optional and not enabled yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers =
        ref.watch(customerListProvider).valueOrNull?.customers ?? [];
    final selectedId = ref.watch(reportsUiProvider).selectedCustomerId;
    final query = _search.trim().toLowerCase();
    final filtered = query.isEmpty
        ? customers
        : customers
            .where(
              (c) =>
                  c.name.toLowerCase().contains(query) ||
                  c.phone.toLowerCase().contains(query),
            )
            .toList();

    final ledgerAsync = selectedId == null
        ? null
        : ref.watch(customerLedgerProvider(selectedId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger'),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed: ledgerAsync?.asData == null
                ? null
                : () {
                    final ledger = ledgerAsync!.requireValue;
                    if (ledger != null) _export(ledger);
                  },
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text(
                    'SQLite reports require Android, iOS, or desktop.',
                  ),
                ),
              ),
            ),
          ReportFilterWidget(
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search customer',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Customer *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: filtered
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.name} (${c.phone})'),
                        ),
                      )
                      .toList(),
                  onChanged: (id) =>
                      ref.read(reportsUiProvider.notifier).setCustomerId(id),
                  validator: (_) => null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (selectedId == null)
            const EmptyReportWidget(
              title: 'Select a customer',
              message: 'Search and choose a customer to view their ledger.',
              icon: Icons.person_search_outlined,
            )
          else
            ledgerAsync!.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('Failed to load ledger: $e'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(customerLedgerProvider(selectedId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (ledger) {
                if (ledger == null) {
                  return const EmptyReportWidget(
                    title: 'Customer not found',
                    message: 'The selected customer no longer exists.',
                  );
                }

                final c = ledger.customer;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ReportHeader(
                      title: 'Customer Ledger',
                      subtitle: c.name,
                      trailing: IconButton(
                        tooltip: 'Open customer',
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.customerDetail,
                          arguments: c.id,
                        ),
                        icon: const Icon(Icons.open_in_new),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer details',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _DetailRow(label: 'Name', value: c.name),
                            _DetailRow(label: 'Phone', value: c.phone),
                            _DetailRow(
                              label: 'CNIC',
                              value: c.cnic?.trim().isNotEmpty == true
                                  ? c.cnic!
                                  : '-',
                            ),
                            _DetailRow(
                              label: 'Address',
                              value: c.address?.trim().isNotEmpty == true
                                  ? c.address!
                                  : '-',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReportSummaryCard(
                      label: 'Total Amount',
                      value: CurrencyFormatter.format(ledger.totalAmount),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    ReportSummaryCard(
                      label: 'Total Paid',
                      value: CurrencyFormatter.format(ledger.totalPaid),
                      icon: Icons.payments_outlined,
                    ),
                    ReportSummaryCard(
                      label: 'Remaining Balance',
                      value:
                          CurrencyFormatter.format(ledger.remainingBalance),
                      icon: Icons.pending_actions_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ledger (oldest to newest)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (!ledger.hasData)
                      const EmptyReportWidget(
                        title: 'No ledger entries',
                        message:
                            'This customer has no transactions or payments yet.',
                      )
                    else
                      ...ledger.entries.map(
                        (entry) => CustomerLedgerCard(entry: entry),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../models/daily_report.dart';
import '../providers/reports_provider.dart';
import '../widgets/empty_report_widget.dart';
import '../widgets/report_filter_widget.dart';
import '../widgets/report_header.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_transaction_tile.dart';

class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({super.key});

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current =
        ref.read(reportsUiProvider).selectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(reportsUiProvider.notifier).setDate(picked);
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref, DailyReport report) async {
    final service = ref.read(reportPdfServiceProvider);
    final text = await service.dailyReportText(report);
    await service.copyToClipboard(text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Daily report copied. PDF export is optional and not enabled yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        ref.watch(reportsUiProvider).selectedDate ?? DateTime.now();
    final reportAsync = ref.watch(dailyReportProvider(selected));
    final dateLabel = DateFormat('dd MMM yyyy').format(selected);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Report'),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed: reportAsync.asData == null
                ? null
                : () => _export(context, ref, reportAsync.requireValue),
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load report: $e'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(dailyReportProvider(selected)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (report) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dailyReportProvider(selected));
              await ref.read(dailyReportProvider(selected).future);
            },
            child: ListView(
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
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Report date'),
                    subtitle: Text(dateLabel),
                    trailing: FilledButton.tonal(
                      onPressed: () => _pickDate(context, ref),
                      child: const Text('Change'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ReportHeader(
                  title: 'Daily Report',
                  subtitle: dateLabel,
                ),
                const SizedBox(height: 12),
                if (!report.hasData)
                  const EmptyReportWidget(
                    title: 'No activity for this date',
                    message: 'Pick another day to view daily business activity.',
                  )
                else ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 600
                              ? 2
                              : 1;
                      final cards = [
                        ReportSummaryCard(
                          label: 'Total Transactions',
                          value: '${report.totalTransactions}',
                          icon: Icons.receipt_long_outlined,
                        ),
                        ReportSummaryCard(
                          label: 'Total Amount',
                          value: CurrencyFormatter.format(report.totalAmount),
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        ReportSummaryCard(
                          label: 'Payments Received',
                          value: CurrencyFormatter.format(
                            report.totalPaymentsReceived,
                          ),
                          icon: Icons.payments_outlined,
                        ),
                        ReportSummaryCard(
                          label: 'Remaining Balance',
                          value: CurrencyFormatter.format(
                            report.remainingBalance,
                          ),
                          icon: Icons.pending_actions_outlined,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        ReportSummaryCard(
                          label: 'Customers Served',
                          value: '${report.customersServed}',
                          icon: Icons.groups_outlined,
                        ),
                      ];
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.6,
                        children: cards,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (report.transactions.isEmpty)
                    const EmptyReportWidget(
                      title: 'No transactions',
                      message: 'Payments may still have been received today.',
                    )
                  else
                    ...report.transactions.map(
                      (tx) => ReportTransactionTile(transaction: tx),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

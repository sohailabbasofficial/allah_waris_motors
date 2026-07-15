import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
import '../models/monthly_report.dart';
import '../providers/reports_provider.dart';
import '../widgets/empty_report_widget.dart';
import '../widgets/report_filter_widget.dart';
import '../widgets/report_header.dart';
import '../widgets/report_summary_card.dart';
import '../widgets/report_transaction_tile.dart';

class MonthlyReportScreen extends ConsumerWidget {
  const MonthlyReportScreen({super.key});

  Future<void> _pickMonth(BuildContext context, WidgetRef ref) async {
    final ui = ref.read(reportsUiProvider);
    final year = ui.selectedYear ?? DateTime.now().year;
    final month = ui.selectedMonth ?? DateTime.now().month;

    final result = await showDialog<(int, int)>(
      context: context,
      builder: (context) => _MonthYearDialog(year: year, month: month),
    );
    if (result != null) {
      ref.read(reportsUiProvider.notifier).setMonthYear(result.$1, result.$2);
    }
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    MonthlyReport report,
  ) async {
    final service = ref.read(reportPdfServiceProvider);
    final text = await service.monthlyReportText(report);
    await service.copyToClipboard(text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Monthly report copied. PDF export is optional and not enabled yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(reportsUiProvider);
    final year = ui.selectedYear ?? DateTime.now().year;
    final month = ui.selectedMonth ?? DateTime.now().month;
    final period = (year: year, month: month);
    final reportAsync = ref.watch(monthlyReportProvider(period));
    final periodLabel = DateFormat('MMMM yyyy').format(DateTime(year, month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report'),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed: reportAsync.asData == null
                ? null
                : () => _export(context, ref, reportAsync.requireValue),
            icon: const Icon(AppIcons.export),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const AppLoading(label: 'Loading monthly report…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load report',
          message: e.toString(),
          onRetry: () => ref.invalidate(monthlyReportProvider(period)),
        ),
        data: (report) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(monthlyReportProvider(period));
              await ref.read(monthlyReportProvider(period).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                if (kIsWeb)
                  PremiumCard(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        AppIcons.info,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text(
                        'SQLite reports require Android, iOS, or desktop.',
                      ),
                    ),
                  ),
                ReportFilterWidget(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        AppIcons.calendar,
                        color: AppColors.secondary,
                      ),
                    ),
                    title: const Text('Month & year'),
                    subtitle: Text(periodLabel),
                    trailing: FilledButton.tonal(
                      onPressed: () => _pickMonth(context, ref),
                      child: const Text('Change'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ReportHeader(
                  title: 'Monthly Report',
                  subtitle: periodLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                if (!report.hasData)
                  const EmptyReportWidget(
                    title: 'No activity for this month',
                    message: 'Select another month to generate a report.',
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
                          icon: AppIcons.transactions,
                        ),
                        ReportSummaryCard(
                          label: 'Total Revenue',
                          value: CurrencyFormatter.format(report.totalRevenue),
                          icon: AppIcons.money,
                          color: AppColors.secondary,
                        ),
                        ReportSummaryCard(
                          label: 'Payments Received',
                          value: CurrencyFormatter.format(
                            report.totalPaymentsReceived,
                          ),
                          icon: AppIcons.payments,
                          color: AppColors.success,
                        ),
                        ReportSummaryCard(
                          label: 'Outstanding Balance',
                          value: CurrencyFormatter.format(
                            report.outstandingBalance,
                          ),
                          icon: AppIcons.remaining,
                          color: AppColors.error,
                        ),
                        ReportSummaryCard(
                          label: 'New Customers',
                          value: '${report.newCustomersAdded}',
                          icon: AppIcons.addCustomer,
                          color: AppColors.accent,
                        ),
                        ReportSummaryCard(
                          label: 'Monthly Collection',
                          value: CurrencyFormatter.format(
                            report.monthlyCollection,
                          ),
                          icon: AppIcons.received,
                          color: AppColors.success,
                        ),
                      ];
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: AppSpacing.sm,
                        crossAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 2.6,
                        children: cards,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: 'Transactions'),
                  if (report.transactions.isEmpty)
                    const EmptyReportWidget(
                      title: 'No transactions',
                      message: 'Collection may still include payments.',
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

class _MonthYearDialog extends StatefulWidget {
  const _MonthYearDialog({required this.year, required this.month});

  final int year;
  final int month;

  @override
  State<_MonthYearDialog> createState() => _MonthYearDialogState();
}

class _MonthYearDialogState extends State<_MonthYearDialog> {
  late int _year = widget.year;
  late int _month = widget.month;

  @override
  Widget build(BuildContext context) {
    final years = [
      for (var y = DateTime.now().year + 1; y >= 2000; y--) y,
    ];

    return AlertDialog(
      title: const Text('Select month'),
      content: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: _month,
              decoration: const InputDecoration(labelText: 'Month'),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                    value: m,
                    child: Text(DateFormat('MMMM').format(DateTime(2000, m))),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _month = value);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: _year,
              decoration: const InputDecoration(labelText: 'Year'),
              items: years
                  .map(
                    (y) => DropdownMenuItem(value: y, child: Text('$y')),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _year = value);
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_year, _month)),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

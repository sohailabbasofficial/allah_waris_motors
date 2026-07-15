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
            icon: const Icon(AppIcons.export),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const AppLoading(label: 'Loading daily report…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load report',
          message: e.toString(),
          onRetry: () => ref.invalidate(dailyReportProvider(selected)),
        ),
        data: (report) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dailyReportProvider(selected));
              await ref.read(dailyReportProvider(selected).future);
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
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(AppIcons.calendar, color: AppColors.primary),
                    ),
                    title: const Text('Report date'),
                    subtitle: Text(dateLabel),
                    trailing: FilledButton.tonal(
                      onPressed: () => _pickDate(context, ref),
                      child: const Text('Change'),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ReportHeader(
                  title: 'Daily Report',
                  subtitle: dateLabel,
                ),
                const SizedBox(height: AppSpacing.md),
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
                          icon: AppIcons.transactions,
                        ),
                        ReportSummaryCard(
                          label: 'Total Amount',
                          value: CurrencyFormatter.format(report.totalAmount),
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
                          label: 'Remaining Balance',
                          value: CurrencyFormatter.format(
                            report.remainingBalance,
                          ),
                          icon: AppIcons.remaining,
                          color: AppColors.error,
                        ),
                        ReportSummaryCard(
                          label: 'Customers Served',
                          value: '${report.customersServed}',
                          icon: AppIcons.customers,
                          color: AppColors.accent,
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

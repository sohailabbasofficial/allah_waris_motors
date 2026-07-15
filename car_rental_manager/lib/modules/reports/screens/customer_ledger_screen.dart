import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
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
            icon: const Icon(AppIcons.export),
          ),
        ],
      ),
      body: ListView(
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
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search customer',
                    prefixIcon: Icon(AppIcons.search),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<int>(
                  // ignore: deprecated_member_use
                  value: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Customer *',
                    prefixIcon: Icon(AppIcons.customer),
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
          const SizedBox(height: AppSpacing.md),
          if (selectedId == null)
            const EmptyReportWidget(
              title: 'Select a customer',
              message: 'Search and choose a customer to view their ledger.',
              icon: AppIcons.customer,
            )
          else
            ledgerAsync!.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xxxl),
                child: AppLoading(label: 'Loading ledger…'),
              ),
              error: (e, _) => AppErrorState(
                title: 'Could not load ledger',
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(customerLedgerProvider(selectedId)),
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
                        icon: const Icon(AppIcons.customer),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PremiumCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Customer details',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _DetailRow(
                            icon: AppIcons.customer,
                            label: 'Name',
                            value: c.name,
                          ),
                          _DetailRow(
                            icon: AppIcons.phone,
                            label: 'Phone',
                            value: c.phone,
                          ),
                          _DetailRow(
                            icon: AppIcons.info,
                            label: 'CNIC',
                            value: c.cnic?.trim().isNotEmpty == true
                                ? c.cnic!
                                : '-',
                          ),
                          _DetailRow(
                            icon: AppIcons.address,
                            label: 'Address',
                            value: c.address?.trim().isNotEmpty == true
                                ? c.address!
                                : '-',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ReportSummaryCard(
                      label: 'Total Amount',
                      value: CurrencyFormatter.format(ledger.totalAmount),
                      icon: AppIcons.money,
                      color: AppColors.customers,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ReportSummaryCard(
                      label: 'Total Paid',
                      value: CurrencyFormatter.format(ledger.totalPaid),
                      icon: AppIcons.payments,
                      color: AppColors.received,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ReportSummaryCard(
                      label: 'Remaining Balance',
                      value:
                          CurrencyFormatter.format(ledger.remainingBalance),
                      icon: AppIcons.remaining,
                      color: AppColors.remaining,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const SectionHeader(title: 'Ledger (oldest to newest)'),
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
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
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

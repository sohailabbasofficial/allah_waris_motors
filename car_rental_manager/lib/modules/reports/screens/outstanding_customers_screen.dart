import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../routes/app_routes.dart';
import '../models/outstanding_customer.dart';
import '../providers/reports_provider.dart';
import '../widgets/empty_report_widget.dart';
import '../widgets/outstanding_customer_card.dart';
import '../widgets/report_filter_widget.dart';
import '../widgets/report_header.dart';

class OutstandingCustomersScreen extends ConsumerStatefulWidget {
  const OutstandingCustomersScreen({super.key});

  @override
  ConsumerState<OutstandingCustomersScreen> createState() =>
      _OutstandingCustomersScreenState();
}

class _OutstandingCustomersScreenState
    extends ConsumerState<OutstandingCustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _export(List<OutstandingCustomer> items) async {
    final service = ref.read(reportPdfServiceProvider);
    final text = await service.outstandingCustomersText(items);
    await service.copyToClipboard(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Outstanding report copied. PDF export is optional and not enabled yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(reportsUiProvider);
    final asyncItems = ref.watch(outstandingCustomersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outstanding Customers'),
        actions: [
          IconButton(
            tooltip: 'Export',
            onPressed: asyncItems.asData == null
                ? null
                : () => _export(asyncItems.requireValue),
            icon: const Icon(AppIcons.export),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(outstandingCustomersProvider),
            icon: const Icon(AppIcons.refresh),
          ),
        ],
      ),
      body: asyncItems.when(
        loading: () =>
            const AppLoading(label: 'Loading outstanding customers…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load report',
          message: e.toString(),
          onRetry: () => ref.invalidate(outstandingCustomersProvider),
        ),
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(outstandingCustomersProvider);
              await ref.read(outstandingCustomersProvider.future);
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
                  actions: [
                    ChoiceChip(
                      label: const Text('Highest balance'),
                      selected:
                          ui.outstandingSort == OutstandingSort.highestBalance,
                      onSelected: (_) => ref
                          .read(reportsUiProvider.notifier)
                          .setOutstandingSort(OutstandingSort.highestBalance),
                    ),
                    ChoiceChip(
                      label: const Text('Lowest balance'),
                      selected:
                          ui.outstandingSort == OutstandingSort.lowestBalance,
                      onSelected: (_) => ref
                          .read(reportsUiProvider.notifier)
                          .setOutstandingSort(OutstandingSort.lowestBalance),
                    ),
                  ],
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by name',
                      prefixIcon: const Icon(AppIcons.search),
                      suffixIcon: ui.outstandingQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(reportsUiProvider.notifier)
                                    .setOutstandingQuery('');
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    ),
                    onChanged: (value) => ref
                        .read(reportsUiProvider.notifier)
                        .setOutstandingQuery(value),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ReportHeader(
                  title: 'Outstanding Customers',
                  subtitle: '${items.length} customer(s) with balance due',
                ),
                const SizedBox(height: AppSpacing.md),
                if (items.isEmpty)
                  const EmptyReportWidget(
                    title: 'No outstanding balances',
                    message:
                        'All customers are settled, or no match was found.',
                    icon: AppIcons.received,
                  )
                else
                  ...items.map(
                    (customer) => OutstandingCustomerCard(
                      customer: customer,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.customerLedger,
                        arguments: customer.id,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

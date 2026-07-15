import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(outstandingCustomersProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: asyncItems.when(
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
                      ref.invalidate(outstandingCustomersProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(outstandingCustomersProvider);
              await ref.read(outstandingCustomersProvider.future);
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
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ui.outstandingQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(reportsUiProvider.notifier)
                                    .setOutstandingQuery('');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                    onChanged: (value) => ref
                        .read(reportsUiProvider.notifier)
                        .setOutstandingQuery(value),
                  ),
                ),
                const SizedBox(height: 12),
                ReportHeader(
                  title: 'Outstanding Customers',
                  subtitle: '${items.length} customer(s) with balance due',
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const EmptyReportWidget(
                    title: 'No outstanding balances',
                    message:
                        'All customers are settled, or no match was found.',
                    icon: Icons.verified_outlined,
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

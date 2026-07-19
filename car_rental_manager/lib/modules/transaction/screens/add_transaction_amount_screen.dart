import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/premium_card.dart';
import '../providers/transaction_provider.dart';
import '../repository/transaction_repository.dart';
import '../services/transaction_validation_service.dart';

/// Adds an extra amount onto an existing transaction (keeps full history).
class AddTransactionAmountScreen extends ConsumerStatefulWidget {
  const AddTransactionAmountScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  ConsumerState<AddTransactionAmountScreen> createState() =>
      _AddTransactionAmountScreenState();
}

class _AddTransactionAmountScreenState
    extends ConsumerState<AddTransactionAmountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final amount = double.parse(_amountController.text.trim());
      await ref.read(transactionListProvider.notifier).addAmount(
            transactionId: widget.transactionId,
            amount: amount,
            notes: _notesController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount added successfully')),
      );
      Navigator.of(context).pop(true);
    } on InvalidAmountAdditionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add amount: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionDetailProvider(widget.transactionId));
    final amount = double.tryParse(_amountController.text.trim());

    return Scaffold(
      appBar: AppBar(title: const Text('Add Amount')),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tx) {
          final previous = tx.totalAmount;
          final previewNew =
              amount != null && amount > 0 ? previous + amount : null;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              PremiumCard(
                child: Column(
                  children: [
                    _BalanceRow(
                      label: 'Previous Balance',
                      value: CurrencyFormatter.format(previous),
                      color: AppColors.brandBlue,
                    ),
                    const Divider(height: 20),
                    _BalanceRow(
                      label: 'Added Amount',
                      value: amount != null && amount > 0
                          ? CurrencyFormatter.format(amount)
                          : '—',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const Divider(height: 20),
                    _BalanceRow(
                      label: 'Current Total Balance',
                      value: previewNew != null
                          ? CurrencyFormatter.format(previewNew)
                          : CurrencyFormatter.format(previous),
                      color: AppColors.remaining,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${tx.customerName} · ${tx.description} · '
                '${DateFormat('dd MMM yyyy').format(tx.date)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Amount to Add *',
                          prefixIcon: Icon(AppIcons.add),
                          helperText: 'Must be greater than zero',
                        ),
                        validator:
                            TransactionValidationService.validateAddedAmount,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _notesController,
                        enabled: !_saving,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(AppIcons.notes),
                        ),
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.save),
                  label: Text(_saving ? 'Saving...' : 'Add Amount'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            )
        : Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            );

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Text(value, style: style),
      ],
    );
  }
}

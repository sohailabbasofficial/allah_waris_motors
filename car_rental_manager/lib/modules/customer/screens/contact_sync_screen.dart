import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../routes/app_routes.dart';
import '../models/matched_contact_model.dart';
import '../providers/contact_sync_provider.dart';
import '../services/contact_sync_service.dart';

/// Shows phone contacts that already exist as customers in the app.
class ContactSyncScreen extends ConsumerStatefulWidget {
  const ContactSyncScreen({super.key});

  @override
  ConsumerState<ContactSyncScreen> createState() => _ContactSyncScreenState();
}

class _ContactSyncScreenState extends ConsumerState<ContactSyncScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(contactSyncProvider.notifier).refresh();
  }

  void _openCustomer(MatchedContactModel match) {
    Navigator.of(context).pushNamed(
      AppRoutes.customerDetail,
      arguments: match.customerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(contactSyncProvider);
    final isRefreshing = asyncState.isLoading && asyncState.hasValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Sync'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing ? null : _refresh,
            icon: const Icon(AppIcons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: AppSearchField(
              controller: _searchController,
              hintText: 'Search by name or phone…',
              onChanged: (value) {
                ref.read(contactSyncProvider.notifier).setQuery(value);
                setState(() {});
              },
            ),
          ),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              child: _InfoBanner(
                text:
                    'Contact sync needs a phone/tablet. Web cannot read device contacts.',
              ),
            ),
          Expanded(
            child: asyncState.when(
              loading: () => const AppLoading(
                label: 'Syncing contacts with customers…',
              ),
              error: (e, _) => AppErrorState(
                title: 'Contact sync failed',
                message: e.toString(),
                onRetry: _refresh,
              ),
              data: (state) {
                if (state.isUnsupported || kIsWeb) {
                  return AppEmptyState(
                    icon: AppIcons.contacts,
                    title: 'Not available here',
                    message:
                        'Contact sync works on Android and iOS devices only.',
                    actionLabel: 'Go back',
                    onAction: () => Navigator.of(context).pop(),
                  );
                }

                if (state.isPermissionDenied) {
                  return AppEmptyState(
                    icon: AppIcons.security,
                    title: 'Contacts permission needed',
                    message: state.errorMessage ??
                        'Allow contacts access to find customers already saved on this phone.',
                    actionLabel: 'Try again',
                    onAction: _refresh,
                  );
                }

                if (state.errorMessage != null && state.matches.isEmpty) {
                  return AppErrorState(
                    title: 'Could not sync contacts',
                    message: state.errorMessage!,
                    onRetry: _refresh,
                  );
                }

                final items = state.filtered;
                if (state.matches.isEmpty) {
                  return AppEmptyState(
                    icon: AppIcons.contacts,
                    title: 'No matched customers',
                    message:
                        'None of your phone contacts match customers in the app. '
                        'Only existing customers are shown — nothing is created automatically.',
                    actionLabel: 'Refresh',
                    onAction: _refresh,
                  );
                }

                if (items.isEmpty) {
                  return const AppEmptyState(
                    icon: AppIcons.search,
                    title: 'No matches',
                    message: 'Try a different name or phone number.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.sm,
                      AppSpacing.pagePadding,
                      AppSpacing.xxxl,
                    ),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            '${state.matches.length} existing customer'
                            '${state.matches.length == 1 ? '' : 's'} found'
                            '${state.contactsScanned > 0 ? ' from ${state.contactsScanned} contacts' : ''}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        );
                      }

                      final match = items[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _MatchedContactTile(
                          match: match,
                          onTap: () => _openCustomer(match),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchedContactTile extends StatelessWidget {
  const _MatchedContactTile({
    required this.match,
    required this.onTap,
  });

  final MatchedContactModel match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PremiumCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Icon(AppIcons.contacts, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.contactName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.phoneNumber,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (match.contactName.toLowerCase() !=
                    match.customer.name.toLowerCase()) ...[
                  const SizedBox(height: 2),
                  Text(
                    'App: ${match.customer.name}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardGreen.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    match.statusLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.cardGreen,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Icon(AppIcons.chevron, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(text),
      ),
    );
  }
}

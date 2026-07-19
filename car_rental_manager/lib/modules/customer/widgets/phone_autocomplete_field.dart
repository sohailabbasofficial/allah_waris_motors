import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../models/device_contact_suggestion.dart';
import '../providers/contact_sync_provider.dart';
import '../services/customer_validation_service.dart';

/// Minimum digits before phone suggestions appear.
const int kPhoneSuggestionMinDigits = 3;

/// Phone field with **mobile contact** autocomplete (name + phone).
class PhoneAutocompleteField extends ConsumerStatefulWidget {
  const PhoneAutocompleteField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onContactSelected,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<DeviceContactSuggestion>? onContactSelected;
  final TextInputAction textInputAction;

  @override
  ConsumerState<PhoneAutocompleteField> createState() =>
      _PhoneAutocompleteFieldState();
}

class _PhoneAutocompleteFieldState
    extends ConsumerState<PhoneAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  String _query = '';
  List<DeviceContactSuggestion> _suggestions = const [];
  int _highlightIndex = -1;
  bool _suppressNextOpen = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
    // Warm the contacts cache (asks permission once).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceContactsCacheProvider);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _hideSuggestions();
    } else {
      _scheduleSearch(widget.controller.text);
    }
  }

  void _onTextChanged() {
    if (_suppressNextOpen) {
      _suppressNextOpen = false;
      return;
    }
    _scheduleSearch(widget.controller.text);
  }

  void _scheduleSearch(String raw) {
    _debounce?.cancel();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < kPhoneSuggestionMinDigits || !_focusNode.hasFocus) {
      _hideSuggestions();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _query = digits);
      _loadSuggestions(digits);
    });
  }

  Future<void> _loadSuggestions(String digits) async {
    final results =
        await ref.read(devicePhoneSuggestionsProvider(digits).future);
    if (!mounted || _query != digits || !_focusNode.hasFocus) return;

    setState(() {
      _suggestions = results;
      _highlightIndex = results.isEmpty ? -1 : 0;
    });

    if (results.isEmpty) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _hideSuggestions() {
    _debounce?.cancel();
    setState(() {
      _suggestions = const [];
      _highlightIndex = -1;
    });
    _removeOverlay();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? MediaQuery.sizeOf(context).width;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, (box?.size.height ?? 56) + 4),
            child: _SuggestionDropdown(
              suggestions: _suggestions,
              highlightIndex: _highlightIndex,
              onHover: (index) {
                setState(() => _highlightIndex = index);
                _overlayEntry?.markNeedsBuild();
              },
              onSelect: _selectSuggestion,
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(DeviceContactSuggestion contact) {
    _suppressNextOpen = true;
    final phone = PhoneNormalizer.normalize(contact.phone).isNotEmpty
        ? PhoneNormalizer.normalize(contact.phone)
        : contact.phone;
    widget.controller.text = phone;
    widget.controller.selection = TextSelection.collapsed(
      offset: phone.length,
    );
    widget.onContactSelected?.call(contact);
    _hideSuggestions();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowDown): () {
            if (_overlayEntry == null || _suggestions.isEmpty) return;
            setState(() {
              _highlightIndex = (_highlightIndex + 1) % _suggestions.length;
            });
            _overlayEntry?.markNeedsBuild();
          },
          const SingleActivator(LogicalKeyboardKey.arrowUp): () {
            if (_overlayEntry == null || _suggestions.isEmpty) return;
            setState(() {
              _highlightIndex = _highlightIndex <= 0
                  ? _suggestions.length - 1
                  : _highlightIndex - 1;
            });
            _overlayEntry?.markNeedsBuild();
          },
          const SingleActivator(LogicalKeyboardKey.enter): () {
            if (_highlightIndex >= 0 &&
                _highlightIndex < _suggestions.length) {
              _selectSuggestion(_suggestions[_highlightIndex]);
            }
          },
          const SingleActivator(LogicalKeyboardKey.escape): _hideSuggestions,
        },
        child: TextFormField(
          key: _fieldKey,
          controller: widget.controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Phone Number *',
            prefixIcon: Icon(AppIcons.phone),
            helperText: 'Type 3+ digits to pick from mobile contacts',
          ),
          validator: CustomerValidationService.validatePhone,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: (_) {
            if (_highlightIndex >= 0 &&
                _highlightIndex < _suggestions.length) {
              _selectSuggestion(_suggestions[_highlightIndex]);
            }
          },
        ),
      ),
    );
  }
}

class _SuggestionDropdown extends StatelessWidget {
  const _SuggestionDropdown({
    required this.suggestions,
    required this.highlightIndex,
    required this.onHover,
    required this.onSelect,
  });

  final List<DeviceContactSuggestion> suggestions;
  final int highlightIndex;
  final ValueChanged<int> onHover;
  final ValueChanged<DeviceContactSuggestion> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.32;

    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      color: colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, index) {
            final contact = suggestions[index];
            final selected = index == highlightIndex;
            return InkWell(
              onTap: () => onSelect(contact),
              onHover: (_) => onHover(index),
              child: ColoredBox(
                color: selected
                    ? colorScheme.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.12),
                        child: Icon(
                          AppIcons.contacts,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              contact.phone,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.north_west_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

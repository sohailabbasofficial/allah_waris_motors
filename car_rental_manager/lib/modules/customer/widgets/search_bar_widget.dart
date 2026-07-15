import 'package:flutter/material.dart';

import '../../../core/widgets/app_search_field.dart';

/// Rounded search field for filtering customers.
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search by name or phone',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      controller: controller,
      onChanged: onChanged,
      hintText: hintText,
    );
  }
}

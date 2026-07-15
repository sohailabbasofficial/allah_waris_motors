import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumps when local business data changes so Drive sync can run.
final dataChangeBusProvider =
    NotifierProvider<DataChangeBus, int>(DataChangeBus.new);

class DataChangeBus extends Notifier<int> {
  @override
  int build() => 0;

  void markDirty() => state = state + 1;
}

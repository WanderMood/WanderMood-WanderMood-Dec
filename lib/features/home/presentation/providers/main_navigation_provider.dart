import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom tabs: 0 My Day, 1 Explore, 2 Moody, 3 Agenda, 4 Profile.
final mainTabProvider = StateProvider<int>((ref) => 0);

int normalizeMainTabIndex(int tab) {
  if (tab < 0) return 0;
  if (tab > 4) return 4;
  return tab;
}

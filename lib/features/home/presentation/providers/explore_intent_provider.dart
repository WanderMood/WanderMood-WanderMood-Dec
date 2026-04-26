import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot handoff from Moody surfaces to Explore search.
/// Explore consumes and clears this intent after applying it.
final exploreSearchIntentProvider = StateProvider<String?>((ref) => null);


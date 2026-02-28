import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/gyg_link.dart';
import '../services/gyg_links_service.dart';
import '../../../core/providers/supabase_provider.dart';

final gygLinksServiceProvider = Provider<GygLinksService>((ref) {
  return GygLinksService(ref.watch(supabaseClientProvider));
});

/// Fetches GYG links for the given destination (city).
/// Watches location; use ref.watch(gygLinksProvider(destination)) with
/// destination from locationNotifierProvider.
final gygLinksProvider =
    FutureProvider.family<List<GygLink>, String>((ref, destination) async {
  final service = ref.watch(gygLinksServiceProvider);
  return service.fetchLinks(destination);
});

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/places/models/place.dart';

/// Full list for "See all" trending — uses cached explore [Place]s only (photos are URLs).
class AllTrendingDestinationsScreen extends StatelessWidget {
  const AllTrendingDestinationsScreen({
    super.key,
    required this.destinations,
  });

  final List<Place> destinations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trending near you',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: destinations.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = destinations[i];
          final url = p.photos.isNotEmpty ? p.photos.first : null;
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: url != null
                  ? Image.network(
                      url,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.place),
                      ),
                    )
                  : const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(Icons.place),
                    ),
            ),
            title: Text(
              p.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              p.types.isNotEmpty
                  ? '${p.types.first.replaceAll('_', ' ')} · ★ ${p.rating.toStringAsFixed(1)}'
                  : '★ ${p.rating.toStringAsFixed(1)}',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Badge to indicate data source (real API data vs mock/estimated)
enum DataSource {
  real,      // From Google Places API or other real source
  estimated, // Estimated/calculated value
  mock,      // Sample/mock data for demonstration
}

class DataSourceBadge extends StatelessWidget {
  final DataSource source;
  final String? tooltip;
  final double size;

  const DataSourceBadge({
    Key? key,
    required this.source,
    this.tooltip,
    this.size = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData icon;
    String label;

    switch (source) {
      case DataSource.real:
        badgeColor = Colors.green.shade100;
        icon = Icons.verified;
        label = 'Real';
        break;
      case DataSource.estimated:
        badgeColor = Colors.orange.shade100;
        icon = Icons.auto_awesome;
        label = 'Est.';
        break;
      case DataSource.mock:
        badgeColor = Colors.grey.shade200;
        icon = Icons.info_outline;
        label = 'Sample';
        break;
    }

    return Tooltip(
      message: tooltip ?? _getDefaultTooltip(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: badgeColor.darken(0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: size, color: badgeColor.darken(0.6)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: size - 2,
                fontWeight: FontWeight.w500,
                color: badgeColor.darken(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultTooltip() {
    switch (source) {
      case DataSource.real:
        return 'Data from Google Places API';
      case DataSource.estimated:
        return 'Estimated value based on place type';
      case DataSource.mock:
        return 'Sample data for demonstration';
    }
  }
}

extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}


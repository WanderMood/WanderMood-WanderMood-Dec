import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/weather_alert.dart';

class WeatherAlertCard extends StatelessWidget {
  final WeatherAlert alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const WeatherAlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onDismiss,
  });

  Color _getSeverityColor() {
    switch (alert.severity.toLowerCase()) {
      case 'extreme':
        return Colors.red;
      case 'severe':
        return Colors.orange;
      case 'moderate':
        return Colors.yellow;
      default:
        return Colors.blue;
    }
  }

  IconData _getAlertIcon() {
    switch (alert.type.toLowerCase()) {
      case 'storm':
        return Icons.flash_on;
      case 'rain':
        return Icons.beach_access;
      case 'wind':
        return Icons.air;
      case 'heat':
        return Icons.wb_sunny;
      case 'cold':
        return Icons.ac_unit;
      default:
        return Icons.warning;
    }
  }
  
  Color _getAlertIconColor() {
    switch (alert.type.toLowerCase()) {
      case 'heat':
        return const Color(0xFFFFD700); // Yellow sun for heat
      default:
        return _getSeverityColor();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        if (onDismiss != null) onDismiss!();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getSeverityColor().withOpacity(0.2),
                  child: Icon(_getAlertIcon(), color: _getAlertIconColor()),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${alert.description.substring(0, alert.description.length > 100 ? 100 : alert.description.length)}${alert.description.length > 100 ? '...' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Valid until: ${DateFormat('dd MMM, HH:mm').format(alert.end)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
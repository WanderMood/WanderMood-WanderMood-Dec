import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';

class MyDayWeatherDialog extends StatelessWidget {
  final WeatherData? weather;

  const MyDayWeatherDialog({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFFFFFFF),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weather in Rotterdam',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1C18),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF8A847B)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (weather != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _weatherIcon(weather!.condition),
                    size: 64,
                    color: _weatherColor(weather!.condition),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather!.temperature.round()}°C',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E1C18),
                        ),
                      ),
                      Text(
                        weather!.condition,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: const Color(0xFF8A847B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD8D0C4), width: 0.5),
                ),
                child: Column(
                  children: [
                    _WeatherDetailRow(
                      label: 'Feels Like',
                      value: '${weather!.details['feelsLike']?.round() ?? '--'}°C',
                    ),
                    const Divider(height: 16, thickness: 1, color: Color(0xFFD8D0C4)),
                    _WeatherDetailRow(
                      label: 'Humidity',
                      value: '${weather!.details['humidity'] ?? '--'}%',
                    ),
                    const Divider(height: 16, thickness: 1, color: Color(0xFFD8D0C4)),
                    _WeatherDetailRow(
                      label: 'Description',
                      value: weather!.details['description'] ?? 'Clear skies',
                    ),
                  ],
                ),
              ),
            ] else ...[
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Weather data unavailable',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Please check your internet connection',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A6049),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _weatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'mist':
      case 'fog':
        return Icons.blur_on;
      default:
        return Icons.wb_sunny;
    }
  }

  Color _weatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'clouds':
        return Colors.grey.shade600;
      case 'rain':
        return Colors.blue;
      case 'snow':
        return Colors.lightBlue;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'mist':
      case 'fog':
        return Colors.grey.shade500;
      default:
        return Colors.orange;
    }
  }
}

class _WeatherDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _WeatherDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF4A4640),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xFF1E1C18),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

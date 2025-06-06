import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';

class CompactWeatherWidget extends ConsumerWidget {
  const CompactWeatherWidget({super.key});

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return const Color(0xFFFFD700);
      case 'clouds':
        return Colors.grey;
      case 'rain':
        return Colors.blueGrey;
      default:
        return const Color(0xFFFFD700);
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.beach_access;
      default:
        return Icons.wb_sunny;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return weatherAsync.when(
      data: (weather) => weather != null ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
              color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getWeatherIcon(weather.condition),
              color: _getWeatherColor(weather.condition),
              size: 20,
            ),
                      const SizedBox(width: 8),
                      Text(
              '${weather.temperature.round()}°',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _getWeatherColor(weather.condition),
              ),
            ),
          ],
        ),
      ) : const SizedBox(),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Icon(Icons.error),
    );
  }
} 
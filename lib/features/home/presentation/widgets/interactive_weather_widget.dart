import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/weather_provider.dart';
import '../../../weather/domain/models/weather.dart';

class InteractiveWeatherWidget extends ConsumerStatefulWidget {
  const InteractiveWeatherWidget({super.key});

  @override
  ConsumerState<InteractiveWeatherWidget> createState() => _InteractiveWeatherWidgetState();
}

class _InteractiveWeatherWidgetState extends ConsumerState<InteractiveWeatherWidget> {
  bool _isDetailExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currentWeather = ref.watch(weatherProvider);
    final hourlyForecast = ref.watch(hourlyForecastProvider);
    final dailyForecast = ref.watch(dailyForecastProvider);

    return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Current Weather
          currentWeather.when(
            data: (weather) => _buildCurrentWeather(weather),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Failed to load weather')),
            ),

          // Hourly Forecast
          if (_isDetailExpanded) ...[
            const Divider(),
            hourlyForecast.when(
              data: (forecast) => _buildHourlyForecast(forecast),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load forecast')),
            ),

            // Daily Forecast
            const Divider(),
            dailyForecast.when(
              data: (forecast) => _buildDailyForecast(forecast),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Failed to load forecast')),
            ),
          ],

          // Expand/Collapse Button
          InkWell(
            onTap: () => setState(() => _isDetailExpanded = !_isDetailExpanded),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isDetailExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isDetailExpanded ? 'Show Less' : 'Show More',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather(Weather? weather) {
    if (weather == null) {
      return const Center(child: Text('No weather data available'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
                child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                '${weather.temperature.round()}°',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                weather.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
          Icon(
            _getWeatherIcon(weather.description),
            size: 48,
            color: _getWeatherColor(weather.description),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(List<Weather> forecast) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: forecast.length,
        itemBuilder: (context, index) {
          final hourlyWeather = forecast[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                Text(
                  '${hourlyWeather.dateTime.hour}:00',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Icon(
                  _getWeatherIcon(hourlyWeather.description),
                  size: 24,
                  color: _getWeatherColor(hourlyWeather.description),
                          ),
                const SizedBox(height: 4),
                Text(
                  '${hourlyWeather.temperature.round()}°',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyForecast(List<Weather> forecast) {
    return Column(
      children: forecast.map((weather) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                _getDayName(weather.dateTime),
                style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                    _getWeatherIcon(weather.description),
                    size: 20,
                    color: _getWeatherColor(weather.description),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                    '${weather.temperature.round()}°',
                    style: GoogleFonts.poppins(fontSize: 14),
                                      ),
                ],
                                    ),
                                  ],
                                ),
        );
      }).toList(),
    );
  }

  IconData _getWeatherIcon(String description) {
    description = description.toLowerCase();
    if (description.contains('clear') || description.contains('sunny')) {
      return Icons.wb_sunny;
    } else if (description.contains('cloud')) {
      return Icons.cloud;
    } else if (description.contains('rain')) {
      return Icons.beach_access;
    } else if (description.contains('storm')) {
      return Icons.thunderstorm;
    } else if (description.contains('snow')) {
      return Icons.ac_unit;
    } else {
      return Icons.wb_sunny_outlined;
    }
  }

  Color _getWeatherColor(String description) {
    description = description.toLowerCase();
    if (description.contains('clear') || description.contains('sunny')) {
      return Colors.orange;
    } else if (description.contains('cloud')) {
      return Colors.grey;
    } else if (description.contains('rain')) {
      return Colors.blue;
    } else if (description.contains('storm')) {
      return Colors.blueGrey;
    } else if (description.contains('snow')) {
      return Colors.lightBlue;
    } else {
      return Colors.orange;
    }
  }

  String _getDayName(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    }
  }
} 
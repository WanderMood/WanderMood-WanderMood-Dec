import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wandermood/features/home/providers/weather_provider.dart';
import 'package:wandermood/features/weather/domain/models/weather.dart';
import 'package:wandermood/features/weather/domain/models/weather_forecast.dart';
import 'package:wandermood/l10n/app_localizations.dart';

class InteractiveWeatherWidget extends ConsumerStatefulWidget {
  const InteractiveWeatherWidget({super.key});

  @override
  ConsumerState<InteractiveWeatherWidget> createState() => _InteractiveWeatherWidgetState();
}

class _InteractiveWeatherWidgetState extends ConsumerState<InteractiveWeatherWidget> {
  bool _isDetailExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            data: (weather) => _buildCurrentWeather(context, weather),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: Text(l10n.weatherFailedLoadCurrent)),
            ),

          // Hourly Forecast
          if (_isDetailExpanded) ...[
            const Divider(),
            hourlyForecast.when(
              data: (forecast) => _buildHourlyForecast(forecast),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(l10n.weatherFailedLoadForecast)),
            ),

            // Daily Forecast
            const Divider(),
            dailyForecast.when(
              data: (forecast) => _buildDailyForecast(forecast),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(l10n.weatherFailedLoadForecast)),
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
                    _isDetailExpanded ? l10n.weatherShowLess : l10n.weatherShowMore,
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

  Widget _buildCurrentWeather(BuildContext context, Weather? weather) {
    final l10n = AppLocalizations.of(context)!;
    if (weather == null) {
      return Center(child: Text(l10n.weatherNoDataAvailable));
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
                weather.description ?? weather.condition,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
          Icon(
            _getWeatherIcon(weather.description ?? weather.condition),
            size: 48,
            color: _getWeatherColor(weather.description ?? weather.condition),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast(List<WeatherForecast> forecast) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: forecast.length,
        itemBuilder: (context, index) {
          final hourlyWeather = forecast[index];
          final label = hourlyWeather.time ??
              '${hourlyWeather.date.hour.toString().padLeft(2, '0')}:00';
          final desc =
              hourlyWeather.description ?? hourlyWeather.conditions;
          final temp = hourlyWeather.temperature ??
              (hourlyWeather.maxTemperature + hourlyWeather.minTemperature) /
                  2.0;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Icon(
                  _getWeatherIcon(desc),
                  size: 24,
                  color: _getWeatherColor(desc),
                          ),
                const SizedBox(height: 4),
                Text(
                  '${temp.round()}°',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyForecast(List<WeatherForecast> forecast) {
    return Column(
      children: forecast.map((row) {
        final desc = row.description ?? row.conditions;
        final temp = row.temperature ??
            (row.maxTemperature + row.minTemperature) / 2.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                _getDayName(row.date),
                style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                    _getWeatherIcon(desc),
                    size: 20,
                    color: _getWeatherColor(desc),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                    '${temp.round()}°',
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
    final now = MoodyClock.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    }
  }
} 
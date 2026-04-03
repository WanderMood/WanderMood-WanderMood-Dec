import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../domain/models/weather_forecast.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';

class WeatherForecastCard extends StatelessWidget {
  final WeatherForecast forecast;
  final VoidCallback? onTap;

  const WeatherForecastCard({
    super.key,
    required this.forecast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMMM').format(forecast.date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        forecast.conditions,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  if (forecast.icon != null)
                    WmNetworkImage(
                      'https://openweathermap.org/img/wn/${forecast.icon}@2x.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.cloud,
                        size: 48,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WeatherDetail(
                    icon: Icons.thermostat,
                    label: 'Max/Min',
                    value: '${forecast.maxTemperature.round()}°/${forecast.minTemperature.round()}°',
                  ),
                  _WeatherDetail(
                    icon: Icons.water_drop,
                    label: 'Vochtigheid',
                    value: '${forecast.humidity}%',
                  ),
                  _WeatherDetail(
                    icon: Icons.umbrella,
                    label: 'Neerslag',
                    value: '${forecast.precipitation} mm',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WeatherDetail(
                    icon: Icons.wb_sunny,
                    label: 'Zonsopgang',
                    value: DateFormat('HH:mm').format(forecast.sunrise),
                  ),
                  _WeatherDetail(
                    icon: Icons.nightlight,
                    label: 'Zonsondergang',
                    value: DateFormat('HH:mm').format(forecast.sunset),
                  ),
                  _WeatherDetail(
                    icon: Icons.wb_twilight,
                    label: 'UV Index',
                    value: forecast.uvIndex.toStringAsFixed(1),
                  ),
                ],
              ),
              if (forecast.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  forecast.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
} 
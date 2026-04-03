import 'package:flutter/material.dart';
import '../../domain/models/weather_data.dart';
import 'package:wandermood/core/presentation/widgets/wm_network_image.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData weather;
  final VoidCallback? onTap;

  const WeatherCard({
    super.key,
    required this.weather,
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
                        '${weather.temperature.round()}°C',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weather.conditions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  if (weather.icon != null)
                    WmNetworkImage(
                      'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.cloud,
                        size: 64,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WeatherDetail(
                    icon: Icons.water_drop,
                    label: 'Vochtigheid',
                    value: '${weather.humidity}%',
                  ),
                  _WeatherDetail(
                    icon: Icons.air,
                    label: 'Wind',
                    value: '${weather.windSpeed} m/s',
                  ),
                  _WeatherDetail(
                    icon: Icons.umbrella,
                    label: 'Neerslag',
                    value: '${weather.precipitation} mm',
                  ),
                ],
              ),
              if (weather.description != null) ...[
                const SizedBox(height: 16),
                Text(
                  weather.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
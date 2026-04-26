import 'package:flutter/material.dart';
import 'package:wandermood/features/weather/presentation/widgets/hourly_weather_widget.dart';

class CompactWeatherWidget extends StatelessWidget {
  final Function(String)? onViewChanged;
  final List<HourlyWeather> hourlyData;
  final String location;
  final int currentTemperature;
  
  const CompactWeatherWidget({
    Key? key,
    this.onViewChanged,
    this.location = 'Washington DC',
    this.currentTemperature = 29,
    this.hourlyData = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFB7E9F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location and current temperature
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$location, $currentTemperature°',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(Icons.wb_sunny, color: Colors.amber[600], size: 20),
            ],
          ),

          const SizedBox(height: 12),

          // Hourly forecast
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: hourlyData.length,
              itemBuilder: (context, index) {
                final hour = hourlyData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Text(
                        hour.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.wb_sunny,
                        color: Colors.amber[600],
                        size: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hour.temperature}°',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 
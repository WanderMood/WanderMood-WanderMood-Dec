import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HourlyWeather {
  final String time;
  final int temperature;

  const HourlyWeather({
    required this.time,
    required this.temperature,
  });
}

class HourlyWeatherWidget extends StatefulWidget {
  final String location;
  final List<HourlyWeather> hourlyWeather;
  final String windSpeed;
  final int uvIndex;
  final String sunriseTime;
  final String sunsetTime;
  final int aqi;

  const HourlyWeatherWidget({
    Key? key,
    required this.location,
    required this.hourlyWeather,
    required this.windSpeed,
    required this.uvIndex,
    required this.sunriseTime,
    required this.sunsetTime,
    required this.aqi,
  }) : super(key: key);

  @override
  State<HourlyWeatherWidget> createState() => _HourlyWeatherWidgetState();
}

class _HourlyWeatherWidgetState extends State<HourlyWeatherWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFB0D4F7),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.location,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A4A24),
                  ),
                ),
                const Icon(
                  Icons.wb_sunny,
                  color: Color(0xFFF9C21B),
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(24, (index) {
                  final hour = DateTime.now().add(Duration(hours: index));
                  final isDaytime = hour.hour >= 6 && hour.hour < 20;
                  final weatherEmoji = isDaytime ? '☀️' : '🌙';
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          index == 0 ? 'Now' : '${hour.hour}:00',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            color: const Color(0xFF1A4A24),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weatherEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${25 + (index % 5)}°',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A4A24),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Icon(
                _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFF1A4A24),
                size: 24,
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF1A4A24), thickness: 0.5),
              const SizedBox(height: 20),
              // Weather details section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem('Wind', widget.windSpeed),
                  _buildDetailItem('UV Index', '${widget.uvIndex}'),
                  _buildDetailItem('AQI', '${widget.aqi}'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem('Sunrise', widget.sunriseTime),
                  _buildDetailItem('Sunset', widget.sunsetTime),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF1A4A24), thickness: 0.5),
              const SizedBox(height: 20),
              // 3-day forecast section
              Text(
                '3-Day Forecast',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A4A24),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _buildDayForecast('Today', '32°', '25°', '☀️', 'Sunny'),
                  const SizedBox(height: 12),
                  _buildDayForecast('Tomorrow', '30°', '24°', '🌤️', 'Partly Cloudy'),
                  const SizedBox(height: 12),
                  _buildDayForecast('Saturday', '29°', '23°', '🌦️', 'Light Rain'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A4A24),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: const Color(0xFF1A4A24),
          ),
        ),
      ],
    );
  }

  Widget _buildDayForecast(String day, String highTemp, String lowTemp, String emoji, String condition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day,
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A4A24),
              ),
            ),
          ),
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          SizedBox(
            width: 100,
            child: Text(
              condition,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: const Color(0xFF1A4A24),
              ),
            ),
          ),
          Row(
            children: [
              Text(
                highTemp,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A4A24),
                ),
              ),
              Text(
                ' / ',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: const Color(0xFF1A4A24),
                ),
              ),
              Text(
                lowTemp,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: const Color(0xFF1A4A24),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 
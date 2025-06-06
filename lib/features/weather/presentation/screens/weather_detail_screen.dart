import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/weather/domain/models/weather_forecast.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/weather/providers/weather_forecast_provider.dart';

class WeatherDetailScreen extends ConsumerWidget {
  final bool isModal;
  
  const WeatherDetailScreen({
    Key? key, 
    this.isModal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationNotifierProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final hourlyForecastAsync = ref.watch(hourlyForecastProvider);
    final dailyForecastAsync = ref.watch(dailyForecastProvider);

    final body = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD1E9DE), // Mint green background
      ),
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: false,
              pinned: isModal ? false : true,
              expandedHeight: isModal ? 80 : 120,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  location.when(
                    data: (data) => data ?? 'Weather',
                    loading: () => 'Loading...',
                    error: (_, __) => 'Weather',
                  ),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF5F7A73), // Dark mint text
                    fontWeight: FontWeight.w600,
                    fontSize: isModal ? 20 : 16,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFD1E9DE), // Mint green
                        const Color(0xFFD1E9DE).withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              leading: isModal 
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF5F7A73)),
                    onPressed: () => Navigator.pop(context),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF5F7A73)),
                    onPressed: () => Navigator.pop(context),
                  ),
            ),
            
            // Current Weather Section
            SliverToBoxAdapter(
              child: weatherAsync.when(
                data: (weather) => _buildCurrentWeather(context, weather),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Color(0xFF5F7A73)),
                  )
                ),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Text(
                      'Failed to load weather data',
                      style: GoogleFonts.poppins(color: const Color(0xFF5F7A73)),
                    ),
                  ),
                ),
              ),
            ),
            
            // Hourly Forecast Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '24-Hour Forecast',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5F7A73),
                      ),
                    ),
                    const SizedBox(height: 12),
                    hourlyForecastAsync.when(
                      data: (forecasts) => _buildHourlyForecast(context, forecasts),
                      loading: () => const Center(
                        child: SizedBox(
                          height: 100,
                          child: CircularProgressIndicator(color: Color(0xFF5F7A73)),
                        ),
                      ),
                      error: (_, __) => _buildMockHourlyForecast(),
                    ),
                  ],
                ),
              ),
            ),
            
            // 3-Day Forecast Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3-Day Forecast',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5F7A73),
                      ),
                    ),
                    const SizedBox(height: 12),
                    dailyForecastAsync.when(
                      data: (forecasts) => _buildDailyForecast(context, forecasts),
                      loading: () => const Center(
                        child: SizedBox(
                          height: 150,
                          child: CircularProgressIndicator(color: Color(0xFF5F7A73)),
                        ),
                      ),
                      error: (_, __) => _buildMockDailyForecast(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
    
    if (isModal) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: body,
      );
    }
    
    return Scaffold(body: body);
  }
  
  Widget _buildCurrentWeather(BuildContext context, WeatherData? weather) {
    if (weather == null) return const SizedBox.shrink();
    
    // Extract icon code from the iconUrl
    final iconCode = weather.iconUrl.split('/').last.replaceAll('@2x.png', '');
    final isDay = iconCode.contains('d');
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}°',
                    style: GoogleFonts.poppins(
                      fontSize: 64,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5F7A73),
                    ),
                  ),
                  Text(
                    weather.condition,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5F7A73),
                    ),
                  ),
                  if (weather.details.containsKey('description'))
                    Text(
                      weather.details['description'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF5F7A73).withOpacity(0.9),
                      ),
                    ),
                ],
              ),
              SizedBox(
                width: 120,
                height: 120,
                child: _getWeatherIcon(
                  weather.condition, 
                  iconCode, 
                  100, 
                  isMain: true
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherInfoItem(
                icon: Icons.thermostat_outlined,
                value: 'Feels like ${(weather.details['feelsLike'] as num).round()}°',
              ),
              _buildWeatherInfoItem(
                icon: Icons.water_drop_outlined,
                value: '${weather.details['humidity']}%',
              ),
              _buildWeatherInfoItem(
                icon: Icons.air_outlined,
                value: '${(weather.details['windSpeed'] as num).round()} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeatherInfoItem({required IconData icon, required String value}) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF5F7A73), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5F7A73),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHourlyForecast(BuildContext context, List<WeatherForecast> forecasts) {
    if (forecasts.isEmpty) {
      return _buildMockHourlyForecast();
    }
    
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: forecasts.length,
        itemBuilder: (context, index) {
          final forecast = forecasts[index];
          final hour = int.tryParse(forecast.time?.split(' ')[0] ?? '12') ?? 12;
          final isPM = forecast.time?.contains('PM') ?? false;
          final actualHour = isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);
          final isDay = actualHour >= 6 && actualHour < 18;
          
          return Container(
            width: 85,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    forecast.time ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5F7A73),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 45,
                  height: 45,
                  child: _getWeatherIcon(
                    forecast.conditions, 
                    isDay ? 'day' : 'night',
                    40,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${forecast.temperature?.round() ?? 0}°',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5F7A73),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_outlined, 
                      size: 12, 
                      color: const Color(0xFF5F7A73).withOpacity(0.8),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${forecast.precipitationProbability.round()}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF5F7A73).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMockHourlyForecast() {
    final now = DateTime.now();
    final currentHour = now.hour;
    
    // Create a list of forecast data points for each hour
    final List<Map<String, dynamic>> forecasts = [];
    
    // Generate 24 hourly forecasts
    for (int i = 0; i < 24; i++) {
      final hour = (currentHour + i) % 24;
      final formattedHour = hour == 0 ? '12 AM' : hour == 12 ? '12 PM' : hour > 12 ? '${hour - 12} PM' : '$hour AM';
      
      // Create more realistic temperature patterns
      double temp;
      if (hour >= 6 && hour <= 14) {
        // Morning to afternoon - warming up
        temp = 15 + (hour - 6) * 0.8;
      } else if (hour > 14 && hour <= 20) {
        // Afternoon to evening - cooling down
        temp = 21 - (hour - 14) * 0.7;
      } else {
        // Night - cooler
        temp = 15;
      }
      
      // Vary the conditions based on time of day
      String condition;
      String icon;
      int precipitation;
      
      if (hour >= 6 && hour <= 9) {
        // Early morning
        condition = 'Clear';
        icon = '01d'; // Clear day
        precipitation = 10;
      } else if (hour > 9 && hour <= 15) {
        // Mid-day
        condition = i % 2 == 0 ? 'Clouds' : 'Clear';
        icon = i % 2 == 0 ? '03d' : '01d'; // Scattered clouds or clear
        precipitation = i % 3 == 0 ? 20 : 10;
      } else if (hour > 15 && hour <= 19) {
        // Evening
        condition = i % 2 == 0 ? 'Clouds' : 'Clear';
        icon = i % 2 == 0 ? '04d' : '01d'; // Broken clouds or clear
        precipitation = i % 2 == 0 ? 30 : 20;
      } else {
        // Night
        condition = i % 3 == 0 ? 'Clouds' : 'Clear';
        icon = i % 3 == 0 ? '04n' : '01n'; // Broken clouds or clear night
        precipitation = 10;
      }
      
      forecasts.add({
        'time': formattedHour,
        'temp': temp.round(),
        'icon': icon,
        'condition': condition,
        'precipitation': precipitation,
      });
    }
    
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: forecasts.length,
        itemBuilder: (context, index) {
          final forecast = forecasts[index];
          
          return Container(
            width: 85,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    forecast['time'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5F7A73),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 45,
                  height: 45,
                  child: _getWeatherIcon(
                    forecast['condition'] as String,
                    forecast['icon'] as String,
                    40,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${forecast['temp']}°',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5F7A73),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 12,
                      color: const Color(0xFF5F7A73).withOpacity(0.8),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${forecast['precipitation']}%',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF5F7A73).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDailyForecast(BuildContext context, List<WeatherForecast> forecasts) {
    if (forecasts.isEmpty) {
      return _buildMockDailyForecast();
    }
    
    return Column(
      children: forecasts.map((forecast) => _buildDailyForecastItem(forecast)).toList(),
    );
  }
  
  Widget _buildMockDailyForecast() {
    final now = DateTime.now();
    final days = [
      {
        'day': _getDayOfWeek((now.weekday + 1) % 7),
        'min': 12,
        'max': 18,
        'condition': 'Clouds',
      },
      {
        'day': _getDayOfWeek((now.weekday + 2) % 7),
        'min': 14,
        'max': 20,
        'condition': 'Clear', // Sunny day
      },
      {
        'day': _getDayOfWeek((now.weekday + 3) % 7),
        'min': 13,
        'max': 19,
        'condition': 'Rain',
      },
    ];
    
    return Column(
      children: days.map((day) => _buildMockDailyForecastItem(day)).toList(),
    );
  }
  
  Widget _buildDailyForecastItem(WeatherForecast forecast) {
    final isSunny = forecast.conditions.toLowerCase().contains('clear') || 
                    forecast.conditions.toLowerCase().contains('sun');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              forecast.time ?? '',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5F7A73),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            height: 50,
            child: _getWeatherIcon(forecast.conditions, 'day', 45),
          ),
          Row(
            children: [
              Text(
                '${forecast.minTemperature.round()}° ',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF5F7A73).withOpacity(0.8),
                ),
              ),
              Text(
                '${forecast.maxTemperature.round()}°',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5F7A73),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMockDailyForecastItem(Map<String, dynamic> day) {
    final isSunny = (day['condition'] as String).toLowerCase().contains('clear');
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              day['day'] as String,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5F7A73),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            height: 50,
            child: isSunny 
              ? Icon(
                  Icons.wb_sunny,
                  color: const Color(0xFFFFD700),
                  size: 45,
                )
              : _getWeatherIcon(day['condition'] as String, 'day', 45),
          ),
          Row(
            children: [
              Text(
                '${day['min']}° ',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF5F7A73).withOpacity(0.8),
                ),
              ),
              Text(
                '${day['max']}°',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5F7A73),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Weather icon method that uses custom images for different weather conditions
  Widget _getWeatherIcon(String condition, String dayOrNight, double size, {bool isMain = false}) {
    final lowercaseCondition = condition.toLowerCase();
    final isDay = dayOrNight.contains('d') || dayOrNight == 'day';
    bool isSunny = false;
    String assetPath = 'assets/images/weather_icons/';
    
    // Special case for the sun/clear conditions to be yellow
    if ((lowercaseCondition.contains('clear') || lowercaseCondition.contains('sun')) && 
        (isDay || dayOrNight == 'day')) {
      return Icon(
        Icons.wb_sunny,
        color: const Color(0xFFFFD700),
        size: isMain ? size * 1.2 : size,
      );
    }
    
    // Map condition to appropriate asset
    if (lowercaseCondition.contains('clear') || lowercaseCondition.contains('sun')) {
      if (isDay) {
        isSunny = true;
        assetPath += 'sunny.png';
      } else {
        assetPath += 'clear_night.png';
      }
    } else if (lowercaseCondition.contains('scattered cloud') || 
               lowercaseCondition.contains('few cloud') || 
               lowercaseCondition.contains('partly cloud')) {
      assetPath += isDay ? 'partly_cloudy.png' : 'partly_cloudy_night.png';
    } else if (lowercaseCondition.contains('cloud')) {
      assetPath += 'cloudy.png';
    } else if (lowercaseCondition.contains('shower') || lowercaseCondition.contains('drizzle')) {
      assetPath += 'light_rain.png';
    } else if (lowercaseCondition.contains('rain')) {
      assetPath += 'rain.png';
    } else if (lowercaseCondition.contains('thunder') || lowercaseCondition.contains('storm')) {
      assetPath += 'thunderstorm.png';
    } else if (lowercaseCondition.contains('snow')) {
      assetPath += 'snow.png';
    } else if (lowercaseCondition.contains('mist') || lowercaseCondition.contains('fog')) {
      assetPath += 'fog.png';
    } else if (lowercaseCondition.contains('wind')) {
      assetPath += 'windy.png';
    } else {
      // Default fallback
      if (isDay) {
        isSunny = true;
        assetPath += 'sunny.png';
      } else {
        assetPath += 'clear_night.png';
      }
    }

    // Handle asset loading with fallback to simple icons if assets are missing
    if (isSunny) {
      return Icon(
        Icons.wb_sunny,
        color: const Color(0xFFFFD700),
        size: isMain ? size * 1.2 : size,
      );
    }
    
    return Image.asset(
      assetPath,
      width: isMain ? size * 1.2 : size,
      height: isMain ? size * 1.2 : size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to simpler icons if the asset is missing
        return _getFallbackIcon(condition, dayOrNight, size, isMain: isMain);
      },
    );
  }
  
  // Fallback method that uses Flutter icons when assets aren't available
  Widget _getFallbackIcon(String condition, String dayOrNight, double size, {bool isMain = false}) {
    final lowercaseCondition = condition.toLowerCase();
    final actualSize = isMain ? size * 1.2 : size * 1.1;
    
    if (lowercaseCondition.contains('scattered cloud') || 
        lowercaseCondition.contains('few cloud') || 
        lowercaseCondition.contains('partly cloud') ||
        lowercaseCondition.contains('cloud')) {
      return Icon(
        Icons.cloud, 
        color: Colors.white,
        size: actualSize,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      );
    } else if (lowercaseCondition.contains('clear') || lowercaseCondition.contains('sun')) {
      if (dayOrNight.contains('d') || dayOrNight == 'day') {
        return Icon(Icons.wb_sunny_outlined, color: const Color(0xFFFFD700), size: actualSize);
      } else {
        return Icon(Icons.nightlight_round, color: Colors.white.withOpacity(0.9), size: actualSize);
      }
    } else if (lowercaseCondition.contains('rain') || lowercaseCondition.contains('shower')) {
      return Icon(
        Icons.grain,
        color: Colors.white, 
        size: actualSize,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      );
    } else if (lowercaseCondition.contains('thunder') || lowercaseCondition.contains('storm')) {
      return Icon(Icons.flash_on, color: const Color(0xFFFFD700), size: actualSize);
    } else if (lowercaseCondition.contains('snow')) {
      return Icon(
        Icons.ac_unit,
        color: Colors.white, 
        size: actualSize,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      );
    } else if (lowercaseCondition.contains('mist') || lowercaseCondition.contains('fog')) {
      return Icon(Icons.blur_on, color: Colors.white.withOpacity(0.9), size: actualSize);
    } else {
      // Default case
      if (dayOrNight.contains('d') || dayOrNight == 'day') {
        return Icon(Icons.wb_sunny_outlined, color: const Color(0xFFFFD700), size: actualSize);
      } else {
        return Icon(Icons.nightlight_round, color: Colors.white.withOpacity(0.9), size: actualSize);
      }
    }
  }
  
  String _getDayOfWeek(int day) {
    switch (day) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 0:
      case 7: return 'Sunday';
      default: return '';
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:wandermood/core/domain/providers/location_notifier_provider.dart';
import 'package:wandermood/features/weather/domain/models/weather_forecast.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/features/weather/providers/weather_forecast_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

// WanderMood v2 — iOS-weather-inspired palette for cleaner, modern weather UI.
const Color _wmModalCharcoal = Color(0xFF1E1C18);
const Color _wmHubCream = Color(0xFFF5F0E8);
const Color _wmHubForest = Color(0xFF2A6049);
const Color _wmHubForestTint = Color(0xFFEBF3EE);
const Color _wmHubInkMuted = Color(0xFF5C574E);
const Color _weatherMintBg = Color(0xFFE8F1FF);
const Color _weatherMintText = Color(0xFF2F4E7A);
const Color _weatherSkyTop = Color(0xFFCCE0FF);
const Color _weatherSkyBottom = Color(0xFFF2F7FF);

DateTime _wmStartOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

String _wmLocaleTag(BuildContext context) =>
    Localizations.localeOf(context).toString();

/// Modal: short weekday (fits narrow dialog). Full screen: API label or full name.
String _wmDailyDayLabel(
  BuildContext context,
  WeatherForecast forecast, {
  required bool isModal,
}) {
  final d = _wmStartOfDay(forecast.date);
  final loc = _wmLocaleTag(context);
  if (isModal) return DateFormat.E(loc).format(d);
  final t = forecast.time?.trim();
  if (t != null && t.isNotEmpty) return t;
  return DateFormat.EEEE(loc).format(d);
}

String _wmMockDailyLabel(
  BuildContext context,
  DateTime date, {
  required bool isModal,
}) {
  final loc = _wmLocaleTag(context);
  final d = _wmStartOfDay(date);
  if (isModal) return DateFormat.E(loc).format(d);
  return DateFormat.EEEE(loc).format(d);
}

class WeatherDetailScreen extends ConsumerWidget {
  final bool isModal;
  
  const WeatherDetailScreen({
    Key? key, 
    this.isModal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final location = ref.watch(locationNotifierProvider);
    final weatherAsync = ref.watch(weatherProvider);
    final hourlyForecastAsync = ref.watch(hourlyForecastProvider);
    final dailyForecastAsync = ref.watch(dailyForecastProvider);

    final body = Container(
      decoration: BoxDecoration(
        color: isModal ? _wmHubCream : _weatherMintBg,
        gradient: isModal
            ? null
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_weatherSkyTop, _weatherSkyBottom],
              ),
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
              expandedHeight: isModal ? 56 : 120,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  location.when(
                    data: (data) => data ?? l10n.weatherDetailTitle,
                    loading: () => l10n.weatherDetailLoading,
                    error: (_, __) => l10n.weatherDetailTitle,
                  ),
                  style: GoogleFonts.poppins(
                    color: isModal ? _wmHubForest : _weatherMintText,
                    fontWeight: FontWeight.w700,
                    fontSize: isModal ? 15 : 16,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    color: isModal ? _wmHubCream : null,
                    gradient: isModal
                        ? null
                        : LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _weatherSkyTop.withValues(alpha: 0.8),
                              _weatherSkyBottom.withValues(alpha: 0.0),
                            ],
                          ),
                  ),
                ),
              ),
              leading: isModal 
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: _wmHubForest.withValues(alpha: 0.75),
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: _weatherMintText),
                    onPressed: () => Navigator.pop(context),
                  ),
            ),
            
            // Current Weather Section
            SliverToBoxAdapter(
              child: weatherAsync.when(
                data: (weather) =>
                    _buildCurrentWeather(context, l10n, weather, isModal: isModal),
                loading: () => Center(
                  child: Padding(
                    padding: EdgeInsets.all(isModal ? 28.0 : 40.0),
                    child: CircularProgressIndicator(
                      color: isModal ? _wmHubForest : _weatherMintText,
                    ),
                  ),
                ),
                error: (_, __) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(isModal ? 28.0 : 40.0),
                    child: Text(
                      l10n.weatherDetailLoadError,
                      style: GoogleFonts.poppins(
                        fontSize: isModal ? 13 : 15,
                        color: isModal ? _wmModalCharcoal : _weatherMintText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Hourly Forecast Section
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isModal ? 10.0 : 16.0,
                  vertical: isModal ? 4.0 : 8.0,
                ),
                padding: EdgeInsets.fromLTRB(
                  isModal ? 10.0 : 14.0,
                  isModal ? 8.0 : 12.0,
                  isModal ? 10.0 : 14.0,
                  isModal ? 10.0 : 14.0,
                ),
                decoration: BoxDecoration(
                  color: isModal ? Colors.white.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(isModal ? 14 : 18),
                  border: Border.all(
                    color: isModal ? _wmHubForest.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weatherDetail24Hour,
                      style: GoogleFonts.poppins(
                        fontSize: isModal ? 14 : 20,
                        fontWeight: FontWeight.w600,
                        color: isModal ? _wmModalCharcoal : _weatherMintText,
                      ),
                    ),
                    SizedBox(height: isModal ? 8 : 12),
                    hourlyForecastAsync.when(
                      data: (forecasts) =>
                          _buildHourlyForecast(context, forecasts, isModal: isModal),
                      loading: () => Center(
                        child: SizedBox(
                          height: 100,
                          child: CircularProgressIndicator(
                            color: isModal ? _wmHubForest : _weatherMintText,
                          ),
                        ),
                      ),
                      error: (_, __) => _buildMockHourlyForecast(isModal: isModal),
                    ),
                  ],
                ),
              ),
            ),
            
            // 3-Day Forecast Section
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.fromLTRB(isModal ? 10 : 16, isModal ? 6 : 8, isModal ? 10 : 16, 0),
                padding: EdgeInsets.fromLTRB(
                  isModal ? 10.0 : 14.0,
                  isModal ? 8.0 : 12.0,
                  isModal ? 10.0 : 14.0,
                  isModal ? 10.0 : 14.0,
                ),
                decoration: BoxDecoration(
                  color: isModal ? Colors.white.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(isModal ? 14 : 18),
                  border: Border.all(
                    color: isModal ? _wmHubForest.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.55),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weatherDetail3Day,
                      style: GoogleFonts.poppins(
                        fontSize: isModal ? 14 : 20,
                        fontWeight: FontWeight.w600,
                        color: isModal ? _wmModalCharcoal : _weatherMintText,
                      ),
                    ),
                    SizedBox(height: isModal ? 8 : 12),
                    dailyForecastAsync.when(
                      data: (forecasts) =>
                          _buildDailyForecast(context, forecasts, isModal: isModal),
                      loading: () => Center(
                        child: SizedBox(
                          height: 150,
                          child: CircularProgressIndicator(
                            color: isModal ? _wmHubForest : _weatherMintText,
                          ),
                        ),
                      ),
                      error: (_, __) =>
                          _buildMockDailyForecast(context, isModal: isModal),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Padding
            SliverToBoxAdapter(
              child: SizedBox(height: isModal ? 20 : 40),
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
  
  Widget _buildCurrentWeather(
    BuildContext context,
    AppLocalizations l10n,
    WeatherData? weather, {
    bool isModal = false,
  }) {
    if (weather == null) return const SizedBox.shrink();
    
    // Extract icon code from the iconUrl
    final iconCode = weather.iconUrl.split('/').last.replaceAll('@2x.png', '');
    final primary = isModal ? _wmModalCharcoal : _weatherMintText;
    final secondary = isModal ? _wmHubInkMuted : _weatherMintText;
    
    final tempFs = isModal ? 40.0 : 64.0;
    final conditionFs = isModal ? 15.0 : 22.0;
    final descFs = isModal ? 12.0 : 16.0;
    final iconBox = isModal ? 72.0 : 120.0;
    final iconPx = isModal ? 52.0 : 100.0;
    final gapAfterRow = isModal ? 12.0 : 20.0;

    return Container(
      margin: EdgeInsets.all(isModal ? 10 : 16),
      padding: EdgeInsets.symmetric(
        vertical: isModal ? 12 : 20,
        horizontal: isModal ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: isModal ? _wmHubForestTint : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(isModal ? 16 : 20),
        border: isModal
            ? Border.all(
                color: _wmHubForest.withValues(alpha: 0.20),
                width: 1,
              )
            : Border.all(
                color: Colors.white.withValues(alpha: 0.48),
                width: 1,
              ),
        boxShadow: isModal
            ? [
                BoxShadow(
                  color: _wmHubForest.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0x1A446AA4),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${weather.temperature.round()}°',
                      style: GoogleFonts.poppins(
                        fontSize: tempFs,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: primary,
                      ),
                    ),
                    SizedBox(height: isModal ? 2 : 4),
                    Text(
                      weather.condition,
                      style: GoogleFonts.poppins(
                        fontSize: conditionFs,
                        fontWeight: FontWeight.w600,
                        color: secondary,
                      ),
                    ),
                    if (weather.details.containsKey('description'))
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          weather.details['description'] as String,
                          maxLines: isModal ? 1 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: descFs,
                            height: 1.25,
                            color: secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: iconBox,
                height: iconBox,
                child: _getWeatherIcon(
                  weather.condition,
                  iconCode,
                  iconPx,
                  isMain: true,
                ),
              ),
            ],
          ),
          SizedBox(height: gapAfterRow),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherInfoItem(
                icon: Icons.thermostat_outlined,
                value: l10n.weatherDetailFeelsLike(
                  (weather.details['feelsLike'] as num).round(),
                ),
                isModal: isModal,
              ),
              _buildWeatherInfoItem(
                icon: Icons.water_drop_outlined,
                value: '${weather.details['humidity']}%',
                isModal: isModal,
              ),
              _buildWeatherInfoItem(
                icon: Icons.air_outlined,
                value: '${(weather.details['windSpeed'] as num).round()} km/h',
                isModal: isModal,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeatherInfoItem({
    required IconData icon,
    required String value,
    bool isModal = false,
  }) {
    final c = isModal ? _wmHubForest : _weatherMintText;
    final iconSz = isModal ? 17.0 : 22.0;
    final textFs = isModal ? 10.5 : 14.0;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: iconSz),
          SizedBox(height: isModal ? 3 : 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: textFs,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHourlyForecast(
    BuildContext context,
    List<WeatherForecast> forecasts, {
    bool isModal = false,
  }) {
    if (forecasts.isEmpty) {
      return _buildMockHourlyForecast(isModal: isModal);
    }

    final rowH = isModal ? 118.0 : 168.0;
    final cellW = isModal ? 62.0 : 85.0;
    final cellR = isModal ? 11.0 : 14.0;
    final timeFs = isModal ? 11.0 : 14.0;
    final tempFs = isModal ? 14.0 : 17.0;
    final precipFs = isModal ? 10.0 : 11.0;
    final iconBox = isModal ? 30.0 : 44.0;
    final iconPx = isModal ? 28.0 : 38.0;

    return SizedBox(
      height: rowH,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isModal ? 4 : 8),
        itemCount: forecasts.length,
        itemBuilder: (context, index) {
          final forecast = forecasts[index];
          final hour = int.tryParse(forecast.time?.split(' ')[0] ?? '12') ?? 12;
          final isPM = forecast.time?.contains('PM') ?? false;
          final actualHour = isPM && hour != 12 ? hour + 12 : (hour == 12 && !isPM ? 0 : hour);
          final isDay = actualHour >= 6 && actualHour < 18;

          final pc = isModal ? _wmModalCharcoal : _weatherMintText;
          final sc = isModal ? _wmHubInkMuted : _weatherMintText;
          return Container(
            width: cellW,
            margin: EdgeInsets.symmetric(horizontal: isModal ? 3 : 4),
            decoration: BoxDecoration(
              color: isModal
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(cellR),
              border: isModal
                  ? Border.all(
                      color: _wmHubForest.withValues(alpha: 0.16),
                      width: 1,
                    )
                  : null,
              boxShadow: isModal
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: isModal ? 4 : 6),
                  child: Text(
                    forecast.time ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: timeFs,
                      fontWeight: FontWeight.w600,
                      color: pc,
                    ),
                  ),
                ),
                SizedBox(height: isModal ? 2 : 4),
                SizedBox(
                  width: iconBox,
                  height: iconBox,
                  child: _getWeatherIcon(
                    forecast.conditions,
                    isDay ? 'day' : 'night',
                    iconPx,
                  ),
                ),
                SizedBox(height: isModal ? 2 : 4),
                Text(
                  '${forecast.temperature?.round() ?? 0}°',
                  style: GoogleFonts.poppins(
                    fontSize: tempFs,
                    fontWeight: FontWeight.w700,
                    color: pc,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: isModal ? 9 : 11,
                      color: sc.withOpacity(0.95),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${forecast.precipitationProbability.round()}%',
                      style: GoogleFonts.poppins(
                        fontSize: precipFs,
                        fontWeight: FontWeight.w600,
                        color: sc.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isModal ? 2 : 4),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMockHourlyForecast({bool isModal = false}) {
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
    
    final rowH = isModal ? 118.0 : 168.0;
    final cellW = isModal ? 62.0 : 85.0;
    final cellR = isModal ? 11.0 : 14.0;
    final timeFs = isModal ? 11.0 : 14.0;
    final tempFs = isModal ? 14.0 : 17.0;
    final precipFs = isModal ? 10.0 : 11.0;
    final iconBox = isModal ? 30.0 : 44.0;
    final iconPx = isModal ? 28.0 : 38.0;

    return SizedBox(
      height: rowH,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: isModal ? 4 : 8),
        itemCount: forecasts.length,
        itemBuilder: (context, index) {
          final forecast = forecasts[index];
          final pc = isModal ? _wmModalCharcoal : _weatherMintText;
          final sc = isModal ? _wmHubInkMuted : _weatherMintText;

          return Container(
            width: cellW,
            margin: EdgeInsets.symmetric(horizontal: isModal ? 3 : 4),
            decoration: BoxDecoration(
              color: isModal
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(cellR),
              border: isModal
                  ? Border.all(
                      color: _wmHubForest.withValues(alpha: 0.16),
                      width: 1,
                    )
                  : null,
              boxShadow: isModal
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: isModal ? 4 : 6),
                  child: Text(
                    forecast['time'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: timeFs,
                      fontWeight: FontWeight.w600,
                      color: pc,
                    ),
                  ),
                ),
                SizedBox(height: isModal ? 2 : 4),
                SizedBox(
                  width: iconBox,
                  height: iconBox,
                  child: _getWeatherIcon(
                    forecast['condition'] as String,
                    forecast['icon'] as String,
                    iconPx,
                  ),
                ),
                SizedBox(height: isModal ? 2 : 4),
                Text(
                  '${forecast['temp']}°',
                  style: GoogleFonts.poppins(
                    fontSize: tempFs,
                    fontWeight: FontWeight.w700,
                    color: pc,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: isModal ? 9 : 11,
                      color: sc.withOpacity(0.95),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${forecast['precipitation']}%',
                      style: GoogleFonts.poppins(
                        fontSize: precipFs,
                        fontWeight: FontWeight.w600,
                        color: sc.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isModal ? 2 : 4),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDailyForecast(
    BuildContext context,
    List<WeatherForecast> forecasts, {
    bool isModal = false,
  }) {
    if (forecasts.isEmpty) {
      return _buildMockDailyForecast(context, isModal: isModal);
    }
    
    return Column(
      children: forecasts
          .map(
            (forecast) => _buildDailyForecastItem(
              context,
              forecast,
              isModal: isModal,
            ),
          )
          .toList(),
    );
  }

  Widget _buildMockDailyForecast(BuildContext context, {bool isModal = false}) {
    final now = DateTime.now();
    final today = _wmStartOfDay(now);
    final days = [
      {
        'date': today.add(const Duration(days: 1)),
        'min': 12,
        'max': 18,
        'condition': 'Clouds',
      },
      {
        'date': today.add(const Duration(days: 2)),
        'min': 14,
        'max': 20,
        'condition': 'Clear',
      },
      {
        'date': today.add(const Duration(days: 3)),
        'min': 13,
        'max': 19,
        'condition': 'Rain',
      },
    ];

    return Column(
      children: days
          .map(
            (day) => _buildMockDailyForecastItem(
              context,
              day,
              isModal: isModal,
            ),
          )
          .toList(),
    );
  }

  Widget _buildDailyForecastItem(
    BuildContext context,
    WeatherForecast forecast, {
    bool isModal = false,
  }) {
    final dayLabel = _wmDailyDayLabel(context, forecast, isModal: isModal);
    final pc = isModal ? _wmModalCharcoal : _weatherMintText;
    final sc = isModal ? _wmHubInkMuted : _weatherMintText;
    final dayFs = isModal ? 13.0 : 16.0;
    final tempFs = isModal ? 13.0 : 16.0;
    final iconBox = isModal ? 38.0 : 50.0;
    final iconPx = isModal ? 32.0 : 45.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: isModal ? 3 : 4),
      padding: EdgeInsets.symmetric(
        vertical: isModal ? 8 : 12,
        horizontal: isModal ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: isModal
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(isModal ? 12 : 14),
        border: isModal
            ? Border.all(
                color: _wmHubForest.withValues(alpha: 0.16),
                width: 1,
              )
            : null,
        boxShadow: isModal
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dayLabel,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: dayFs,
                fontWeight: FontWeight.w600,
                color: pc,
              ),
            ),
          ),
          SizedBox(
            width: iconBox,
            height: iconBox,
            child: Center(
              child: _getWeatherIcon(forecast.conditions, 'day', iconPx),
            ),
          ),
          SizedBox(width: isModal ? 6 : 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${forecast.minTemperature.round()}° ',
                style: GoogleFonts.poppins(
                  fontSize: tempFs,
                  fontWeight: FontWeight.w500,
                  color: sc.withOpacity(0.92),
                ),
              ),
              Text(
                '${forecast.maxTemperature.round()}°',
                style: GoogleFonts.poppins(
                  fontSize: tempFs,
                  fontWeight: FontWeight.w700,
                  color: pc,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockDailyForecastItem(
    BuildContext context,
    Map<String, dynamic> day, {
    bool isModal = false,
  }) {
    final isSunny = (day['condition'] as String).toLowerCase().contains('clear');
    final date = day['date'] as DateTime;
    final label = _wmMockDailyLabel(context, date, isModal: isModal);
    final pc = isModal ? _wmModalCharcoal : _weatherMintText;
    final sc = isModal ? _wmHubInkMuted : _weatherMintText;
    final dayFs = isModal ? 13.0 : 16.0;
    final tempFs = isModal ? 13.0 : 16.0;
    final iconBox = isModal ? 38.0 : 50.0;
    final iconPx = isModal ? 32.0 : 45.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: isModal ? 3 : 4),
      padding: EdgeInsets.symmetric(
        vertical: isModal ? 8 : 12,
        horizontal: isModal ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: isModal
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(isModal ? 12 : 14),
        border: isModal
            ? Border.all(
                color: _wmHubForest.withValues(alpha: 0.16),
                width: 1,
              )
            : null,
        boxShadow: isModal
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: dayFs,
                fontWeight: FontWeight.w600,
                color: pc,
              ),
            ),
          ),
          SizedBox(
            width: iconBox,
            height: iconBox,
            child: Center(
              child: isSunny
                  ? Icon(
                      Icons.wb_sunny,
                      color: const Color(0xFFFFD700),
                      size: iconPx,
                    )
                  : _getWeatherIcon(day['condition'] as String, 'day', iconPx),
            ),
          ),
          SizedBox(width: isModal ? 6 : 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${day['min']}° ',
                style: GoogleFonts.poppins(
                  fontSize: tempFs,
                  fontWeight: FontWeight.w500,
                  color: sc.withOpacity(0.92),
                ),
              ),
              Text(
                '${day['max']}°',
                style: GoogleFonts.poppins(
                  fontSize: tempFs,
                  fontWeight: FontWeight.w700,
                  color: pc,
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
}
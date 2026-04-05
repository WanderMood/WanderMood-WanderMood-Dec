import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/weather/providers/weather_provider.dart';
import 'package:wandermood/l10n/app_localizations.dart';

String _localizedWeatherMain(String main, AppLocalizations l10n) {
  switch (main.trim().toLowerCase()) {
    case 'clear':
      return l10n.weatherMainClear;
    case 'clouds':
      return l10n.weatherMainClouds;
    case 'rain':
      return l10n.weatherMainRain;
    case 'drizzle':
      return l10n.weatherMainDrizzle;
    case 'thunderstorm':
      return l10n.weatherMainThunderstorm;
    case 'snow':
      return l10n.weatherMainSnow;
    case 'mist':
      return l10n.weatherMainMist;
    case 'fog':
      return l10n.weatherMainFog;
    case 'haze':
      return l10n.weatherMainHaze;
    case 'smoke':
      return l10n.weatherMainSmoke;
    case 'dust':
      return l10n.weatherMainDust;
    case 'sand':
      return l10n.weatherMainSand;
    case 'ash':
      return l10n.weatherMainAsh;
    case 'squall':
      return l10n.weatherMainSquall;
    case 'tornado':
      return l10n.weatherMainTornado;
    default:
      return l10n.weatherMainOther;
  }
}

class MyDayWeatherDialog extends StatelessWidget {
  final WeatherData? weather;

  const MyDayWeatherDialog({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    weather != null
                        ? l10n.myDayWeatherDialogTitle(weather!.location)
                        : l10n.recDetailSectionWeather,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1C18),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF8C8780)),
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
                        _localizedWeatherMain(weather!.condition, l10n),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: const Color(0xFF8C8780),
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
                  border: Border.all(color: const Color(0xFFE8E2D8), width: 1),
                ),
                child: Column(
                  children: [
                    _WeatherDetailRow(
                      label: l10n.myDayWeatherFeelsLike,
                      value:
                          '${weather!.details['feelsLike']?.round() ?? '--'}°C',
                    ),
                    const Divider(
                        height: 16, thickness: 1, color: Color(0xFFE8E2D8)),
                    _WeatherDetailRow(
                      label: l10n.myDayWeatherHumidity,
                      value: '${weather!.details['humidity'] ?? '--'}%',
                    ),
                    const Divider(
                        height: 16, thickness: 1, color: Color(0xFFE8E2D8)),
                    _WeatherDetailRow(
                      label: l10n.myDayWeatherDescriptionLabel,
                      value: (weather!.details['description'] as String?)
                                  ?.trim()
                                  .isNotEmpty ==
                              true
                          ? (weather!.details['description'] as String).trim()
                          : l10n.myDayWeatherClearSkyFallback,
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
                l10n.myDayWeatherUnavailable,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                l10n.myDayWeatherCheckConnection,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.myDayWeatherClose,
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
      case 'drizzle':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'mist':
      case 'fog':
      case 'haze':
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
      case 'drizzle':
        return Colors.blue;
      case 'snow':
        return Colors.lightBlue;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'mist':
      case 'fog':
      case 'haze':
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF4A4640),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF1E1C18),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

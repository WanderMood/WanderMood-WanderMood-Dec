import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../application/enhanced_weather_service.dart';
import '../../domain/models/weather_location.dart';
import '../../domain/models/weather.dart';
import '../../domain/models/weather_forecast.dart';

class WeatherTestScreen extends ConsumerStatefulWidget {
  const WeatherTestScreen({super.key});

  @override
  ConsumerState<WeatherTestScreen> createState() => _WeatherTestScreenState();
}

class _WeatherTestScreenState extends ConsumerState<WeatherTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Test locations
  final List<WeatherLocation> _testLocations = [
    WeatherLocation(
      id: 'amsterdam',
      name: 'Amsterdam',
      latitude: 52.3676,
      longitude: 4.9041,
    ),
    WeatherLocation(
      id: 'paris',
      name: 'Paris',
      latitude: 48.8566,
      longitude: 2.3522,
    ),
    WeatherLocation(
      id: 'newyork',
      name: 'New York',
      latitude: 40.7128,
      longitude: -74.0060,
    ),
    WeatherLocation(
      id: 'tokyo',
      name: 'Tokyo',
      latitude: 35.6762,
      longitude: 139.6503,
    ),
  ];
  
  WeatherLocation? _selectedLocation;
  Weather? _currentWeather;
  List<WeatherForecast>? _forecast;
  Map<String, dynamic>? _travelPostWeather;
  
  bool _isLoadingCurrent = false;
  bool _isLoadingForecast = false;
  bool _isLoadingTravelPost = false;
  
  String? _currentError;
  String? _forecastError;
  String? _travelPostError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedLocation = _testLocations.first;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Weather API Test'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Current Weather'),
            Tab(text: 'Forecast'),
            Tab(text: 'Travel Post Weather'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildLocationSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentWeatherTab(),
                _buildForecastTab(),
                _buildTravelPostWeatherTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Test Location:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButton<WeatherLocation>(
            value: _selectedLocation,
            isExpanded: true,
            onChanged: (location) {
              setState(() {
                _selectedLocation = location;
                _currentWeather = null;
                _forecast = null;
                _travelPostWeather = null;
                _currentError = null;
                _forecastError = null;
                _travelPostError = null;
              });
            },
            items: _testLocations.map((location) {
              return DropdownMenuItem(
                value: location,
                child: Text('${location.name} (${location.latitude}, ${location.longitude})'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Current Weather for ${_selectedLocation?.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoadingCurrent ? null : _fetchCurrentWeather,
                icon: _isLoadingCurrent
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Fetch'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_currentError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: $_currentError',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_currentWeather != null) ...[
            _buildCurrentWeatherCard(_currentWeather!),
          ] else if (!_isLoadingCurrent && _currentError == null) ...[
            const Text('No weather data loaded. Tap "Fetch" to load current weather.'),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hourly Forecast for ${_selectedLocation?.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoadingForecast ? null : _fetchForecast,
                icon: _isLoadingForecast
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Fetch'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_forecastError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: $_forecastError',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_forecast != null) ...[
            Expanded(child: _buildForecastList(_forecast!)),
          ] else if (!_isLoadingForecast && _forecastError == null) ...[
            const Text('No forecast data loaded. Tap "Fetch" to load hourly forecast.'),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelPostWeatherTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Travel Post Weather for ${_selectedLocation?.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoadingTravelPost ? null : _fetchTravelPostWeather,
                icon: _isLoadingTravelPost
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Fetch'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This demonstrates the weather data format used when creating travel posts.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          if (_travelPostError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: $_travelPostError',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_travelPostWeather != null) ...[
            _buildTravelPostWeatherCard(_travelPostWeather!),
          ] else if (!_isLoadingTravelPost && _travelPostError == null) ...[
            const Text('No travel post weather data loaded. Tap "Fetch" to load weather data.'),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard(Weather weather) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getWeatherIcon(weather.icon ?? '01d'),
                  size: 48,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weather.condition,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        weather.description ?? 'No description available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherDetail('Feels Like', '${weather.feelsLike?.toStringAsFixed(1) ?? 'N/A'}°C'),
                ),
                Expanded(
                  child: _buildWeatherDetail('Humidity', '${weather.humidity}%'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherDetail('Wind Speed', '${weather.windSpeed.toStringAsFixed(1)} m/s'),
                ),
                Expanded(
                  child: _buildWeatherDetail('Pressure', '${weather.pressure ?? 'N/A'} hPa'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildWeatherDetail('Min Temp', '${weather.minTemp?.toStringAsFixed(1) ?? 'N/A'}°C'),
                ),
                Expanded(
                  child: _buildWeatherDetail('Max Temp', '${weather.maxTemp?.toStringAsFixed(1) ?? 'N/A'}°C'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastList(List<WeatherForecast> forecasts) {
    return ListView.builder(
      itemCount: forecasts.length,
      itemBuilder: (context, index) {
        final forecast = forecasts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(_getWeatherIcon(forecast.icon ?? '01d')),
            title: Text('${forecast.time ?? ''} - ${forecast.temperature?.toStringAsFixed(1) ?? forecast.maxTemperature.toStringAsFixed(1)}°C'),
            subtitle: Text('${forecast.conditions} (${forecast.humidity.toStringAsFixed(0)}% humidity)'),
            trailing: forecast.precipitation > 0
                ? Text('${forecast.precipitation.toStringAsFixed(0)}%')
                : null,
          ),
        );
      },
    );
  }

  Widget _buildTravelPostWeatherCard(Map<String, dynamic> weatherData) {
    final isFallback = weatherData['isFallback'] == true;
    
    return Card(
      elevation: 4,
      color: isFallback ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFallback) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Fallback Data',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'JSON Format for Travel Posts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _formatJson(weatherData),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(_getWeatherIcon(weatherData['icon'] ?? '01d')),
                const SizedBox(width: 8),
                Text(
                  '${weatherData['temperature'] ?? 0}°C - ${weatherData['condition'] ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode.substring(0, 2)) {
      case '01': return Icons.wb_sunny;
      case '02': return Icons.wb_cloudy;
      case '03': case '04': return Icons.cloud;
      case '09': case '10': return Icons.umbrella;
      case '11': return Icons.flash_on;
      case '13': return Icons.ac_unit;
      case '50': return Icons.foggy;
      default: return Icons.wb_sunny;
    }
  }

  String _formatJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<void> _fetchCurrentWeather() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isLoadingCurrent = true;
      _currentError = null;
    });

    try {
      final weatherService = EnhancedWeatherService();
      final weather = await weatherService.getCurrentWeather(_selectedLocation!);
      
      setState(() {
        _currentWeather = weather;
        _isLoadingCurrent = false;
      });
    } catch (e) {
      setState(() {
        _currentError = e.toString();
        _isLoadingCurrent = false;
      });
    }
  }

  Future<void> _fetchForecast() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isLoadingForecast = true;
      _forecastError = null;
    });

    try {
      final weatherService = EnhancedWeatherService();
      final forecast = await weatherService.getHourlyForecast(_selectedLocation!);
      
      setState(() {
        _forecast = forecast;
        _isLoadingForecast = false;
      });
    } catch (e) {
      setState(() {
        _forecastError = e.toString();
        _isLoadingForecast = false;
      });
    }
  }

  Future<void> _fetchTravelPostWeather() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isLoadingTravelPost = true;
      _travelPostError = null;
    });

    try {
      final weatherService = EnhancedWeatherService();
      final weatherData = await weatherService.getWeatherForTravelPost(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      
      setState(() {
        _travelPostWeather = weatherData;
        _isLoadingTravelPost = false;
      });
    } catch (e) {
      setState(() {
        _travelPostError = e.toString();
        _isLoadingTravelPost = false;
      });
    }
  }
} 
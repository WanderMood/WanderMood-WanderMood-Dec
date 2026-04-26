import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../domain/models/weather_data.dart';
import '../domain/models/weather_forecast.dart';
import '../domain/models/weather_alert.dart';
import '../domain/models/weather_location.dart';

class WeatherCacheService {
  static const String _locationBoxName = 'locations';
  static const String _weatherBoxName = 'weather';
  static const String _forecastBoxName = 'forecasts';
  static const String _alertBoxName = 'weather_alerts';
  static const Duration _cacheDuration = Duration(hours: 1);

  late Box<WeatherLocation> _locationBox;
  late Box<WeatherData> _weatherBox;
  late Box<List<WeatherForecast>> _forecastBox;
  Box<List<dynamic>>? _alertBox;

  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    if (!Hive.isBoxOpen('forecasts')) {
      Hive.init(appDir.path);
      
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WeatherForecastAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(WeatherAlertAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(LocationAdapter());
      }
      
      _forecastBox = await Hive.openBox<List<WeatherForecast>>(_forecastBoxName);
      _alertBox = await Hive.openBox<List<dynamic>>('alerts');
    } else {
      _forecastBox = Hive.box<List<WeatherForecast>>(_forecastBoxName);
    }

    _locationBox = await Hive.openBox<WeatherLocation>(_locationBoxName);
    _weatherBox = await Hive.openBox<WeatherData>(_weatherBoxName);
  }

  Future<void> cacheWeatherData(WeatherLocation location, WeatherData weather) async {
    await _weatherBox.put(_getLocationKey(location), weather);
  }

  Future<WeatherData?> getCachedWeatherData(WeatherLocation location) async {
    return _weatherBox.get(_getLocationKey(location));
  }

  Future<void> cacheForecasts(WeatherLocation location, List<WeatherForecast> forecasts) async {
    await _forecastBox.put(_getLocationKey(location), forecasts);
  }

  Future<List<WeatherForecast>?> getCachedForecasts(WeatherLocation location) async {
    return _forecastBox.get(_getLocationKey(location));
  }

  Future<void> cacheAlerts(List<WeatherAlert> alerts) async {
    await _alertBox?.put('alerts', alerts);
  }

  Future<List<WeatherAlert>?> getCachedAlerts() async {
    final alerts = _alertBox?.get('alerts');
    return alerts?.cast<WeatherAlert>();
  }

  Future<void> cacheLocation(WeatherLocation location) async {
    await _locationBox.put(location.id, location);
  }

  Future<WeatherLocation?> getCachedLocation(String name) async {
    final locations = _locationBox.values;
    try {
      return locations.firstWhere(
        (loc) => loc.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  String _getLocationKey(WeatherLocation location) {
    return '${location.latitude}_${location.longitude}';
  }

  Future<void> clearCache() async {
    await init();
    await _weatherBox.clear();
    await _forecastBox.clear();
    await _alertBox?.clear();
    await _locationBox.clear();
  }
}

// Hive adapters
class WeatherDataAdapter extends TypeAdapter<WeatherData> {
  @override
  final int typeId = 0;

  @override
  WeatherData read(BinaryReader reader) {
    return WeatherData.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, WeatherData obj) {
    writer.writeMap(obj.toJson());
  }
}

class WeatherForecastAdapter extends TypeAdapter<WeatherForecast> {
  @override
  final int typeId = 1;

  @override
  WeatherForecast read(BinaryReader reader) {
    return WeatherForecast.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, WeatherForecast obj) {
    writer.writeMap(obj.toJson());
  }
}

class WeatherAlertAdapter extends TypeAdapter<WeatherAlert> {
  @override
  final int typeId = 2;

  @override
  WeatherAlert read(BinaryReader reader) {
    return WeatherAlert.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, WeatherAlert obj) {
    writer.writeMap(obj.toJson());
  }
}

class LocationAdapter extends TypeAdapter<WeatherLocation> {
  @override
  final int typeId = 0;

  @override
  WeatherLocation read(BinaryReader reader) {
    return WeatherLocation.fromJson(Map<String, dynamic>.from(reader.readMap()));
  }

  @override
  void write(BinaryWriter writer, WeatherLocation obj) {
    writer.writeMap(obj.toJson());
  }
} 
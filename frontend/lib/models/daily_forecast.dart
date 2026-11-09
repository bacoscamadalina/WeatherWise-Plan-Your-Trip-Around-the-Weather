import 'weather_advisory.dart';
import 'current_conditions.dart';

class DailyForecast {
  const DailyForecast({
    required this.id,
    required this.date,
    required this.label,
    required this.weatherClass,
    required this.activityContext,
    required this.minC,
    required this.maxC,
    required this.rainProbability,
    required this.windSpeedKph,
    this.uvIndexMax,
    this.sunriseLocal,
    this.sunsetLocal,
    this.daylightDurationSeconds,
    this.current,
    this.advisories = const [],
  });

  final int id;
  final DateTime date;
  final String label;
  final String weatherClass;
  final String activityContext;
  final double minC;
  final double maxC;
  final int rainProbability;
  final double windSpeedKph;
  final double? uvIndexMax;
  final String? sunriseLocal;
  final String? sunsetLocal;
  final int? daylightDurationSeconds;
  final CurrentConditions? current;
  final List<WeatherAdvisory> advisories;

  bool get hasHighAdvisory => advisories.any((advisory) => advisory.isHigh);

  String? get daylightRange {
    final sunrise = _clockTime(sunriseLocal);
    final sunset = _clockTime(sunsetLocal);
    if (sunrise == null || sunset == null) return null;
    return '$sunrise–$sunset';
  }

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    final condition = json['condition'] as Map<String, dynamic>;
    final temperature = json['temperature'] as Map<String, dynamic>;
    final precipitation = json['precipitation'] as Map<String, dynamic>;
    return DailyForecast(
      id: json['id'] as int,
      date: DateTime.parse(json['date'] as String),
      label: condition['label'] as String,
      weatherClass: condition['weather_class'] as String,
      activityContext: json['activity_context'] as String,
      minC: (temperature['min_c'] as num).toDouble(),
      maxC: (temperature['max_c'] as num).toDouble(),
      rainProbability: precipitation['probability'] as int,
      windSpeedKph: (json['wind_speed_kph'] as num).toDouble(),
      uvIndexMax: (json['uv_index_max'] as num?)?.toDouble(),
      sunriseLocal: (json['daylight']
          as Map<String, dynamic>?)?['sunrise_local'] as String?,
      sunsetLocal: (json['daylight'] as Map<String, dynamic>?)?['sunset_local']
          as String?,
      daylightDurationSeconds: (json['daylight']
          as Map<String, dynamic>?)?['duration_seconds'] as int?,
      current: json['current'] == null
          ? null
          : CurrentConditions.fromJson(
              json['current'] as Map<String, dynamic>,
            ),
      advisories: ((json['advisories'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(WeatherAdvisory.fromJson)
          .toList(growable: false),
    );
  }

  static String? _clockTime(String? value) {
    if (value == null) return null;
    final separator = value.indexOf('T');
    if (separator < 0 || value.length < separator + 6) return null;
    return value.substring(separator + 1, separator + 6);
  }
}

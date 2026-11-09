class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.label,
    required this.weatherClass,
    required this.activityContext,
    required this.temperatureC,
    required this.rainProbability,
    required this.windSpeedKph,
    required this.daylight,
  });

  final DateTime time;
  final String label;
  final String weatherClass;
  final String activityContext;
  final double temperatureC;
  final int rainProbability;
  final double windSpeedKph;
  final bool daylight;

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final condition = json['condition'] as Map<String, dynamic>;
    final precipitation = json['precipitation'] as Map<String, dynamic>;
    return HourlyForecast(
      // Keep the searched place's wall-clock hour even when the device uses a
      // different timezone. `time` remains available in the API as an instant.
      time: DateTime.parse(
        (json['local_time'] as String?) ?? _wallClock(json['time'] as String),
      ),
      label: condition['label'] as String,
      weatherClass: condition['weather_class'] as String,
      activityContext: json['activity_context'] as String,
      temperatureC: (json['temperature_c'] as num).toDouble(),
      rainProbability: (precipitation['probability'] as num).toInt(),
      windSpeedKph: (json['wind_speed_kph'] as num).toDouble(),
      daylight: json['daylight'] as bool? ?? false,
    );
  }

  static String _wallClock(String timestamp) =>
      timestamp.length >= 19 ? timestamp.substring(0, 19) : timestamp;
}

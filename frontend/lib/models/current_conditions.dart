class CurrentConditions {
  const CurrentConditions({
    required this.observedAt,
    required this.label,
    required this.weatherClass,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.precipitationMm,
    required this.windSpeedKph,
    required this.daylight,
  });

  final String observedAt;
  final String label;
  final String weatherClass;
  final double temperatureC;
  final double apparentTemperatureC;
  final double precipitationMm;
  final double windSpeedKph;
  final bool daylight;

  factory CurrentConditions.fromJson(Map<String, dynamic> json) {
    final condition = json['condition'] as Map<String, dynamic>;
    return CurrentConditions(
      observedAt: json['observed_at'] as String,
      label: condition['label'] as String,
      weatherClass: condition['weather_class'] as String,
      temperatureC: (json['temperature_c'] as num).toDouble(),
      apparentTemperatureC: (json['apparent_temperature_c'] as num).toDouble(),
      precipitationMm: (json['precipitation_mm'] as num).toDouble(),
      windSpeedKph: (json['wind_speed_kph'] as num).toDouble(),
      daylight: json['daylight'] as bool,
    );
  }
}

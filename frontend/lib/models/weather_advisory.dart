class WeatherAdvisory {
  const WeatherAdvisory({
    required this.code,
    required this.severity,
    required this.title,
    required this.message,
  });

  final String code;
  final String severity;
  final String title;
  final String message;

  bool get isHigh => severity == 'high';

  factory WeatherAdvisory.fromJson(Map<String, dynamic> json) =>
      WeatherAdvisory(
        code: json['code'] as String,
        severity: json['severity'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
      );
}

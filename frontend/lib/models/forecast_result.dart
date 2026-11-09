import 'daily_forecast.dart';
import 'location.dart';

class ForecastResult {
  const ForecastResult({
    required this.location,
    required this.forecasts,
    this.isDemo = false,
    this.sourceLabel,
    this.sourceUrl,
    this.updatedAt,
  });

  final Location location;
  final List<DailyForecast> forecasts;
  final bool isDemo;
  final String? sourceLabel;
  final String? sourceUrl;
  final DateTime? updatedAt;
}

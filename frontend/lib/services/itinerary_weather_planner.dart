import '../models/hourly_forecast.dart';
import '../models/itinerary_item.dart';

class ItineraryPeriodWeather {
  const ItineraryPeriodWeather({
    required this.period,
    required this.forecast,
  });

  final String period;
  final HourlyForecast forecast;
}

class ItineraryWeatherPlanner {
  const ItineraryWeatherPlanner();

  Map<String, ItineraryPeriodWeather> build({
    required List<HourlyForecast> hours,
    required List<ItineraryItem> items,
  }) {
    if (hours.isEmpty) return const {};
    final byPeriod = {for (final item in items) item.period: item};
    return {
      for (final period in const ['morning', 'afternoon', 'evening'])
        period: ItineraryPeriodWeather(
          period: period,
          forecast: _nearest(
            hours,
            _targetHour(period, byPeriod[period]?.startTime),
          ),
        ),
    };
  }

  HourlyForecast _nearest(List<HourlyForecast> hours, int targetHour) {
    return hours.reduce((best, candidate) {
      final bestDistance = (best.time.hour - targetHour).abs();
      final candidateDistance = (candidate.time.hour - targetHour).abs();
      if (candidateDistance != bestDistance) {
        return candidateDistance < bestDistance ? candidate : best;
      }
      return candidate.time.isBefore(best.time) ? candidate : best;
    });
  }

  int _targetHour(String period, String? startTime) {
    if (startTime != null) {
      final hour = int.tryParse(startTime.split(':').first);
      if (hour != null && hour >= 0 && hour <= 23) return hour;
    }
    return switch (period) {
      'morning' => 9,
      'afternoon' => 15,
      _ => 20,
    };
  }
}

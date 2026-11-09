import '../models/itinerary_item.dart';
import '../models/plan_recommendation.dart';
import 'day_plan_builder.dart';
import 'itinerary_weather_planner.dart';

class AdaptiveDayPlan {
  const AdaptiveDayPlan();

  Set<String> riskyPeriods({
    required List<ItineraryItem> items,
    required Map<String, ItineraryPeriodWeather> weather,
  }) =>
      {
        for (final item in items)
          if (item.indoor == false && _isRisky(weather[item.period]))
            item.period,
      };

  Map<String, String> relocations({
    required List<ItineraryItem> items,
    required Map<String, ItineraryPeriodWeather> weather,
    required Set<String> riskyPeriods,
  }) {
    final occupied = items.map((item) => item.period).toSet();
    final result = <String, String>{};
    for (final item in items) {
      if (!riskyPeriods.contains(item.period) ||
          item.sourceType != 'activity' ||
          item.startTime != null) {
        continue;
      }
      for (final candidate in const ['morning', 'afternoon']) {
        if (candidate == item.period ||
            occupied.contains(candidate) ||
            (item.recommendedPeriods.isNotEmpty &&
                !item.recommendedPeriods.contains(candidate)) ||
            weather[candidate] == null ||
            _isRisky(weather[candidate])) {
          continue;
        }
        result[item.period] = candidate;
        occupied.add(candidate);
        break;
      }
    }
    return result;
  }

  Map<String, PlanRecommendation> replacements({
    required List<PlanRecommendation> recommendations,
    required List<ItineraryItem> items,
    required Set<String> riskyPeriods,
  }) {
    final used = items
        .where((item) => !riskyPeriods.contains(item.period))
        .map((item) => item.sourceKey)
        .toSet();
    final result = <String, PlanRecommendation>{};
    for (final period in DayPlanBuilder.periods) {
      if (!riskyPeriods.contains(period)) continue;
      final candidates = recommendations.where((item) {
        final key = const DayPlanBuilder().sourceKey(item);
        return item.indoor && !used.contains(key) && _fits(item, period);
      }).toList(growable: false)
        ..sort((a, b) => b.score.compareTo(a.score));
      if (candidates.isEmpty) continue;
      result[period] = candidates.first;
      used.add(const DayPlanBuilder().sourceKey(candidates.first));
    }
    return result;
  }

  bool _isRisky(ItineraryPeriodWeather? value) {
    if (value == null) return false;
    final hour = value.forecast;
    return hour.weatherClass == 'rain' ||
        hour.rainProbability >= 50 ||
        hour.windSpeedKph >= 35 ||
        hour.weatherClass == 'storm' ||
        hour.weatherClass == 'snow';
  }

  bool _fits(PlanRecommendation item, String period) {
    if (item.recommendedPeriods.isNotEmpty) {
      return item.recommendedPeriods.contains(period);
    }
    return item.type == 'movie' ? period == 'evening' : period != 'evening';
  }
}

import '../models/daily_forecast.dart';
import '../models/location.dart';
import '../models/plan_recommendation.dart';

class MovieRotationLedger {
  final Set<int> _seenMovieIds = {};
  final Map<String, Set<int>> _movieIdsByContext = {};

  void seedSeenIds(Iterable<int> movieIds) {
    _seenMovieIds.addAll(movieIds);
  }

  void rememberIds(
    Location location,
    DailyForecast forecast,
    Iterable<int> movieIds,
  ) {
    final ids = movieIds.toSet();
    if (ids.isEmpty) return;
    _seenMovieIds.addAll(ids);
    _movieIdsByContext
        .putIfAbsent(_contextKey(location, forecast), () => <int>{})
        .addAll(ids);
  }

  Set<int> exclusions(Location location, DailyForecast forecast) {
    final allowed =
        _movieIdsByContext[_contextKey(location, forecast)] ?? const <int>{};
    return _seenMovieIds.difference(allowed);
  }

  void remember(
    Location location,
    DailyForecast forecast,
    Iterable<PlanRecommendation> recommendations,
  ) {
    final ids = recommendations
        .where((item) => item.type == 'movie')
        .map((item) => item.id)
        .toSet();
    rememberIds(location, forecast, ids);
  }

  String _contextKey(Location location, DailyForecast forecast) =>
      '${location.countryCode}:${location.id}:${location.latitude}:${location.longitude}:${forecast.date.toIso8601String().split('T').first}';
}

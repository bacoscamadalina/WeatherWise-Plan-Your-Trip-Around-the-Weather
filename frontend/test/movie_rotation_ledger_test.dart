import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/daily_forecast.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/plan_recommendation.dart';
import 'package:weatherwise/services/movie_rotation_ledger.dart';

void main() {
  test('keeps a day stable but excludes its movies from another day', () {
    final ledger = MovieRotationLedger();
    ledger.remember(_iasi, _rainyDay, const [_movie]);

    expect(ledger.exclusions(_iasi, _rainyDay), isEmpty);
    expect(ledger.exclusions(_iasi, _sunnyDay), {42});
  });

  test('excludes previously shown movies from another location', () {
    final ledger = MovieRotationLedger();
    ledger.remember(_iasi, _rainyDay, const [_movie]);

    expect(ledger.exclusions(_brasov, _rainyDay), {42});
  });

  test('includes saved-plan movies in the global rotation', () {
    final ledger = MovieRotationLedger()..seedSeenIds(const [42, 91]);

    ledger.rememberIds(_iasi, _rainyDay, const [42]);

    expect(ledger.exclusions(_iasi, _rainyDay), {91});
    expect(ledger.exclusions(_iasi, _sunnyDay), {42, 91});
  });
}

const _iasi = Location(
  id: 1,
  name: 'Iași',
  displayName: 'Iași, Romania',
  countryCode: 'RO',
  latitude: 47.1585,
  longitude: 27.6014,
  timezone: 'Europe/Bucharest',
);

const _brasov = Location(
  id: 2,
  name: 'Brașov',
  displayName: 'Brașov, Romania',
  countryCode: 'RO',
  latitude: 45.6579,
  longitude: 25.6012,
  timezone: 'Europe/Bucharest',
);

final _rainyDay = DailyForecast(
  id: 7,
  date: DateTime(2026, 10, 7),
  label: 'Rain',
  weatherClass: 'rain',
  activityContext: 'indoor',
  minC: 8,
  maxC: 14,
  rainProbability: 80,
  windSpeedKph: 12,
);

final _sunnyDay = DailyForecast(
  id: 8,
  date: DateTime(2026, 10, 8),
  label: 'Clear',
  weatherClass: 'clear',
  activityContext: 'outdoor',
  minC: 10,
  maxC: 20,
  rainProbability: 5,
  windSpeedKph: 8,
);

const _movie = PlanRecommendation(
  id: 42,
  type: 'movie',
  title: 'Rain Mystery',
  summary: 'A mystery for a rainy evening.',
  indoor: true,
  genres: ['mystery'],
  tags: ['movie'],
  score: 90,
  reason: 'Fits the rain.',
);

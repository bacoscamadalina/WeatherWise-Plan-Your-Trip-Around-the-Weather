import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/daily_forecast.dart';
import 'package:weatherwise/models/weather_advisory.dart';
import 'package:weatherwise/services/best_day_advisor.dart';

void main() {
  const advisor = BestDayAdvisor();

  test('chooses the strongest outdoor weather balance', () {
    final result = advisor.bestOutdoorDay([
      _forecast(id: 1, rain: 70, wind: 12, context: 'indoor'),
      _forecast(id: 2, rain: 10, wind: 11, context: 'outdoor'),
      _forecast(id: 3, rain: 25, wind: 20, context: 'flexible'),
    ]);

    expect(result?.forecast.id, 2);
    expect(result?.reason, 'Low rain risk and manageable wind.');
  });

  test('penalizes days with planning advisories', () {
    final result = advisor.bestOutdoorDay([
      _forecast(
        id: 1,
        rain: 0,
        wind: 12,
        context: 'outdoor',
        advisories: const [
          WeatherAdvisory(
            code: 'heat',
            severity: 'high',
            title: 'Heat',
            message: 'Avoid exposed plans.',
          ),
        ],
      ),
      _forecast(id: 2, rain: 15, wind: 15, context: 'outdoor'),
    ]);

    expect(result?.forecast.id, 2);
  });

  test('returns the earlier day when scores match', () {
    final result = advisor.bestOutdoorDay([
      _forecast(id: 2, rain: 10, wind: 12, context: 'outdoor'),
      _forecast(id: 1, rain: 10, wind: 12, context: 'outdoor'),
    ]);

    expect(result?.forecast.id, 1);
  });

  test('keeps a poor-outlook explanation concrete', () {
    final result = advisor.bestOutdoorDay([
      _forecast(id: 1, rain: 75, wind: 38, context: 'caution'),
      _forecast(id: 2, rain: 65, wind: 32, context: 'caution'),
    ]);

    expect(
      result?.reason,
      'Best available balance: 65% rain and 32 km/h wind.',
    );
  });

  test('penalizes and explains very high UV exposure', () {
    final result = advisor.bestOutdoorDay([
      _forecast(
        id: 1,
        rain: 0,
        wind: 8,
        context: 'outdoor',
        uvIndexMax: 10,
      ),
      _forecast(
        id: 2,
        rain: 10,
        wind: 10,
        context: 'outdoor',
        uvIndexMax: 8.2,
      ),
    ]);

    expect(result?.forecast.id, 2);
    expect(result?.reason, 'UV peaks at 8.2; favor shade around midday.');
  });

  test('keeps rain and wind concrete when a poor day also has high UV', () {
    final result = advisor.bestOutdoorDay([
      _forecast(
        id: 1,
        rain: 65,
        wind: 32,
        context: 'caution',
        uvIndexMax: 8.6,
      ),
    ]);

    expect(
      result?.reason,
      'Best available balance: 65% rain and 32 km/h wind. '
      'UV peaks at 8.6; favor shade around midday.',
    );
  });

  test('returns null for an empty outlook', () {
    expect(advisor.bestOutdoorDay(const []), isNull);
  });
}

DailyForecast _forecast({
  required int id,
  required int rain,
  required double wind,
  required String context,
  List<WeatherAdvisory> advisories = const [],
  double? uvIndexMax,
}) {
  return DailyForecast(
    id: id,
    date: DateTime(2026, 10, id),
    label: 'Clear',
    weatherClass: 'clear',
    activityContext: context,
    minC: 12,
    maxC: 22,
    rainProbability: rain,
    windSpeedKph: wind,
    uvIndexMax: uvIndexMax,
    advisories: advisories,
  );
}

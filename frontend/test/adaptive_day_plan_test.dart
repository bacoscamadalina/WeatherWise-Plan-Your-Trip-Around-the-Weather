import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/hourly_forecast.dart';
import 'package:weatherwise/models/itinerary_item.dart';
import 'package:weatherwise/services/adaptive_day_plan.dart';
import 'package:weatherwise/services/itinerary_weather_planner.dart';

void main() {
  test('flags only exposed outdoor stops in hazardous hourly weather', () {
    final risks = const AdaptiveDayPlan().riskyPeriods(
      items: const [
        ItineraryItem(
            sourceKey: 'a',
            sourceType: 'activity',
            title: 'Park',
            subtitle: 'Outdoor',
            period: 'afternoon',
            indoor: false),
        ItineraryItem(
            sourceKey: 'b',
            sourceType: 'activity',
            title: 'Museum',
            subtitle: 'Indoor',
            period: 'morning',
            indoor: true),
      ],
      weather: {
        'morning': ItineraryPeriodWeather(period: 'morning', forecast: _rain()),
        'afternoon':
            ItineraryPeriodWeather(period: 'afternoon', forecast: _rain()),
      },
    );
    expect(risks, {'afternoon'});
  });

  test('moves an unscheduled outdoor stop into a free safer period', () {
    final moves = const AdaptiveDayPlan().relocations(
      items: const [
        ItineraryItem(
          sourceKey: 'activity:test:1',
          sourceType: 'activity',
          title: 'Park walk',
          subtitle: 'Outdoor',
          period: 'morning',
          indoor: false,
        ),
      ],
      weather: {
        'morning': ItineraryPeriodWeather(
          period: 'morning',
          forecast: _rain(),
        ),
        'afternoon': ItineraryPeriodWeather(
          period: 'afternoon',
          forecast: _clear(),
        ),
      },
      riskyPeriods: const {'morning'},
    );

    expect(moves, {'morning': 'afternoon'});
  });

  test('does not move a stop outside its provider-derived periods', () {
    final moves = const AdaptiveDayPlan().relocations(
      items: const [
        ItineraryItem(
          sourceKey: 'activity:test:1',
          sourceType: 'activity',
          title: 'Morning garden tour',
          subtitle: 'Outdoor',
          period: 'morning',
          indoor: false,
          recommendedPeriods: ['morning'],
        ),
      ],
      weather: {
        'morning': ItineraryPeriodWeather(
          period: 'morning',
          forecast: _rain(),
        ),
        'afternoon': ItineraryPeriodWeather(
          period: 'afternoon',
          forecast: _clear(),
        ),
      },
      riskyPeriods: const {'morning'},
    );

    expect(moves, isEmpty);
  });
}

HourlyForecast _rain() => HourlyForecast(
      time: DateTime(2026, 10, 2, 15),
      label: 'Rain',
      weatherClass: 'rain',
      activityContext: 'indoor',
      temperatureC: 12,
      rainProbability: 29,
      windSpeedKph: 12,
      daylight: true,
    );

HourlyForecast _clear() => HourlyForecast(
      time: DateTime(2026, 10, 2, 15),
      label: 'Clear',
      weatherClass: 'clear',
      activityContext: 'outdoor',
      temperatureC: 18,
      rainProbability: 5,
      windSpeedKph: 8,
      daylight: true,
    );

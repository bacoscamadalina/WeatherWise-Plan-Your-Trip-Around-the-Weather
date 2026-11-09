import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/hourly_forecast.dart';
import 'package:weatherwise/models/itinerary_item.dart';
import 'package:weatherwise/services/itinerary_weather_planner.dart';

void main() {
  test('matches the nearest forecast to each default day period', () {
    final result = const ItineraryWeatherPlanner().build(
      hours: [_hour(9), _hour(15), _hour(20)],
      items: const [],
    );

    expect(result['morning']?.forecast.time.hour, 9);
    expect(result['afternoon']?.forecast.time.hour, 15);
    expect(result['evening']?.forecast.time.hour, 20);
  });

  test('uses a planned event time instead of the period default', () {
    final result = const ItineraryWeatherPlanner().build(
      hours: [_hour(18), _hour(20), _hour(22)],
      items: const [
        ItineraryItem(
          sourceKey: 'event:1',
          sourceType: 'event',
          title: 'Concert',
          subtitle: 'Test Hall · 22:00',
          period: 'evening',
          startTime: '22:00',
        ),
      ],
    );

    expect(result['evening']?.forecast.time.hour, 22);
  });
}

HourlyForecast _hour(int hour) => HourlyForecast(
      time: DateTime(2026, 10, 2, hour),
      label: 'Clear',
      weatherClass: 'clear',
      activityContext: 'outdoor',
      temperatureC: 18,
      rainProbability: 5,
      windSpeedKph: 7,
      daylight: true,
    );

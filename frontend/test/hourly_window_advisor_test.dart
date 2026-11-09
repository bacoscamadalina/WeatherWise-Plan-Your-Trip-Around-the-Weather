import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/hourly_forecast.dart';
import 'package:weatherwise/services/hourly_window_advisor.dart';

void main() {
  test('finds the longest consecutive daylight outdoor window', () {
    final hours = List.generate(24, (hour) {
      final suitable = hour >= 14 && hour <= 19;
      return HourlyForecast(
        time: DateTime(2026, 10, 2, hour),
        label: suitable ? 'Clear' : 'Rain',
        weatherClass: suitable ? 'clear' : 'rain',
        activityContext: suitable ? 'outdoor' : 'indoor',
        temperatureC: 16,
        rainProbability: suitable ? 10 : 80,
        windSpeedKph: 12,
        daylight: hour >= 7 && hour <= 19,
      );
    });

    final window = const HourlyWindowAdvisor().bestOutdoorWindow(hours);

    expect(window!.start, DateTime(2026, 10, 2, 14));
    expect(window.end, DateTime(2026, 10, 2, 20));
    expect(window.hours, 6);
  });

  test('requires at least two suitable consecutive hours', () {
    final result = const HourlyWindowAdvisor().bestOutdoorWindow([
      HourlyForecast(
        time: DateTime(2026, 10, 2, 14),
        label: 'Clear',
        weatherClass: 'clear',
        activityContext: 'outdoor',
        temperatureC: 18,
        rainProbability: 10,
        windSpeedKph: 8,
        daylight: true,
      ),
    ]);

    expect(result, isNull);
  });
}

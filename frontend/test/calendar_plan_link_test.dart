import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/services/calendar_plan_link.dart';

void main() {
  test('builds an all-day Google Calendar template in destination timezone',
      () {
    final uri = const CalendarPlanLink().build(
      date: DateTime(2026, 10, 7),
      title: 'WeatherWise day plan — Iași',
      details: 'Morning — Botanical Garden',
      location: 'Iași, Romania',
      timezone: 'Europe/Bucharest',
    );

    expect(uri.host, 'calendar.google.com');
    expect(uri.path, '/calendar/render');
    expect(uri.queryParameters['action'], 'TEMPLATE');
    expect(uri.queryParameters['dates'], '20261007/20261008');
    expect(uri.queryParameters['text'], 'WeatherWise day plan — Iași');
    expect(uri.queryParameters['details'], 'Morning — Botanical Garden');
    expect(uri.queryParameters['location'], 'Iași, Romania');
    expect(uri.queryParameters['ctz'], 'Europe/Bucharest');
  });
}

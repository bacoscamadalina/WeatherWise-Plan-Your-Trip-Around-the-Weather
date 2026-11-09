import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:weatherwise/l10n/app_strings.dart';
import 'package:weatherwise/models/advisory_notification_preferences.dart';
import 'package:weatherwise/models/daily_forecast.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/weather_advisory.dart';
import 'package:weatherwise/services/advisory_notification_planner.dart';
import 'package:weatherwise/services/advisory_notification_preferences_store.dart';

void main() {
  test('plans one timezone-local reminder per matching forecast day', () {
    const planner = AdvisoryNotificationPlanner();
    const preferences = AdvisoryNotificationPreferences(
      enabled: true,
      locationId: 1,
      locationName: 'Iași',
      hour: 8,
      minute: 30,
    );

    final result = planner.build(
      preferences: preferences,
      location: _location,
      forecasts: [
        _forecast(
          date: DateTime(2026, 10, 3),
          advisories: const [_moderate, _high],
        ),
      ],
      now: DateTime(2026, 10, 2, 12),
    );

    expect(result, hasLength(1));
    expect(result.single.scheduledAt, DateTime(2026, 10, 3, 8, 30));
    expect(result.single.title, 'Iași: Strong wind');
    expect(result.single.body, contains('1 more condition'));
    expect(result.single.body, contains('not an official weather warning'));
    expect(result.single.payload, contains('2026-10-03'));
  });

  test('high-priority mode excludes moderate-only days and past times', () {
    const planner = AdvisoryNotificationPlanner();
    const preferences = AdvisoryNotificationPreferences(
      enabled: true,
      locationId: 1,
      locationName: 'Iași',
      hour: 8,
      highOnly: true,
    );

    final result = planner.build(
      preferences: preferences,
      location: _location,
      forecasts: [
        _forecast(
          date: DateTime(2026, 10, 2),
          advisories: const [_high],
        ),
        _forecast(
          date: DateTime(2026, 10, 3),
          advisories: const [_moderate],
        ),
      ],
      now: DateTime(2026, 10, 2, 9),
    );

    expect(result, isEmpty);
  });

  test('localizes scheduled reminder content in Romanian', () {
    const planner = AdvisoryNotificationPlanner();
    const preferences = AdvisoryNotificationPreferences(
      enabled: true,
      locationId: 1,
      locationName: 'Iași',
      hour: 8,
    );

    final result = planner.build(
      preferences: preferences,
      location: _location,
      forecasts: [
        _forecast(
          date: DateTime(2026, 10, 3),
          advisories: const [_moderate, _high],
        ),
      ],
      now: DateTime(2026, 10, 2, 12),
      strings: const AppStrings(Locale('ro')),
    );

    expect(result.single.title, 'Iași: Vânt puternic');
    expect(result.single.body, contains('Încă 1 condiție de verificat'));
    expect(result.single.body, contains('nu este o avertizare meteo oficială'));
  });

  test('preferences round-trip through the memory store', () async {
    const preferences = AdvisoryNotificationPreferences(
      enabled: true,
      locationId: 1,
      locationName: 'Iași',
      hour: 7,
      minute: 45,
      highOnly: true,
    );
    final store = MemoryAdvisoryNotificationStore();

    await store.save(preferences);
    final restored = await store.load();
    final jsonRestored = AdvisoryNotificationPreferences.fromJson(
      preferences.toJson(),
    );

    expect(restored.follows(_location), isTrue);
    expect(restored.hour, 7);
    expect(restored.minute, 45);
    expect(restored.highOnly, isTrue);
    expect(jsonRestored.locationName, 'Iași');
  });
}

const _location = Location(
  id: 1,
  name: 'Iași',
  displayName: 'Iași, Romania',
  countryCode: 'RO',
  latitude: 47.1585,
  longitude: 27.6014,
  timezone: 'Europe/Bucharest',
);

const _moderate = WeatherAdvisory(
  code: 'strong_wind',
  severity: 'moderate',
  title: 'Strong wind',
  message: 'Prefer sheltered routes.',
);

const _high = WeatherAdvisory(
  code: 'storm',
  severity: 'high',
  title: 'Storm risk',
  message: 'Check official local warnings.',
);

DailyForecast _forecast({
  required DateTime date,
  required List<WeatherAdvisory> advisories,
}) =>
    DailyForecast(
      id: date.day,
      date: date,
      label: 'Windy',
      weatherClass: 'cloudy',
      activityContext: 'caution',
      minC: 7,
      maxC: 13,
      rainProbability: 20,
      windSpeedKph: 48,
      advisories: advisories,
    );

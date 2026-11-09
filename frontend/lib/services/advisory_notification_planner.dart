import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/advisory_notification_preferences.dart';
import '../models/daily_forecast.dart';
import '../models/location.dart';

class PlannedAdvisoryNotification {
  const PlannedAdvisoryNotification({
    required this.id,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime scheduledAt;
  final String title;
  final String body;
  final String payload;
}

class AdvisoryNotificationPlanner {
  const AdvisoryNotificationPlanner();

  List<PlannedAdvisoryNotification> build({
    required AdvisoryNotificationPreferences preferences,
    required Location location,
    required List<DailyForecast> forecasts,
    DateTime? now,
    AppStrings strings = const AppStrings(Locale('en')),
  }) {
    if (!preferences.follows(location)) return const [];
    final current = now ?? DateTime.now();

    return forecasts.expand((forecast) {
      final advisories = preferences.highOnly
          ? forecast.advisories.where((advisory) => advisory.isHigh).toList()
          : forecast.advisories;
      if (advisories.isEmpty) return const <PlannedAdvisoryNotification>[];

      final scheduledAt = DateTime(
        forecast.date.year,
        forecast.date.month,
        forecast.date.day,
        preferences.hour,
        preferences.minute,
      );
      if (!scheduledAt.isAfter(current.add(const Duration(minutes: 1)))) {
        return const <PlannedAdvisoryNotification>[];
      }

      final first = advisories.first;
      final extra = advisories.length > 1
          ? strings.moreConditions(advisories.length - 1)
          : '';
      return [
        PlannedAdvisoryNotification(
          id: _notificationId(location.id, forecast.date),
          scheduledAt: scheduledAt,
          title:
              '${location.name}: ${strings.advisoryTitle(first.code, first.title)}',
          body: '${strings.advisoryMessage(first.code, first.message)}$extra'
              '${strings.notificationAdvisoryDisclaimer}',
          payload: jsonEncode({
            'location_id': location.id,
            'forecast_date': _dateKey(forecast.date),
          }),
        ),
      ];
    }).toList(growable: false);
  }

  int _notificationId(int locationId, DateTime date) {
    final locationPart = locationId.abs() % 10000;
    final dayPart = date.difference(DateTime.utc(2020)).inDays.abs() % 100000;
    return locationPart * 100000 + dayPart;
  }

  String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/advisory_notification_preferences.dart';

abstract interface class AdvisoryNotificationPreferencesStore {
  Future<AdvisoryNotificationPreferences> load();

  Future<void> save(AdvisoryNotificationPreferences preferences);
}

class SharedPreferencesAdvisoryNotificationStore
    implements AdvisoryNotificationPreferencesStore {
  SharedPreferencesAdvisoryNotificationStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'weatherwise.advisory_notifications.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AdvisoryNotificationPreferences> load() async {
    final stored = await _preferences.getString(_storageKey);
    if (stored == null) return const AdvisoryNotificationPreferences();

    try {
      return AdvisoryNotificationPreferences.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      return const AdvisoryNotificationPreferences();
    } on TypeError {
      return const AdvisoryNotificationPreferences();
    }
  }

  @override
  Future<void> save(AdvisoryNotificationPreferences preferences) =>
      _preferences.setString(_storageKey, jsonEncode(preferences.toJson()));
}

class MemoryAdvisoryNotificationStore
    implements AdvisoryNotificationPreferencesStore {
  MemoryAdvisoryNotificationStore({
    AdvisoryNotificationPreferences initial =
        const AdvisoryNotificationPreferences(),
  }) : _preferences = initial;

  AdvisoryNotificationPreferences _preferences;

  @override
  Future<AdvisoryNotificationPreferences> load() async => _preferences;

  @override
  Future<void> save(AdvisoryNotificationPreferences preferences) async {
    _preferences = preferences;
  }
}

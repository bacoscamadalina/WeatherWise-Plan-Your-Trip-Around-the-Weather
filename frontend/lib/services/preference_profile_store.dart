import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/preference_profile.dart';

abstract interface class PreferenceProfileStore {
  Future<List<PreferenceProfile>> load();

  Future<void> save(List<PreferenceProfile> profiles);
}

class SharedPreferencesPreferenceProfileStore
    implements PreferenceProfileStore {
  SharedPreferencesPreferenceProfileStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'weatherwise.preference_profiles.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<PreferenceProfile>> load() async {
    final stored = await _preferences.getString(_storageKey);
    if (stored == null) return const [];

    try {
      return (jsonDecode(stored) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PreferenceProfile.fromJson)
          .toList();
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  @override
  Future<void> save(List<PreferenceProfile> profiles) => _preferences.setString(
        _storageKey,
        jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
      );
}

class MemoryPreferenceProfileStore implements PreferenceProfileStore {
  MemoryPreferenceProfileStore({List<PreferenceProfile>? initial})
      : _profiles = [...?initial];

  List<PreferenceProfile> _profiles;

  @override
  Future<List<PreferenceProfile>> load() async => [..._profiles];

  @override
  Future<void> save(List<PreferenceProfile> profiles) async {
    _profiles = [...profiles];
  }
}

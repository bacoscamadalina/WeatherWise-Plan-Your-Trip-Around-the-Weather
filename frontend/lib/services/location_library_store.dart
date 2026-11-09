import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_library.dart';

abstract interface class LocationLibraryStore {
  Future<LocationLibrary> load();

  Future<void> save(LocationLibrary library);
}

class SharedPreferencesLocationLibraryStore implements LocationLibraryStore {
  SharedPreferencesLocationLibraryStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'weatherwise.location_library.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<LocationLibrary> load() async {
    final stored = await _preferences.getString(_storageKey);
    if (stored == null) return const LocationLibrary();

    try {
      return LocationLibrary.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      return const LocationLibrary();
    } on TypeError {
      return const LocationLibrary();
    }
  }

  @override
  Future<void> save(LocationLibrary library) =>
      _preferences.setString(_storageKey, jsonEncode(library.toJson()));
}

class MemoryLocationLibraryStore implements LocationLibraryStore {
  MemoryLocationLibraryStore({LocationLibrary? initial})
      : _library = initial ?? const LocationLibrary();

  LocationLibrary _library;

  @override
  Future<LocationLibrary> load() async => LocationLibrary(
        saved: [..._library.saved],
        recent: [..._library.recent],
      );

  @override
  Future<void> save(LocationLibrary library) async {
    _library = LocationLibrary(
      saved: [...library.saved],
      recent: [...library.recent],
    );
  }
}

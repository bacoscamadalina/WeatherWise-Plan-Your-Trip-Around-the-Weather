import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/itinerary_item.dart';

abstract interface class ItineraryStore {
  Future<Map<String, Map<String, ItineraryItem>>> load();

  Future<void> save(Map<String, Map<String, ItineraryItem>> itineraries);
}

class SerializedItineraryStore implements ItineraryStore {
  SerializedItineraryStore(this._delegate);

  final ItineraryStore _delegate;
  Future<void> _saveQueue = Future<void>.value();

  @override
  Future<Map<String, Map<String, ItineraryItem>>> load() => _delegate.load();

  @override
  Future<void> save(
    Map<String, Map<String, ItineraryItem>> itineraries,
  ) {
    final snapshot = _copyItineraries(itineraries);
    final operation = _saveQueue.then((_) => _delegate.save(snapshot));
    _saveQueue = operation.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return operation;
  }
}

class SharedPreferencesItineraryStore implements ItineraryStore {
  SharedPreferencesItineraryStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'weatherwise.itineraries.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<Map<String, Map<String, ItineraryItem>>> load() async {
    final stored = await _preferences.getString(_storageKey);
    if (stored == null) return {};

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      return decoded.map(
        (itineraryKey, periods) => MapEntry(
          itineraryKey,
          (periods as Map<String, dynamic>).map(
            (period, item) => MapEntry(
              period,
              ItineraryItem.fromJson(item as Map<String, dynamic>),
            ),
          ),
        ),
      );
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  @override
  Future<void> save(
    Map<String, Map<String, ItineraryItem>> itineraries,
  ) {
    final encoded = itineraries.map(
      (itineraryKey, periods) => MapEntry(
        itineraryKey,
        periods.map(
          (period, item) => MapEntry(period, item.toJson()),
        ),
      ),
    );
    return _preferences.setString(_storageKey, jsonEncode(encoded));
  }
}

class MemoryItineraryStore implements ItineraryStore {
  MemoryItineraryStore({Map<String, Map<String, ItineraryItem>>? initial})
      : _itineraries = _copyItineraries(initial ?? const {});

  Map<String, Map<String, ItineraryItem>> _itineraries;

  @override
  Future<Map<String, Map<String, ItineraryItem>>> load() async =>
      _copyItineraries(_itineraries);

  @override
  Future<void> save(
    Map<String, Map<String, ItineraryItem>> itineraries,
  ) async {
    _itineraries = _copyItineraries(itineraries);
  }
}

Map<String, Map<String, ItineraryItem>> _copyItineraries(
  Map<String, Map<String, ItineraryItem>> source,
) =>
    source.map(
      (key, periods) => MapEntry(key, Map<String, ItineraryItem>.from(periods)),
    );

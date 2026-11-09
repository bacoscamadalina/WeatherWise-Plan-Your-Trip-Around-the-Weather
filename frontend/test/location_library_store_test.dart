import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/location_library.dart';
import 'package:weatherwise/services/location_library_store.dart';

void main() {
  test('location JSON round-trips all provider-neutral fields', () {
    const location = Location(
      id: 102,
      name: 'Paris',
      displayName: 'Paris, Texas, United States',
      countryCode: 'US',
      countryName: 'United States',
      adminArea: 'Texas',
      featureCode: 'PPLA2',
      population: 24782,
      latitude: 33.6609,
      longitude: -95.5555,
      timezone: 'America/Chicago',
    );

    final restored = Location.fromJson(location.toJson());

    expect(restored.id, location.id);
    expect(restored.displayName, location.displayName);
    expect(restored.countryName, location.countryName);
    expect(restored.adminArea, location.adminArea);
    expect(restored.featureCode, location.featureCode);
    expect(restored.population, location.population);
    expect(restored.latitude, location.latitude);
    expect(restored.longitude, location.longitude);
    expect(restored.timezone, location.timezone);
  });

  test('recent locations are unique, newest first, and capped at five', () {
    var library = const LocationLibrary();
    for (var id = 1; id <= 6; id++) {
      library = library.remember(_location(id));
    }
    library = library.remember(_location(3));

    expect(library.recent.map((location) => location.id), [3, 6, 5, 4, 2]);
  });

  test('saved locations toggle and stop at the documented limit', () {
    var library = const LocationLibrary();
    for (var id = 1; id <= LocationLibrary.maxSaved; id++) {
      library = library.toggleSaved(_location(id));
    }

    expect(library.saved, hasLength(LocationLibrary.maxSaved));
    expect(
      () => library.toggleSaved(_location(99)),
      throwsA(isA<FormatException>()),
    );
    expect(library.toggleSaved(_location(1)).isSaved(_location(1)), isFalse);
  });

  test('memory store returns defensive list copies', () async {
    final original = LocationLibrary(
      saved: [_location(1)],
      recent: [_location(2)],
    );
    final store = MemoryLocationLibraryStore(initial: original);
    final restored = await store.load();

    expect(restored.saved.single.id, 1);
    expect(identical(restored.saved, original.saved), isFalse);
    expect(identical(restored.recent, original.recent), isFalse);
  });
}

Location _location(int id) => Location(
      id: id,
      name: 'Place $id',
      displayName: 'Place $id, Testland',
      countryCode: 'TS',
      latitude: id.toDouble(),
      longitude: -id.toDouble(),
      timezone: 'UTC',
    );

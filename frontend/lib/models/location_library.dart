import 'location.dart';

class LocationLibrary {
  const LocationLibrary({
    this.saved = const [],
    this.recent = const [],
  });

  static const maxSaved = 12;
  static const maxRecent = 5;

  final List<Location> saved;
  final List<Location> recent;

  bool isSaved(Location location) =>
      saved.any((item) => item.id == location.id);

  LocationLibrary remember(Location location) => copyWith(
        recent: [
          location,
          ...recent.where((item) => item.id != location.id),
        ].take(maxRecent).toList(growable: false),
      );

  LocationLibrary toggleSaved(Location location) {
    if (isSaved(location)) {
      return copyWith(
        saved: saved
            .where((item) => item.id != location.id)
            .toList(growable: false),
      );
    }
    if (saved.length >= maxSaved) {
      throw const FormatException('Saved-place limit reached.');
    }
    return copyWith(saved: [...saved, location]);
  }

  LocationLibrary copyWith({
    List<Location>? saved,
    List<Location>? recent,
  }) =>
      LocationLibrary(
        saved: saved ?? this.saved,
        recent: recent ?? this.recent,
      );

  factory LocationLibrary.fromJson(Map<String, dynamic> json) {
    List<Location> decode(String key, int limit) =>
        ((json[key] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Location.fromJson)
            .fold<List<Location>>([], (locations, location) {
              if (!locations.any((item) => item.id == location.id)) {
                locations.add(location);
              }
              return locations;
            })
            .take(limit)
            .toList(growable: false);

    return LocationLibrary(
      saved: decode('saved', maxSaved),
      recent: decode('recent', maxRecent),
    );
  }

  Map<String, dynamic> toJson() => {
        'saved': saved.map((location) => location.toJson()).toList(),
        'recent': recent.map((location) => location.toJson()).toList(),
      };
}

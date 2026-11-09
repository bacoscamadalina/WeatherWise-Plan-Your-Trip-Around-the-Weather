import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/preference_profile.dart';
import 'package:weatherwise/models/recommendation_filters.dart';
import 'package:weatherwise/services/preference_profile_store.dart';

void main() {
  test('preference filters round-trip through profile JSON', () {
    const profile = PreferenceProfile(
      id: 'culture-nearby',
      name: 'Nearby culture',
      filters: RecommendationFilters(
        type: 'activity',
        activityKind: 'culture',
        setting: 'indoor',
        maxDistanceKm: 5,
        timeOfDay: 'afternoon',
      ),
    );

    final restored = PreferenceProfile.fromJson(profile.toJson());

    expect(restored.id, profile.id);
    expect(restored.name, profile.name);
    expect(restored.filters, profile.filters);
  });

  test('memory store returns defensive profile lists', () async {
    const profile = PreferenceProfile(
      id: 'movie-night',
      name: 'Movie night',
      filters: RecommendationFilters(type: 'movie', genre: 'comedy'),
    );
    final store = MemoryPreferenceProfileStore(initial: const [profile]);

    final first = await store.load();
    first.clear();

    expect(await store.load(), hasLength(1));
  });
}

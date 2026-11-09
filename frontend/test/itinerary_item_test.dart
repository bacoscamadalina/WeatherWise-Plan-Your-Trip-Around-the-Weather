import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/itinerary_item.dart';

void main() {
  test('persists provider-derived recommended periods', () {
    const item = ItineraryItem(
      sourceKey: 'activity:test:1',
      sourceType: 'activity',
      title: 'Garden tour',
      subtitle: 'Outdoor activity',
      period: 'morning',
      indoor: false,
      recommendedPeriods: ['morning'],
    );

    final restored = ItineraryItem.fromJson(item.toJson());

    expect(restored.recommendedPeriods, ['morning']);
  });

  test('keeps older saved plans compatible', () {
    final restored = ItineraryItem.fromJson(const {
      'source_key': 'activity:test:1',
      'source_type': 'activity',
      'title': 'Garden tour',
      'subtitle': 'Outdoor activity',
      'period': 'morning',
    });

    expect(restored.recommendedPeriods, isEmpty);
  });
}

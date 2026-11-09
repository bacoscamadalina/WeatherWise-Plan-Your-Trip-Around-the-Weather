import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/plan_recommendation.dart';

void main() {
  test('parses provider-neutral planning notes', () {
    final recommendation = PlanRecommendation.fromJson({
      'id': 12,
      'type': 'activity',
      'title': 'Botanical Garden',
      'summary': 'An outdoor walk.',
      'indoor': false,
      'genres': <String>[],
      'tags': <String>['garden'],
      'score': 72,
      'reason': 'Makes the most of the clear outdoor window',
      'planning_notes': [
        {
          'code': 'very_high_uv',
          'severity': 'moderate',
          'message':
              'UV peaks at 8.5; favor shade around midday and use sun protection.',
        },
      ],
    });

    expect(recommendation.planningNotes, hasLength(1));
    expect(recommendation.planningNotes.single.code, 'very_high_uv');
    expect(recommendation.planningNotes.single.severity, 'moderate');
    expect(recommendation.planningNotes.single.message, contains('shade'));
  });

  test('defaults planning notes to an empty list', () {
    final recommendation = PlanRecommendation.fromJson({
      'id': 13,
      'type': 'movie',
      'title': 'Rain Story',
      'summary': 'An indoor movie.',
      'indoor': true,
      'genres': <String>['mystery'],
      'tags': <String>['movie'],
      'score': 80,
      'reason': 'A sheltered choice',
    });

    expect(recommendation.planningNotes, isEmpty);
  });
}

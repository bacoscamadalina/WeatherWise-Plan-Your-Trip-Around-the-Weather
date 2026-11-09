import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/plan_recommendation.dart';
import 'package:weatherwise/services/day_plan_builder.dart';

void main() {
  const builder = DayPlanBuilder();
  const museum = PlanRecommendation(
    id: 1,
    type: 'activity',
    title: 'Museum',
    summary: 'Culture',
    indoor: true,
    genres: [],
    tags: ['museum'],
    score: 80,
    reason: 'Weather fit',
    provider: 'wikipedia',
    recommendedPeriods: ['morning', 'afternoon'],
  );
  const garden = PlanRecommendation(
    id: 2,
    type: 'activity',
    title: 'Garden',
    summary: 'Nature',
    indoor: false,
    genres: [],
    tags: ['garden'],
    score: 76,
    reason: 'Weather fit',
    provider: 'wikipedia',
    recommendedPeriods: ['morning', 'afternoon'],
  );
  const movie = PlanRecommendation(
    id: 3,
    type: 'movie',
    title: 'Film',
    summary: 'Evening film',
    indoor: true,
    genres: ['drama'],
    tags: ['movie'],
    score: 72,
    reason: 'Weather fit',
    provider: 'tmdb',
    recommendedPeriods: ['evening'],
  );

  test('builds a distinct morning afternoon and evening plan', () {
    final plan = builder.build(recommendations: [museum, garden, movie]);

    expect(plan['morning'], museum);
    expect(plan['afternoon'], garden);
    expect(plan['evening'], movie);
  });

  test('preserves occupied periods and does not reuse their source', () {
    final plan = builder.build(
      recommendations: [museum, garden, movie],
      occupiedPeriods: const {'morning'},
      usedSourceKeys: {builder.sourceKey(museum)},
    );

    expect(plan.containsKey('morning'), isFalse);
    expect(plan['afternoon'], garden);
    expect(plan['evening'], movie);
  });
}

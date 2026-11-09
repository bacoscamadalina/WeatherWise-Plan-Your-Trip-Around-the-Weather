import '../models/plan_recommendation.dart';

class DayPlanBuilder {
  const DayPlanBuilder();

  static const periods = ['morning', 'afternoon', 'evening'];

  Map<String, PlanRecommendation> build({
    required List<PlanRecommendation> recommendations,
    Set<String> occupiedPeriods = const {},
    Set<String> usedSourceKeys = const {},
  }) {
    final plan = <String, PlanRecommendation>{};
    final used = Set<String>.from(usedSourceKeys);

    for (final period in periods) {
      if (occupiedPeriods.contains(period)) continue;

      final candidates = recommendations.indexed
          .where((entry) =>
              !used.contains(sourceKey(entry.$2)) &&
              _periodsFor(entry.$2).contains(period))
          .toList(growable: false)
        ..sort((left, right) {
          final scoreComparison =
              _score(right.$2, period).compareTo(_score(left.$2, period));
          return scoreComparison != 0
              ? scoreComparison
              : left.$1.compareTo(right.$1);
        });

      if (candidates.isEmpty) continue;
      final recommendation = candidates.first.$2;
      plan[period] = recommendation;
      used.add(sourceKey(recommendation));
    }

    return plan;
  }

  String sourceKey(PlanRecommendation recommendation) =>
      '${recommendation.type}:${recommendation.provider ?? 'local'}:${recommendation.id}';

  List<String> _periodsFor(PlanRecommendation recommendation) {
    if (recommendation.recommendedPeriods.isNotEmpty) {
      return recommendation.recommendedPeriods;
    }
    if (recommendation.eventTime != null) {
      final hour = int.tryParse(recommendation.eventTime!.split(':').first);
      if (hour != null) {
        if (hour < 12) return const ['morning'];
        if (hour < 17) return const ['afternoon'];
        return const ['evening'];
      }
    }
    return recommendation.type == 'movie'
        ? const ['evening']
        : const ['morning', 'afternoon'];
  }

  int _score(PlanRecommendation recommendation, String period) {
    final typeBonus = switch ((period, recommendation.type)) {
      ('morning', 'activity') => 30,
      ('afternoon', 'activity') => 30,
      ('afternoon', 'event') => 24,
      ('evening', 'event') => 55,
      ('evening', 'movie') => 50,
      ('evening', 'activity') => 8,
      _ => 0,
    };
    return recommendation.score + typeBonus;
  }
}

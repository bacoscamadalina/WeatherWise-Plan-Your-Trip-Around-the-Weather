import 'dart:math' as math;

import '../models/daily_forecast.dart';

class DayOpportunity {
  const DayOpportunity({
    required this.forecast,
    required this.score,
    required this.reason,
  });

  final DailyForecast forecast;
  final double score;
  final String reason;
}

class BestDayAdvisor {
  const BestDayAdvisor();

  DayOpportunity? bestOutdoorDay(List<DailyForecast> forecasts) {
    if (forecasts.isEmpty) return null;

    final ranked = forecasts
        .map(
          (forecast) => DayOpportunity(
            forecast: forecast,
            score: _outdoorScore(forecast),
            reason: _reason(forecast),
          ),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final scoreOrder = b.score.compareTo(a.score);
        if (scoreOrder != 0) return scoreOrder;
        return a.forecast.date.compareTo(b.forecast.date);
      });
    return ranked.first;
  }

  double _outdoorScore(DailyForecast forecast) {
    final contextScore = switch (forecast.activityContext) {
      'outdoor' => 30.0,
      'flexible' => 18.0,
      'indoor' => -16.0,
      'caution' => -24.0,
      _ => 0.0,
    };
    final rainScore = (100 - forecast.rainProbability) * .42;
    final windScore = math.max(0, 34 - forecast.windSpeedKph) * .65;
    final average = (forecast.minC + forecast.maxC) / 2;
    final comfortScore = math.max(0, 20 - (average - 20).abs() * 1.5);
    final uvPenalty = math.max(0, (forecast.uvIndexMax ?? 0) - 7) * 4;
    final advisoryPenalty = forecast.hasHighAdvisory
        ? 36.0
        : forecast.advisories.isNotEmpty
            ? 18.0
            : 0.0;
    return contextScore +
        rainScore +
        windScore +
        comfortScore -
        uvPenalty -
        advisoryPenalty;
  }

  String _reason(DailyForecast forecast) {
    final hasVeryHighUv = (forecast.uvIndexMax ?? 0) >= 8;
    final uvReason = hasVeryHighUv
        ? 'UV peaks at ${forecast.uvIndexMax!.toStringAsFixed(1)}; '
            'favor shade around midday.'
        : null;

    if (forecast.rainProbability <= 15 && forecast.windSpeedKph < 22) {
      return uvReason ?? 'Low rain risk and manageable wind.';
    }
    if (forecast.rainProbability <= 30) {
      return uvReason ?? 'One of the drier options in this outlook.';
    }
    if (forecast.windSpeedKph < 18) {
      return uvReason ?? 'Calmer wind makes flexible plans easier.';
    }
    final poorOutlookReason =
        'Best available balance: ${forecast.rainProbability}% rain and '
        '${forecast.windSpeedKph.round()} km/h wind.';
    return uvReason == null
        ? poorOutlookReason
        : '$poorOutlookReason $uvReason';
  }
}

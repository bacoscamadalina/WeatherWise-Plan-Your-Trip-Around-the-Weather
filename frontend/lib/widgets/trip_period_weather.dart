import 'package:flutter/material.dart';

import '../models/trip_plan.dart';
import '../theme/atlas_theme.dart';

class TripPeriodWeather extends StatelessWidget {
  const TripPeriodWeather({
    required this.item,
    required this.romanian,
    super.key,
  });

  final TripPlanItem item;
  final bool romanian;

  @override
  Widget build(BuildContext context) {
    final raw = item.metadata['period_weather'];
    if (raw is! Map) return const SizedBox.shrink();
    final weather = Map<String, dynamic>.from(raw);
    final weatherClass = weather['weather_class'] as String? ?? 'cloudy';
    final rain = (weather['precipitation_probability'] as num?)?.round();
    final minimum = (weather['temperature_min_c'] as num?)?.round();
    final maximum = (weather['temperature_max_c'] as num?)?.round();
    final hourly = weather['source'] == 'hourly';
    final foreground = _foreground(weatherClass);

    final condition = _condition(weatherClass, rain);
    final temperature = minimum == null
        ? null
        : minimum == maximum
            ? '$minimum°C'
            : '$minimum–$maximum°C';
    final detail = [
      condition,
      if (temperature != null) temperature,
      if (rain != null) romanian ? 'ploaie max. $rain%' : 'rain up to $rain%',
    ].join(' · ');
    final source = hourly
        ? (romanian ? 'prognoză orară' : 'hourly forecast')
        : (romanian ? 'estimare zilnică' : 'daily estimate');

    return Semantics(
      label: '$detail, $source',
      container: true,
      child: Container(
        key: ValueKey('trip-period-weather-${item.id}'),
        margin: const EdgeInsets.only(top: 7, bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _background(weatherClass),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(_icon(weatherClass), size: 18, color: foreground),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: detail,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: ' · $source',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _condition(String weatherClass, int? rain) => switch (weatherClass) {
        'clear' => romanian ? 'Interval senin' : 'Clear window',
        'rain' => romanian ? 'Ploaie în interval' : 'Rain during this window',
        'snow' => romanian ? 'Ninsoare în interval' : 'Snow during this window',
        'storm' => romanian ? 'Furtună posibilă' : 'Possible storm',
        _ => rain != null && rain >= 40
            ? (romanian ? 'Nori, posibilă ploaie' : 'Cloudy, rain possible')
            : (romanian ? 'Interval noros' : 'Cloudy window'),
      };

  Color _background(String weatherClass) => switch (weatherClass) {
        'clear' => AtlasColors.gold.withValues(alpha: .2),
        'rain' || 'storm' => AtlasColors.sky.withValues(alpha: .72),
        'snow' => const Color(0xFFE8F2F6),
        _ => AtlasColors.line.withValues(alpha: .55),
      };

  Color _foreground(String weatherClass) => switch (weatherClass) {
        'clear' => const Color(0xFF765000),
        'rain' || 'storm' => AtlasColors.ink,
        _ => AtlasColors.mutedInk,
      };

  IconData _icon(String weatherClass) => switch (weatherClass) {
        'clear' => Icons.wb_sunny_outlined,
        'rain' => Icons.water_drop_outlined,
        'snow' => Icons.ac_unit_rounded,
        'storm' => Icons.thunderstorm_outlined,
        _ => Icons.cloud_outlined,
      };
}

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/daily_forecast.dart';

class ForecastCard extends StatelessWidget {
  const ForecastCard({
    required this.forecast,
    required this.onPressed,
    required this.expanded,
    super.key,
  });

  final DailyForecast forecast;
  final VoidCallback onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 62,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.shortWeekday(forecast.date),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${forecast.date.day} ${strings.shortMonth(forecast.date)}',
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _iconFor(forecast.weatherClass),
                    size: 30,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.weatherLabel(forecast.label),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          switch (forecast.activityContext) {
                            'indoor' => strings.indoorContext,
                            'outdoor' => strings.outdoorContext,
                            'caution' => strings.cautionContext,
                            _ => strings.flexibleContext,
                          },
                          style: TextStyle(color: colors.primary),
                        ),
                        Text(
                          '${strings.rain(forecast.rainProbability)} · ${strings.wind(forecast.windSpeedKph)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${forecast.maxC.round()}°\n${forecast.minC.round()}°',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      size: 17, color: colors.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      expanded ? strings.hideIdeas : strings.seeIdeas,
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String value) => switch (value) {
        'clear' => Icons.wb_sunny_outlined,
        'rain' => Icons.water_drop_outlined,
        'snow' => Icons.ac_unit,
        'storm' => Icons.thunderstorm_outlined,
        'fog' => Icons.foggy,
        _ => Icons.cloud_outlined,
      };
}

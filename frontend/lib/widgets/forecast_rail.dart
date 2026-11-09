import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/daily_forecast.dart';
import '../theme/atlas_theme.dart';
import 'weather_visuals.dart';

class ForecastRail extends StatelessWidget {
  const ForecastRail({
    required this.forecasts,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<DailyForecast> forecasts;
  final int? selectedId;
  final ValueChanged<DailyForecast> onSelected;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.35);
    return SizedBox(
      height: 148 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: forecasts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final forecast = forecasts[index];
          return _ForecastDay(
            forecast: forecast,
            selected: forecast.id == selectedId,
            onTap: () => onSelected(forecast),
          );
        },
      ),
    );
  }
}

class _ForecastDay extends StatelessWidget {
  const _ForecastDay({
    required this.forecast,
    required this.selected,
    required this.onTap,
  });

  final DailyForecast forecast;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final visuals = WeatherVisuals.forForecast(forecast);
    final accent = visuals.accent(brightness);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${strings.shortWeekday(forecast.date)}, ${strings.weatherLabel(forecast.label)}',
      child: AnimatedContainer(
        key: ValueKey('forecast-day-${forecast.id}'),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: selected ? 152 : 142,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  accent.withValues(alpha: .08),
                  AtlasColors.paper,
                )
              : AtlasColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : AtlasColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Container(height: 4, color: accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings.shortWeekday(forecast.date),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Semantics(
                          label: forecast.advisories.isEmpty
                              ? null
                              : forecast.hasHighAdvisory
                                  ? strings.highPriorityAdvisory
                                  : strings.planningAdvisory,
                          child: SizedBox.square(
                            dimension: 24,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Icon(
                                    _iconFor(forecast.weatherClass),
                                    size: 22,
                                    color: accent,
                                  ),
                                ),
                                if (forecast.advisories.isNotEmpty)
                                  Positioned(
                                    right: -1,
                                    top: -2,
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      size: 13,
                                      color: forecast.hasHighAdvisory
                                          ? colors.error
                                          : colors.tertiary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${forecast.date.day}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      '${forecast.maxC.round()}°  ${forecast.minC.round()}°',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      strings.rainPercent(forecast.rainProbability),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
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
        'snow' => Icons.ac_unit_rounded,
        'storm' => Icons.thunderstorm_outlined,
        'fog' => Icons.foggy,
        _ => Icons.cloud_outlined,
      };
}

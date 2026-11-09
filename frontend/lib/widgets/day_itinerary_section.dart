import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/itinerary_item.dart';
import '../models/hourly_forecast.dart';
import '../services/itinerary_weather_planner.dart';
import '../services/adaptive_day_plan.dart';

class DayItinerarySection extends StatelessWidget {
  const DayItinerarySection({
    required this.items,
    required this.onRemove,
    required this.onClear,
    required this.onCopy,
    required this.onCalendar,
    required this.onRoute,
    required this.onSuggest,
    required this.canSuggest,
    required this.hourlyForecasts,
    required this.onAdapt,
    this.adapting = false,
    this.weatherPlanner = const ItineraryWeatherPlanner(),
    this.adaptivePlan = const AdaptiveDayPlan(),
    super.key,
  });

  static const _periods = ['morning', 'afternoon', 'evening'];

  final List<ItineraryItem> items;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;
  final VoidCallback onCopy;
  final VoidCallback onCalendar;
  final VoidCallback? onRoute;
  final VoidCallback onSuggest;
  final bool canSuggest;
  final List<HourlyForecast> hourlyForecasts;
  final ItineraryWeatherPlanner weatherPlanner;
  final AdaptiveDayPlan adaptivePlan;
  final VoidCallback? onAdapt;
  final bool adapting;

  @override
  Widget build(BuildContext context) {
    final byPeriod = {for (final item in items) item.period: item};
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    final weatherByPeriod = weatherPlanner.build(
      hours: hourlyForecasts,
      items: items,
    );
    final riskyPeriods = adaptivePlan.riskyPeriods(
      items: items,
      weather: weatherByPeriod,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.yourDayPlan,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.dayPlanSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty) ...[
                IconButton(
                  key: const ValueKey('copy-day-plan'),
                  tooltip: strings.copyDayPlan,
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_all_outlined, size: 20),
                ),
                IconButton(
                  tooltip: strings.clearDayPlan,
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                ),
              ],
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onRoute != null)
                  OutlinedButton.icon(
                    key: const ValueKey('route-day-plan'),
                    onPressed: onRoute,
                    icon: const Icon(Icons.route_outlined, size: 19),
                    label: Text(strings.openDayRoute),
                  ),
                OutlinedButton.icon(
                  key: const ValueKey('calendar-day-plan'),
                  onPressed: onCalendar,
                  icon: const Icon(Icons.calendar_month_outlined, size: 19),
                  label: Text(strings.openPlanInCalendar),
                ),
              ],
            ),
          ],
          if (canSuggest) ...[
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: OutlinedButton.icon(
                key: const ValueKey('suggest-day-plan'),
                onPressed: onSuggest,
                icon: const Icon(Icons.auto_awesome_outlined, size: 19),
                label: Text(
                  items.isEmpty
                      ? strings.suggestDayPlan
                      : strings.completeDayPlan,
                ),
              ),
            ),
          ],
          if (riskyPeriods.isNotEmpty && onAdapt != null) ...[
            const SizedBox(height: 10),
            Semantics(
              label: strings.planWeatherRisk(riskyPeriods.length),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.umbrella_outlined,
                        size: 20, color: colors.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.planWeatherRisk(riskyPeriods.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onTertiaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('adapt-day-plan'),
                      onPressed: adapting ? null : onAdapt,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (adapting) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(adapting
                              ? strings.adaptingDayPlan
                              : strings.adaptDayPlan),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          for (var index = 0; index < _periods.length; index++) ...[
            _PeriodRow(
              period: _periods[index],
              item: byPeriod[_periods[index]],
              weather: weatherByPeriod[_periods[index]],
              onRemove: onRemove,
            ),
            if (index < _periods.length - 1)
              Divider(height: 1, color: colors.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({
    required this.period,
    required this.item,
    required this.onRemove,
    required this.weather,
  });

  final String period;
  final ItineraryItem? item;
  final ValueChanged<String> onRemove;
  final ItineraryPeriodWeather? weather;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Icon(
              switch (period) {
                'morning' => Icons.wb_sunny_outlined,
                'afternoon' => Icons.light_mode_outlined,
                _ => Icons.nights_stay_outlined,
              },
              size: 20,
              color: item == null ? colors.outline : colors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: item == null
                  ? Column(
                      key: ValueKey('empty-$period'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.of(context).emptyPeriod(period),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                        if (weather != null) _WeatherLine(weather: weather!),
                      ],
                    )
                  : Column(
                      key: ValueKey(item!.sourceKey),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${AppStrings.of(context).filterValue(period)} · ${item!.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          item!.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (weather != null) _WeatherLine(weather: weather!),
                      ],
                    ),
            ),
          ),
          if (item != null)
            IconButton(
              key: ValueKey('remove-plan-$period'),
              tooltip: AppStrings.of(context).removeFromPeriod(period),
              onPressed: () => onRemove(period),
              icon: const Icon(Icons.close, size: 20),
            ),
        ],
      ),
    );
  }
}

class _WeatherLine extends StatelessWidget {
  const _WeatherLine({required this.weather});

  final ItineraryPeriodWeather weather;

  @override
  Widget build(BuildContext context) {
    final forecast = weather.forecast;
    final strings = AppStrings.of(context);
    final time = '${forecast.time.hour.toString().padLeft(2, '0')}:00';
    return Semantics(
      label: strings.hourlySemantics(
        time,
        forecast.label,
        forecast.temperatureC,
        forecast.rainProbability,
      ),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            strings.itineraryWeatherSummary(
              time,
              forecast.label,
              forecast.temperatureC,
              forecast.rainProbability,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

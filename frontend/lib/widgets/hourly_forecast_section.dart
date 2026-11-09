import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/hourly_forecast.dart';
import '../services/hourly_window_advisor.dart';

class HourlyForecastSection extends StatelessWidget {
  const HourlyForecastSection({
    required this.hours,
    required this.loading,
    required this.error,
    required this.onRetry,
    this.advisor = const HourlyWindowAdvisor(),
    super.key,
  });

  final List<HourlyForecast> hours;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final HourlyWindowAdvisor advisor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    final visibleHours = hours
        .where(
            (hour) => hour.time.hour.between(6, 21) && hour.time.hour % 3 == 0)
        .toList(growable: false);
    final bestWindow = advisor.bestOutdoorWindow(hours);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // Romanian labels such as „șanse de ploaie” need a second line at the
    // compact 64 px tick width. Keep enough vertical room for translated copy.
    final timelineHeight = 128.0 * (textScale < 1 ? 1.0 : textScale);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    strings.dayUnfolds,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                  ),
                ),
              ],
            ),
            if (loading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                strings.findingWeatherWindows,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ] else if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: colors.error)),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(strings.retryHourly),
              ),
            ] else if (hours.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                strings.hourlyUnavailable,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Text(
                bestWindow == null
                    ? strings.noOutdoorWindow
                    : strings.bestOutdoorWindow(
                        _time(bestWindow.start), _time(bestWindow.end)),
                style: TextStyle(
                  color: bestWindow == null
                      ? colors.onSurfaceVariant
                      : colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bestWindow == null
                    ? strings.indoorAlternative
                    : strings.calmerHours(bestWindow.hours),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: timelineHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleHours.length,
                  separatorBuilder: (_, __) => VerticalDivider(
                    width: 22,
                    indent: 8,
                    endIndent: 8,
                    color: colors.outlineVariant,
                  ),
                  itemBuilder: (context, index) => _HourTick(
                    hour: visibleHours[index],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:00';
}

class _HourTick extends StatelessWidget {
  const _HourTick({required this.hour});

  final HourlyForecast hour;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: AppStrings.of(context).hourlySemantics(
        '${hour.time.hour}:00',
        hour.label,
        hour.temperatureC,
        hour.rainProbability,
      ),
      child: ExcludeSemantics(
        child: SizedBox(
          width: 64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hour.time.hour.toString().padLeft(2, '0')}:00',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(
                    _icon(hour.weatherClass),
                    size: 20,
                    color: colors.primary,
                  ),
                  const Spacer(),
                  Text(
                    '${hour.temperatureC.round()}°',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.of(context).rainPercent(hour.rainProbability),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(String weatherClass) => switch (weatherClass) {
        'clear' => Icons.wb_sunny_outlined,
        'rain' => Icons.water_drop_outlined,
        'snow' => Icons.ac_unit_rounded,
        'storm' => Icons.thunderstorm_outlined,
        'fog' => Icons.foggy,
        _ => Icons.cloud_outlined,
      };
}

extension on int {
  bool between(int min, int max) => this >= min && this <= max;
}

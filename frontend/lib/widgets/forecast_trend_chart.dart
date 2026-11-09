import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/daily_forecast.dart';
import '../services/best_day_advisor.dart';

class ForecastTrendChart extends StatelessWidget {
  const ForecastTrendChart({
    required this.forecasts,
    required this.selectedId,
    required this.onSelected,
    this.advisor = const BestDayAdvisor(),
    super.key,
  });

  final List<DailyForecast> forecasts;
  final int? selectedId;
  final ValueChanged<DailyForecast> onSelected;
  final BestDayAdvisor advisor;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (forecasts.isEmpty) {
      return Text(strings.trendUnavailable);
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final selected = forecasts.firstWhere(
      (forecast) => forecast.id == selectedId,
      orElse: () => forecasts.first,
    );
    final bestDay =
        forecasts.length < 2 ? null : advisor.bestOutdoorDay(forecasts);
    final cellWidth = 52.0 * math.max(1.0, textScale);
    final chartHeight = 188.0 * math.max(1.0, textScale);

    return Semantics(
      container: true,
      label: strings.trendSemantics,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.outlineVariant),
            bottom: BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final title = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.trendTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        strings.trendSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                  if (constraints.maxWidth < 600 || textScale > 1.3) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 10),
                        _Legend(colors: colors, strings: strings),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 16),
                      _Legend(colors: colors, strings: strings),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              if (bestDay != null) ...[
                _BestDayPrompt(
                  opportunity: bestDay,
                  onPressed: () => onSelected(bestDay.forecast),
                ),
                const SizedBox(height: 12),
              ],
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: Text(
                  key: ValueKey(selected.id),
                  strings.selectedForecastSummary(
                    selected.date,
                    selected.maxC,
                    selected.minC,
                    selected.rainProbability,
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.max(
                    constraints.maxWidth,
                    forecasts.length * cellWidth,
                  );
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      height: chartHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              key: const ValueKey('forecast-trend-painter'),
                              painter: _ForecastTrendPainter(
                                forecasts: forecasts,
                                selectedId: selected.id,
                                colors: colors,
                                textScale: textScale,
                                cellWidth: width / forecasts.length,
                                weekdays: List.generate(
                                  7,
                                  (index) => strings.shortWeekday(
                                    DateTime(2026, 1, 5 + index),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Row(
                              children: [
                                for (final forecast in forecasts)
                                  SizedBox(
                                    width: width / forecasts.length,
                                    child: Semantics(
                                      button: true,
                                      selected: forecast.id == selected.id,
                                      label: strings.forecastSemantics(
                                        forecast.label,
                                        forecast.date,
                                        forecast.maxC,
                                        forecast.minC,
                                        forecast.rainProbability,
                                      ),
                                      child: InkWell(
                                        key: ValueKey(
                                          'forecast-trend-day-${forecast.id}',
                                        ),
                                        onTap: () => onSelected(forecast),
                                        splashColor: colors.primary.withValues(
                                          alpha: .10,
                                        ),
                                        highlightColor: colors.primary
                                            .withValues(alpha: .05),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestDayPrompt extends StatelessWidget {
  const _BestDayPrompt({
    required this.opportunity,
    required this.onPressed,
  });

  final DayOpportunity opportunity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final forecast = opportunity.forecast;
    final reason = _reason(strings, forecast);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Semantics(
              label: strings.bestOutdoorSemantics(forecast.date, reason),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Icon(
                      Icons.eco_outlined,
                      color: colors.onPrimaryContainer,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.bestOutdoorTitle(forecast.date),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reason,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onPrimaryContainer,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            if (constraints.maxWidth < 560 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      key: const ValueKey('plan-best-outdoor-day'),
                      onPressed: onPressed,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      iconAlignment: IconAlignment.end,
                      label: Text(strings.planThisDay),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: copy),
                const SizedBox(width: 10),
                TextButton.icon(
                  key: const ValueKey('plan-best-outdoor-day'),
                  onPressed: onPressed,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  iconAlignment: IconAlignment.end,
                  label: Text(strings.planThisDay),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _reason(AppStrings strings, DailyForecast forecast) {
    final highUv = (forecast.uvIndexMax ?? 0) >= 8;
    final uvReason = highUv
        ? strings.uvReason(forecast.uvIndexMax!.toStringAsFixed(1))
        : null;
    if (forecast.rainProbability <= 15 && forecast.windSpeedKph < 22) {
      return uvReason ?? strings.lowRainReason;
    }
    if (forecast.rainProbability <= 30) {
      return uvReason ?? strings.drierReason;
    }
    if (forecast.windSpeedKph < 18) {
      return uvReason ?? strings.calmerWindReason;
    }
    final balance = strings.bestBalanceReason(
      forecast.rainProbability,
      forecast.windSpeedKph.round(),
    );
    return uvReason == null ? balance : '$balance $uvReason';
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.colors, required this.strings});

  final ColorScheme colors;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: strings.legendSemantics,
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: [
            _LegendItem(color: colors.tertiary, label: strings.high),
            _LegendItem(color: colors.outline, label: strings.lowLabel),
            _LegendItem(
              color: colors.primary,
              label: strings.rainChance,
              bar: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.bar = false,
  });

  final Color color;
  final String label;
  final bool bar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: bar ? 5 : 14,
          height: bar ? 12 : 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ForecastTrendPainter extends CustomPainter {
  const _ForecastTrendPainter({
    required this.forecasts,
    required this.selectedId,
    required this.colors,
    required this.textScale,
    required this.cellWidth,
    required this.weekdays,
  });

  final List<DailyForecast> forecasts;
  final int selectedId;
  final ColorScheme colors;
  final double textScale;
  final double cellWidth;
  final List<String> weekdays;

  @override
  void paint(Canvas canvas, Size size) {
    final labelHeight = 34.0 * math.max(1.0, textScale);
    final plot = Rect.fromLTWH(0, 8, size.width, size.height - labelHeight - 8);
    final temperatures = forecasts
        .expand((forecast) => [forecast.minC, forecast.maxC])
        .toList(growable: false);
    var minTemperature = temperatures.reduce(math.min).floorToDouble() - 2;
    var maxTemperature = temperatures.reduce(math.max).ceilToDouble() + 2;
    if (maxTemperature - minTemperature < 8) {
      final middle = (maxTemperature + minTemperature) / 2;
      minTemperature = middle - 4;
      maxTemperature = middle + 4;
    }

    final selectedIndex = forecasts.indexWhere(
      (forecast) => forecast.id == selectedId,
    );
    if (selectedIndex >= 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            selectedIndex * cellWidth + 4,
            0,
            cellWidth - 8,
            size.height,
          ),
          const Radius.circular(12),
        ),
        Paint()..color = colors.secondaryContainer.withValues(alpha: .52),
      );
    }

    final gridPaint = Paint()
      ..color = colors.outlineVariant.withValues(alpha: .62)
      ..strokeWidth = 1;
    for (var step = 0; step <= 2; step++) {
      final y = plot.top + (plot.height * step / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    double xFor(int index) => cellWidth * index + cellWidth / 2;
    double yFor(double temperature) {
      final portion =
          (temperature - minTemperature) / (maxTemperature - minTemperature);
      return plot.bottom - portion * plot.height;
    }

    final highPath = Path();
    final lowPath = Path();
    final bandPath = Path();
    for (var index = 0; index < forecasts.length; index++) {
      final x = xFor(index);
      final highY = yFor(forecasts[index].maxC);
      final lowY = yFor(forecasts[index].minC);
      if (index == 0) {
        highPath.moveTo(x, highY);
        lowPath.moveTo(x, lowY);
        bandPath.moveTo(x, highY);
      } else {
        highPath.lineTo(x, highY);
        lowPath.lineTo(x, lowY);
        bandPath.lineTo(x, highY);
      }
    }
    for (var index = forecasts.length - 1; index >= 0; index--) {
      bandPath.lineTo(xFor(index), yFor(forecasts[index].minC));
    }
    bandPath.close();
    canvas.drawPath(
      bandPath,
      Paint()..color = colors.tertiary.withValues(alpha: .09),
    );

    for (var index = 0; index < forecasts.length; index++) {
      final forecast = forecasts[index];
      final rainHeight = plot.height * .32 * forecast.rainProbability / 100;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            xFor(index) - 5,
            plot.bottom - rainHeight,
            10,
            rainHeight,
          ),
          const Radius.circular(5),
        ),
        Paint()..color = colors.primary.withValues(alpha: .42),
      );
    }

    canvas.drawPath(
      lowPath,
      Paint()
        ..color = colors.outline
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      highPath,
      Paint()
        ..color = colors.tertiary
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var index = 0; index < forecasts.length; index++) {
      final forecast = forecasts[index];
      final selected = forecast.id == selectedId;
      final highPoint = Offset(xFor(index), yFor(forecast.maxC));
      final lowPoint = Offset(xFor(index), yFor(forecast.minC));
      canvas.drawCircle(
        highPoint,
        selected ? 4.5 : 3,
        Paint()..color = colors.tertiary,
      );
      canvas.drawCircle(
        lowPoint,
        selected ? 4 : 2.5,
        Paint()..color = colors.outline,
      );

      final label = TextPainter(
        text: TextSpan(
          text: '${weekdays[forecast.date.weekday - 1]}\n${forecast.date.day}',
          style: TextStyle(
            color: selected ? colors.onSecondaryContainer : colors.onSurface,
            fontSize: 11 * textScale,
            height: 1.2,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: cellWidth - 4);
      label.paint(
        canvas,
        Offset(xFor(index) - label.width / 2, plot.bottom + 7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ForecastTrendPainter oldDelegate) {
    return oldDelegate.forecasts != forecasts ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.colors != colors ||
        oldDelegate.textScale != textScale ||
        oldDelegate.cellWidth != cellWidth ||
        !listEquals(oldDelegate.weekdays, weekdays);
  }
}

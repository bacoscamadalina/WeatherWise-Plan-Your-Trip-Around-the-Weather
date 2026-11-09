import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/daily_forecast.dart';
import 'package:weatherwise/widgets/forecast_trend_chart.dart';

void main() {
  testWidgets('renders a selectable fourteen-day temperature and rain story',
      (tester) async {
    final forecasts = _forecasts();
    DailyForecast? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ForecastTrendChart(
            forecasts: forecasts,
            selectedId: forecasts.first.id,
            onSelected: (forecast) => selected = forecast,
          ),
        ),
      ),
    );

    expect(find.text('14-day weather story'), findsOneWidget);
    expect(find.text('Thu 1 · 18° / 8° · 5% rain'), findsOneWidget);
    expect(find.textContaining('Best forecast match for outdoors'),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('forecast-trend-painter')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('forecast-trend-day-2')),
    );
    expect(selected?.id, 2);

    await tester.tap(find.byKey(const ValueKey('plan-best-outdoor-day')));
    expect(selected, isNotNull);
  });

  testWidgets('keeps the chart usable with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ForecastTrendChart(
                forecasts: _forecasts(),
                selectedId: 1,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('14-day weather story'), findsOneWidget);
  });
}

List<DailyForecast> _forecasts() {
  return List.generate(14, (index) {
    return DailyForecast(
      id: index + 1,
      date: DateTime(2026, 10, index + 1),
      label: index.isEven ? 'Clear' : 'Rain',
      weatherClass: index.isEven ? 'clear' : 'rain',
      activityContext: index.isEven ? 'outdoor' : 'indoor',
      minC: 8 + index / 2,
      maxC: 18 + index / 2,
      rainProbability: 5 + index * 6,
      windSpeedKph: 12,
    );
  });
}

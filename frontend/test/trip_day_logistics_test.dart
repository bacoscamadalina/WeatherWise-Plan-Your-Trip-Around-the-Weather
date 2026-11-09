import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/trip_plan.dart';
import 'package:weatherwise/theme/atlas_theme.dart';
import 'package:weatherwise/widgets/trip_day_logistics.dart';

void main() {
  testWidgets('shows a calculated daily route without overstating precision',
      (tester) async {
    await _pump(
      tester,
      const TripDayLogistics(
        plannedStops: 3,
        locatedStops: 3,
        routeAvailable: true,
        travelMinutes: 70,
        distanceKm: 23.4,
        returnArrivalAt: '21:40',
      ),
    );

    expect(find.text('Drumul zilei'), findsOneWidget);
    expect(find.text('3 opriri'), findsOneWidget);
    expect(find.text('• 1 h 10 min pe drum'), findsOneWidget);
    expect(find.text('• 23,4 km'), findsOneWidget);
    expect(find.text('• înapoi la 21:40'), findsOneWidget);
    expect(find.text('calculat pe traseu'), findsOneWidget);
  });

  testWidgets('labels estimated travel and omits unknown distance',
      (tester) async {
    await _pump(
      tester,
      const TripDayLogistics(
        plannedStops: 2,
        locatedStops: 2,
        routeAvailable: true,
        travelMinutes: 45,
        estimated: true,
      ),
    );

    expect(find.text('rezervă estimată'), findsOneWidget);
    expect(find.textContaining('km'), findsNothing);
  });

  testWidgets('wraps safely on a narrow screen with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pump(
      tester,
      const TripDayLogistics(
        plannedStops: 4,
        locatedStops: 4,
        routeAvailable: true,
        travelMinutes: 135,
        distanceKm: 48.7,
        returnArrivalAt: '22:15',
        estimated: true,
      ),
      textScaler: const TextScaler.linear(1.6),
    );

    expect(find.text('4 opriri'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('honestly reports when stops have no routable coordinates',
      (tester) async {
    await _pump(
      tester,
      const TripDayLogistics(plannedStops: 2),
    );

    expect(find.text('Planul zilei'), findsOneWidget);
    expect(find.text('traseu încă indisponibil'), findsOneWidget);
    expect(find.textContaining('pe drum'), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester,
  TripDayLogistics logistics, {
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: TripDayLogisticsBand(
                logistics: logistics,
                romanian: true,
              ),
            ),
          ),
        ),
      ),
    );

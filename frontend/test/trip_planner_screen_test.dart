import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/l10n/app_strings.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/trip_plan.dart';
import 'package:weatherwise/screens/trip_planner_screen.dart';
import 'package:weatherwise/services/trip_repository.dart';
import 'package:weatherwise/theme/atlas_theme.dart';

void main() {
  testWidgets('builds and renders a weather-aware trip day', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeTripRepository();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ro'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AtlasTheme.light(),
        home: TripPlannerScreen(
          location: location,
          repository: repository,
        ),
      ),
    );

    expect(find.text('Călătoria ta, în ritmul vremii.'), findsOneWidget);
    expect(find.text('50 km'), findsOneWidget);

    final partySize = find.byKey(const ValueKey('trip-create-party-size'));
    await tester.ensureVisible(partySize);
    await tester.pumpAndSettle();
    await tester.tap(partySize);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('trip-preference-nature')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trip-preference-nature')));
    await tester.tap(find.byKey(const ValueKey('trip-preference-vegan')));
    await tester.tap(find.byKey(const ValueKey('trip-budget-moderate')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('potriviri de căutare, nu meniuri verificate'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Construiește planul'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Construiește planul'));
    await tester.pumpAndSettle();

    expect(repository.partySizeReceived, 2);
    expect(repository.arrivalTimeReceived, '12:00');
    expect(repository.departureTimeReceived, '18:00');
    expect(repository.preferencesReceived?.budget, 'moderate');
    expect(repository.preferencesReceived?.dietary, ['vegan']);
    expect(repository.preferencesReceived?.interests, ['nature']);
    expect(find.text('Călătorie în Iași'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Harmony Café'), findsOneWidget);
    expect(find.text('4.7 (312)'), findsOneWidget);
    expect(find.text('Sursă: Google Places'), findsOneWidget);
    expect(find.text('Grădina Botanică'), findsOneWidget);
    expect(find.textContaining('Interval senin · 16–19°C'), findsOneWidget);
    expect(find.textContaining('prognoză orară'), findsOneWidget);
    expect(find.text('Echilibrat · 08:30–22:30'), findsOneWidget);
    expect(find.textContaining('3 activități · 20 min'), findsOneWidget);
    expect(find.textContaining('Zi parțială'), findsOneWidget);
    expect(find.text('Drumul zilei'), findsOneWidget);
    expect(find.text('2 opriri'), findsOneWidget);
    expect(find.textContaining('1 h 10 min pe drum'), findsOneWidget);
    expect(find.textContaining('înapoi la 17:20'), findsOneWidget);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 2000),
      1000,
    );
    await tester.pumpAndSettle();
    final pace = find.text('Echilibrat');
    await tester.ensureVisible(pace);
    await tester.pumpAndSettle();
    await tester.tap(pace);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relaxat').last);
    await tester.pumpAndSettle();

    expect(find.text('Călătorie în Iași'), findsNothing);
  });

  testWidgets(
      'keeps personalization and the plan action reachable at 1.6x text',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ro'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AtlasTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: TripPlannerScreen(
            location: location,
            repository: _FakeTripRepository(),
          ),
        ),
      ),
    );

    final nature = find.byKey(const ValueKey('trip-preference-nature'));
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, -1600),
      2000,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(nature);
    await tester.pumpAndSettle();
    await tester.tap(nature);
    final action = find.text('Construiește planul');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();

    expect(action, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const location = Location(
  id: 1,
  name: 'Iași',
  displayName: 'Iași, România',
  countryCode: 'RO',
  latitude: 47.1585,
  longitude: 27.6014,
  timezone: 'Europe/Bucharest',
);

class _FakeTripRepository implements TripRepository {
  int? partySizeReceived;
  String? arrivalTimeReceived;
  String? departureTimeReceived;
  TripPreferences? preferencesReceived;

  @override
  Future<TripPlan> createTrip({
    required Location location,
    required DateTime startsOn,
    required DateTime endsOn,
    required String pace,
    required String transportMode,
    required double maxDistanceKm,
    String? arrivalTime,
    String? departureTime,
    int partySize = 1,
    TripPreferences preferences = const TripPreferences(),
  }) async {
    partySizeReceived = partySize;
    arrivalTimeReceived = arrivalTime;
    departureTimeReceived = departureTime;
    preferencesReceived = preferences;
    return TripPlan(
      id: 7,
      name: 'Călătorie în Iași',
      location: location,
      startsOn: startsOn,
      endsOn: endsOn,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      maxDistanceKm: maxDistanceKm,
      pace: pace,
      transportMode: transportMode,
      partySize: partySize,
      status: 'planned',
      rhythm: const TripRhythm(
        pace: 'balanced',
        label: 'Echilibrat',
        description:
            'Trei descoperiri, cu timp suficient între mese și deplasări.',
        dayStart: '08:30',
        dayEnd: '22:30',
        plannedActivityCount: 3,
        travelBufferMinutes: 20,
      ),
      days: [
        TripPlanDay(
          id: 9,
          date: startsOn,
          weatherClass: 'clear',
          activityContext: 'outdoor',
          summary: 'Mai mult senin, 10–22°C, 5% ploaie',
          weather: const {'rain_probability': 5},
          availableFrom: arrivalTime,
          availableUntil: departureTime,
          logistics: const TripDayLogistics(
            plannedStops: 2,
            locatedStops: 2,
            routeAvailable: true,
            travelMinutes: 70,
            distanceKm: 23.4,
            returnArrivalAt: '17:20',
          ),
          items: const [
            TripPlanItem(
              id: 1,
              slot: 'breakfast',
              kind: 'meal',
              title: 'Harmony Café',
              status: 'suggested',
              startsAt: '08:30',
              rating: 4.7,
              ratingCount: 312,
              distanceKm: 1.2,
              provider: 'google_places',
            ),
            TripPlanItem(
              id: 2,
              slot: 'morning',
              kind: 'activity',
              title: 'Grădina Botanică',
              status: 'suggested',
              startsAt: '10:00',
              summary: 'Potrivită pentru vremea senină.',
              distanceKm: 3.4,
              metadata: {
                'period_weather': {
                  'source': 'hourly',
                  'weather_class': 'clear',
                  'temperature_min_c': 16,
                  'temperature_max_c': 19,
                  'precipitation_probability': 8,
                },
              },
            ),
          ],
        ),
      ],
    );
  }
}

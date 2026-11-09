import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:weatherwise/l10n/app_strings.dart';
import 'package:weatherwise/models/activity_availability.dart';
import 'package:weatherwise/models/daily_forecast.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/plan_recommendation.dart';
import 'package:weatherwise/screens/recommendation_detail_screen.dart';

void main() {
  test('parses map and movie metadata from the recommendation API', () {
    final item = PlanRecommendation.fromJson({
      'id': 42,
      'type': 'movie',
      'title': 'A Rainy Mystery',
      'summary': 'A careful whodunit.',
      'indoor': true,
      'genres': ['mystery'],
      'tags': ['movie'],
      'score': 80,
      'reason': 'A sheltered choice',
      'coordinates': {'latitude': 47.1, 'longitude': 27.6},
      'rating': 8.1,
      'release_date': '2026-09-10',
      'recommended_periods': ['evening'],
      'availability': {
        'status': 'listed_open',
        'label': 'Listed as open in the evening',
        'period': 'evening',
        'disclaimer': 'Verify before visiting.',
      },
    });

    expect(item.latitude, 47.1);
    expect(item.longitude, 27.6);
    expect(item.rating, 8.1);
    expect(item.releaseDate, DateTime(2026, 9, 10));
    expect(item.recommendedPeriods, ['evening']);
    expect(item.availability?.status, 'listed_open');
  });

  testWidgets('opens the movie source from the detail screen', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Uri? openedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationDetailScreen(
          recommendation: _movie,
          forecast: _forecast,
          location: _location,
          linkLauncher: (uri) async {
            openedUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A simple rhythm for the day'), findsOneWidget);
    expect(find.text('Evening'), findsWidgets);
    final sourceButton =
        find.widgetWithText(OutlinedButton, 'View movie source');
    await tester.scrollUntilVisible(
      sourceButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(sourceButton);
    await tester.pump();

    expect(openedUri, Uri.parse('https://www.themoviedb.org/movie/42'));
  });

  testWidgets('renders elevation route length and trail difficulty',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const mountain = PlanRecommendation(
      id: 77,
      type: 'activity',
      title: 'Vârful Toaca',
      summary: 'A mapped summit.',
      indoor: false,
      genres: [],
      tags: ['nature', 'hiking', 'summit'],
      provider: 'openstreetmap',
      score: 95,
      reason: 'The dry daylight window passes the hiking filter',
      weatherSensitive: true,
      elevationM: 1904,
      routeDistanceKm: 8.5,
      routeStart: 'Durău',
      routeEnd: 'Vârful Toaca',
      durationMinutes: 210,
      ascentM: 780,
      descentM: 120,
      roundtrip: false,
      difficulty: 'mountain_hiking',
      trailVisibility: 'good',
      surface: 'rock',
      routeNetwork: 'rwn',
      routeRef: 'bandă roșie',
      trailMarker: 'red:white:red_bar',
      routeOperator: 'Salvamont Neamț',
      recommendedPeriods: ['morning'],
      planningNotes: [
        RecommendationPlanningNote(
          code: 'verify_trail_conditions',
          severity: 'advisory',
          message: 'Verify official trail conditions.',
        ),
      ],
    );
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
        home: RecommendationDetailScreen(
          recommendation: mountain,
          forecast: _forecast,
          location: _location,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final usefulDetails = find.text('Detalii utile');
    await tester.scrollUntilVisible(
      usefulDetails,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Altitudine'), findsOneWidget);
    expect(find.text('1904 m'), findsOneWidget);
    expect(find.text('Lungimea traseului'), findsWidgets);
    expect(find.text('8.5 km'), findsWidgets);
    expect(find.text('drumeție montană'), findsOneWidget);
    expect(find.text('potecă bine vizibilă'), findsOneWidget);
    expect(find.text('stâncă'), findsOneWidget);
    expect(find.text('Pregătirea traseului'), findsOneWidget);
    expect(find.text('Durău'), findsWidgets);
    expect(find.text('3 h 30 min'), findsWidgets);
    expect(find.text('Urcare cumulată'), findsWidgets);
    expect(find.text('780 m'), findsWidgets);
    expect(find.text('Traseu liniar'), findsWidgets);
    expect(find.text('Rețeaua traseului'), findsWidgets);
    expect(find.text('rețea regională'), findsWidgets);
    expect(find.text('Marcaj / indicativ'), findsWidgets);
    expect(find.text('bandă roșie'), findsWidgets);
    expect(find.text('Marcaj OSM'), findsWidgets);
    expect(find.text('Administrator traseu'), findsWidgets);
    expect(find.text('Salvamont Neamț'), findsWidgets);
    expect(find.text('Verifică programul live'), findsNothing);
  });

  testWidgets('localizes movie planning details in Romanian', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
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
        home: RecommendationDetailScreen(
          recommendation: _movie,
          forecast: _forecast,
          location: _location,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Idee de film'), findsOneWidget);
    expect(find.text('De ce se potrivește acestei zile'), findsOneWidget);
    expect(find.text('Un ritm simplu pentru această zi'), findsOneWidget);
    expect(find.text('Seară'), findsWidgets);

    final sourceButton =
        find.widgetWithText(OutlinedButton, 'Vezi sursa filmului');
    await tester.scrollUntilVisible(
      sourceButton,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(sourceButton, findsOneWidget);
  });

  testWidgets('checks and renders live activity hours on demand',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? checkedPeriod;
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationDetailScreen(
          recommendation: _activity,
          forecast: _forecast,
          location: _location,
          availabilityChecker: (period) async {
            checkedPeriod = period;
            return ActivityAvailability(
              status: 'verified_open',
              label: 'Provider lists this place open in the afternoon',
              detail: 'Checked against current provider hours.',
              period: period,
              provider: 'google_places',
              checkedAt: DateTime.utc(2026, 10, 1, 9),
              placeName: 'Palace of Culture',
              placeUrl: Uri.parse('https://maps.google.com/example'),
              attributionLabel: 'Google Maps',
              attributionUrl: Uri.parse('https://maps.google.com'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final checkButton = find.widgetWithText(FilledButton, 'Check live hours');
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(checkButton);
    await tester.pumpAndSettle();
    await tester.tap(checkButton);
    await tester.pumpAndSettle();

    expect(checkedPeriod, 'afternoon');
    expect(
      find.text('Provider lists this place open in the afternoon'),
      findsOneWidget,
    );
    expect(find.text('Matched place: Palace of Culture'), findsOneWidget);
    expect(find.text('Open provider place'), findsOneWidget);
    expect(find.text('Live hours data by Google Maps'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(
        tester.getSize(find.widgetWithText(FilledButton, 'Check again')).height,
        greaterThanOrEqualTo(48));
  });

  testWidgets('clears an older availability result when retry fails',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RecommendationDetailScreen(
          recommendation: _activity,
          forecast: _forecast,
          location: _location,
          availabilityChecker: (period) async {
            attempts += 1;
            if (attempts > 1) throw StateError('Provider unavailable');
            return ActivityAvailability(
              status: 'verified_open',
              label: 'Provider lists this place open in the afternoon',
              detail: 'Checked against current provider hours.',
              period: period,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstCheck = find.widgetWithText(FilledButton, 'Check live hours');
    await tester.ensureVisible(firstCheck);
    await tester.tap(firstCheck);
    await tester.pumpAndSettle();
    expect(
      find.text('Provider lists this place open in the afternoon'),
      findsOneWidget,
    );

    final retry = find.widgetWithText(FilledButton, 'Check again');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();

    expect(
      find.text('Provider lists this place open in the afternoon'),
      findsNothing,
    );
    expect(
      find.text(
        'Live hours could not be checked. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });
}

const _movie = PlanRecommendation(
  id: 42,
  type: 'movie',
  title: 'A Rainy Mystery',
  summary: 'A careful whodunit for a wet evening.',
  indoor: true,
  genres: ['mystery'],
  tags: ['movie'],
  url: 'https://www.themoviedb.org/movie/42',
  score: 80,
  reason: 'A sheltered choice for rain conditions',
  recommendedPeriods: ['evening'],
);

const _activity = PlanRecommendation(
  id: 7,
  type: 'activity',
  title: 'Palace of Culture',
  summary: 'A museum visit for a rainy afternoon.',
  venueName: 'Palace of Culture',
  indoor: true,
  genres: [],
  tags: ['museum'],
  latitude: 47.1573,
  longitude: 27.5863,
  score: 90,
  reason: 'A sheltered choice for rain conditions',
  recommendedPeriods: ['morning', 'afternoon'],
);

final _forecast = DailyForecast(
  id: 1,
  date: DateTime(2026, 10, 2),
  label: 'Rain',
  weatherClass: 'rain',
  activityContext: 'indoor',
  minC: 8,
  maxC: 14,
  rainProbability: 80,
  windSpeedKph: 12,
);

const _location = Location(
  id: 1,
  name: 'Iași',
  displayName: 'Iași, RO',
  countryCode: 'RO',
  latitude: 47.1585,
  longitude: 27.6014,
  timezone: 'Europe/Bucharest',
);

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/l10n/app_strings.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/trip_plan.dart';
import 'package:weatherwise/screens/saved_trip_screen.dart';
import 'package:weatherwise/services/trip_repository.dart';
import 'package:weatherwise/theme/atlas_theme.dart';

void main() {
  testWidgets('replans a saved trip for refreshed weather', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SavedTripRepository(updatedPlan: rainyPlan);

    await tester.pumpWidget(_app(repository));

    expect(find.text('Grădina Botanică'), findsOneWidget);
    await tester.tap(find.text('Actualizează după vreme'));
    await tester.pumpAndSettle();
    expect(find.text('Replănuiești după vremea nouă?'), findsOneWidget);

    await tester.tap(find.text('Replănuiește'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repository.replanCalls, 1);
    expect(find.text('Palatul Culturii'), findsOneWidget);
    expect(find.text('Grădina Botanică'), findsNothing);
    expect(
      find.text('Planul a fost adaptat la cea mai nouă prognoză.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the previous plan when replanning fails', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SavedTripRepository(
      updatedPlan: rainyPlan,
      fail: true,
    );

    await tester.pumpWidget(_app(repository));
    await tester.tap(find.text('Actualizează după vreme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Replănuiește'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Grădina Botanică'), findsOneWidget);
    expect(
      find.text(
        'Nu am putut actualiza planul. Versiunea anterioară a fost păstrată.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reîncearcă'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the replan action usable with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        _SavedTripRepository(updatedPlan: rainyPlan),
        textScaler: const TextScaler.linear(1.6),
      ),
    );

    expect(find.text('Actualizează după vreme'), findsOneWidget);
    final edit = find.byKey(const ValueKey('edit-trip-details'));
    await tester.ensureVisible(edit);
    await tester.pumpAndSettle();
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(find.text('Detaliile călătoriei'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save-and-replan-trip')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the replacement action usable with enlarged text',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        _SavedTripRepository(updatedPlan: rainyPlan),
        textScaler: const TextScaler.linear(1.6),
      ),
    );

    final replacement = find.byKey(const ValueKey('replace-trip-item-1'));
    await tester.scrollUntilVisible(
      replacement,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Schimbă oprirea'), findsOneWidget);
    expect(tester.getSize(replacement).height, 48);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits trip settings and replans with the submitted values',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SavedTripRepository(updatedPlan: rainyPlan);

    await tester.pumpWidget(_app(repository));
    await tester.tap(find.byKey(const ValueKey('edit-trip-details')));
    await tester.pumpAndSettle();

    expect(find.text('Detaliile călătoriei'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('trip-party-size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('trip-pace')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relaxat').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('trip-preference-culture')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trip-preference-culture')));
    await tester.tap(find.byKey(const ValueKey('trip-preference-vegetarian')));
    await tester.tap(find.byKey(const ValueKey('trip-budget-value')));
    await tester.pumpAndSettle();
    final submit = find.byKey(const ValueKey('save-and-replan-trip'));
    await tester.scrollUntilVisible(
      submit,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(repository.replanCalls, 1);
    expect(repository.lastRequest?.partySize, 2);
    expect(repository.lastRequest?.arrivalTime, '12:00');
    expect(repository.lastRequest?.departureTime, '18:00');
    expect(repository.lastRequest?.pace, 'relaxed');
    expect(repository.lastRequest?.transportMode, 'car');
    expect(repository.lastRequest?.maxDistanceKm, 50);
    expect(repository.lastRequest?.preferences?.budget, 'value');
    expect(repository.lastRequest?.preferences?.dietary, ['vegetarian']);
    expect(repository.lastRequest?.preferences?.interests, ['culture']);
    expect(find.text('Palatul Culturii'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replaces one stop while keeping the saved trip visible',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SavedTripRepository(updatedPlan: rainyPlan);

    await tester.pumpWidget(_app(repository));
    final replace = find.byKey(const ValueKey('replace-trip-item-1'));
    await tester.ensureVisible(replace);
    await tester.pumpAndSettle();
    await tester.tap(replace);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 350));

    expect(repository.replaceCalls, 1);
    expect(repository.lastReplacedItemId, 1);
    expect(find.text('Palatul Culturii'), findsOneWidget);
    expect(find.text('Grădina Botanică'), findsNothing);
    expect(
      find.text(
        'Am găsit o alternativă potrivită și am păstrat restul planului.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the current stop when no replacement is available',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SavedTripRepository(
      updatedPlan: rainyPlan,
      failReplacement: true,
    );

    await tester.pumpWidget(_app(repository));
    final replace = find.byKey(const ValueKey('replace-trip-item-1'));
    await tester.ensureVisible(replace);
    await tester.pumpAndSettle();
    await tester.tap(replace);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Grădina Botanică'), findsOneWidget);
    expect(
      find.text(
        'Nu am găsit acum o alternativă diferită. Oprirea actuală a fost păstrată.',
      ),
      findsOneWidget,
    );
    expect(find.text('Reîncearcă'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('distinguishes a provider failure from catalog exhaustion',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SavedTripRepository(
      updatedPlan: rainyPlan,
      replacementErrorCode: 'provider_unavailable',
    );

    await tester.pumpWidget(_app(repository));
    final replace = find.byKey(const ValueKey('replace-trip-item-1'));
    await tester.ensureVisible(replace);
    await tester.pumpAndSettle();
    await tester.tap(replace);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Grădina Botanică'), findsOneWidget);
    expect(
      find.text(
        'Serviciul de recomandări nu răspunde momentan. Oprirea actuală a fost păstrată.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  PersonalTripRepository repository, {
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
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
        data: MediaQueryData(textScaler: textScaler),
        child: SavedTripScreen(plan: clearPlan, repository: repository),
      ),
    );

const location = Location(
  id: 1,
  name: 'Iași',
  displayName: 'Iași, România',
  countryCode: 'RO',
  latitude: 47.1585,
  longitude: 27.6014,
  timezone: 'Europe/Bucharest',
);

final clearPlan = _plan(
  weatherClass: 'clear',
  summary: 'Senin, 11–23°C, 5% ploaie',
  activity: 'Grădina Botanică',
);

final rainyPlan = _plan(
  weatherClass: 'rain',
  summary: 'Ploaie, 9–15°C, 80% ploaie',
  activity: 'Palatul Culturii',
);

TripPlan _plan({
  required String weatherClass,
  required String summary,
  required String activity,
}) =>
    TripPlan(
      id: 7,
      name: 'Weekend în Iași',
      location: location,
      startsOn: DateTime(2026, 10, 7),
      endsOn: DateTime(2026, 10, 7),
      arrivalTime: '12:00',
      departureTime: '18:00',
      maxDistanceKm: 50,
      pace: 'balanced',
      transportMode: 'car',
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
          date: DateTime(2026, 10, 7),
          weatherClass: weatherClass,
          activityContext: weatherClass == 'rain' ? 'indoor' : 'outdoor',
          summary: summary,
          weather: const {},
          items: [
            TripPlanItem(
              id: weatherClass == 'rain' ? 2 : 1,
              slot: 'morning',
              kind: 'activity',
              title: activity,
              status: 'suggested',
              startsAt: '10:00',
              endsAt: '12:00',
              metadata: const {
                'duration_minutes': 120,
                'travel_buffer_minutes': 20,
              },
            ),
          ],
        ),
      ],
    );

class _SavedTripRepository implements PersonalTripRepository {
  _SavedTripRepository({
    required this.updatedPlan,
    this.fail = false,
    this.failReplacement = false,
    this.replacementErrorCode,
  });

  final TripPlan updatedPlan;
  final bool fail;
  final bool failReplacement;
  final String? replacementErrorCode;
  int replanCalls = 0;
  int replaceCalls = 0;
  int? lastReplacedItemId;
  TripEditRequest? lastRequest;

  @override
  Future<TripPlan> replanTrip(
    int id, {
    DateTime? startsOn,
    DateTime? endsOn,
    String? arrivalTime,
    String? departureTime,
    int? partySize,
    String? pace,
    String? transportMode,
    double? maxDistanceKm,
    TripPreferences? preferences,
  }) async {
    replanCalls += 1;
    lastRequest = TripEditRequest(
      startsOn: startsOn,
      endsOn: endsOn,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      partySize: partySize,
      pace: pace,
      transportMode: transportMode,
      maxDistanceKm: maxDistanceKm,
      preferences: preferences,
    );
    if (fail) throw const TripRepositoryException('offline');
    return updatedPlan;
  }

  @override
  Future<TripPlan> replaceItem(int tripId, int itemId) async {
    replaceCalls += 1;
    lastReplacedItemId = itemId;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (failReplacement) {
      throw const TripRepositoryException(
        'unavailable',
        code: 'no_alternative',
      );
    }
    if (replacementErrorCode != null) {
      throw TripRepositoryException(
        'unavailable',
        code: replacementErrorCode,
      );
    }
    return updatedPlan;
  }

  @override
  Future<void> deleteTrip(int id) async {}

  @override
  Future<TripPlan> getTrip(int id) async => clearPlan;

  @override
  Future<List<TripPlan>> listTrips() async => [clearPlan];

  @override
  Future<TripPlan> renameTrip(int id, String name) async => clearPlan;
}

class TripEditRequest {
  const TripEditRequest({
    this.startsOn,
    this.endsOn,
    this.arrivalTime,
    this.departureTime,
    this.partySize,
    this.pace,
    this.transportMode,
    this.maxDistanceKm,
    this.preferences,
  });

  final DateTime? startsOn;
  final DateTime? endsOn;
  final String? arrivalTime;
  final String? departureTime;
  final int? partySize;
  final String? pace;
  final String? transportMode;
  final double? maxDistanceKm;
  final TripPreferences? preferences;
}

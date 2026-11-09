import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/l10n/app_strings.dart';
import 'package:weatherwise/models/itinerary_item.dart';
import 'package:weatherwise/models/event_day_summary.dart';
import 'package:weatherwise/models/hourly_forecast.dart';
import 'package:weatherwise/models/plan_recommendation.dart';
import 'package:weatherwise/models/recommendation_filters.dart';
import 'package:weatherwise/widgets/recommendation_panel.dart';

void main() {
  testWidgets('renders an accessible outdoor planning note at compact width',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const message =
        'UV peaks at 8.5; favor shade around midday and use sun protection.';
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecommendationPanel(
              recommendations: const [
                PlanRecommendation(
                  id: 12,
                  type: 'activity',
                  title: 'Botanical Garden',
                  summary: 'A shaded garden walk for a clear day.',
                  indoor: false,
                  genres: [],
                  tags: ['garden'],
                  score: 72,
                  reason: 'Makes the most of the clear outdoor window',
                  planningNotes: [
                    RecommendationPlanningNote(
                      code: 'very_high_uv',
                      severity: 'moderate',
                      message: message,
                    ),
                  ],
                ),
              ],
              hourlyForecasts: const [],
              loading: false,
              filters: const RecommendationFilters(),
              onTypeChanged: (_) {},
              onTunePressed: () {},
              onClearFilters: () {},
              onRetry: () {},
              onRecommendationPressed: (_) {},
              showtimes: const [],
              showtimesLoading: false,
              onShowtimesRetry: () {},
              onShowtimePressed: (_) {},
              itinerary: const [],
              onAddRecommendationToPlan: (_) {},
              onAddShowtimeToPlan: (_) {},
              onRemoveFromPlan: (_) {},
              onClearPlan: () {},
              onCopyPlan: () {},
              onCalendarPlan: () {},
              onRoutePlan: null,
              onSuggestPlan: () {},
              onAdaptPlan: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(message), findsOneWidget);
    final planningNote = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Planning note: $message',
    );
    expect(planningNote, findsOneWidget);
    expect(
      find.descendant(
        of: planningNote,
        matching: find.byIcon(Icons.wb_sunny_outlined),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes WeatherWise UV notes and semantics in Romanian',
      (tester) async {
    const original =
        'UV peaks at 8.5; favor shade around midday and use sun protection.';
    const translated =
        'UV atinge 8.5; caută umbră la prânz și folosește protecție solară.';
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
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecommendationPanel(
              recommendations: const [
                PlanRecommendation(
                  id: 12,
                  type: 'activity',
                  title: 'Grădina Botanică',
                  summary: 'Plimbare la umbră.',
                  indoor: false,
                  genres: [],
                  tags: ['garden'],
                  score: 72,
                  reason: 'A nature pick suited to this forecast',
                  planningNotes: [
                    RecommendationPlanningNote(
                      code: 'very_high_uv',
                      severity: 'moderate',
                      message: original,
                    ),
                  ],
                ),
              ],
              hourlyForecasts: const [],
              loading: false,
              filters: const RecommendationFilters(),
              onTypeChanged: (_) {},
              onTunePressed: () {},
              onClearFilters: () {},
              onRetry: () {},
              onRecommendationPressed: (_) {},
              showtimes: const [],
              showtimesLoading: false,
              onShowtimesRetry: () {},
              onShowtimePressed: (_) {},
              itinerary: const [],
              onAddRecommendationToPlan: (_) {},
              onAddShowtimeToPlan: (_) {},
              onRemoveFromPlan: (_) {},
              onClearPlan: () {},
              onCopyPlan: () {},
              onCalendarPlan: () {},
              onRoutePlan: null,
              onSuggestPlan: () {},
              onAdaptPlan: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(translated), findsOneWidget);
    expect(find.text(original), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Notă de planificare: $translated',
      ),
      findsOneWidget,
    );
  });

  testWidgets('exposes a labeled route action for a located day plan',
      (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecommendationPanel(
              recommendations: const [],
              hourlyForecasts: [
                HourlyForecast(
                  time: DateTime(2026, 10, 2, 9),
                  label: 'Clear',
                  weatherClass: 'clear',
                  activityContext: 'outdoor',
                  temperatureC: 18,
                  rainProbability: 5,
                  windSpeedKph: 7,
                  daylight: true,
                ),
              ],
              loading: false,
              filters: const RecommendationFilters(),
              onTypeChanged: (_) {},
              onTunePressed: () {},
              onClearFilters: () {},
              onRetry: () {},
              onRecommendationPressed: (_) {},
              showtimes: const [],
              showtimesLoading: false,
              onShowtimesRetry: () {},
              onShowtimePressed: (_) {},
              itinerary: const [
                ItineraryItem(
                  sourceKey: 'activity:1',
                  sourceType: 'activity',
                  title: 'Botanical Garden',
                  subtitle: 'Local activity',
                  period: 'morning',
                  latitude: 47.18,
                  longitude: 27.57,
                ),
              ],
              onAddRecommendationToPlan: (_) {},
              onAddShowtimeToPlan: (_) {},
              onRemoveFromPlan: (_) {},
              onClearPlan: () {},
              onCopyPlan: () {},
              onCalendarPlan: () {},
              onRoutePlan: () => opened = true,
              onSuggestPlan: () {},
              onAdaptPlan: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('route-day-plan')));
    expect(opened, isTrue);
    expect(find.text('Open route'), findsOneWidget);
    expect(find.text('09:00 · Clear · 18° · 5% rain'), findsNWidgets(3));
  });

  testWidgets('explains an empty date-scoped event search', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationPanel(
            recommendations: const [],
            hourlyForecasts: const [],
            loading: false,
            filters: const RecommendationFilters(type: 'event'),
            onTypeChanged: (_) {},
            onTunePressed: () {},
            onClearFilters: () {},
            onRetry: () {},
            onRecommendationPressed: (_) {},
            showtimes: const [],
            showtimesLoading: false,
            onShowtimesRetry: () {},
            onShowtimePressed: (_) {},
            itinerary: const [],
            onAddRecommendationToPlan: (_) {},
            onAddShowtimeToPlan: (_) {},
            onRemoveFromPlan: (_) {},
            onClearPlan: () {},
            onCopyPlan: () {},
            onCalendarPlan: () {},
            onRoutePlan: null,
            onSuggestPlan: () {},
            onAdaptPlan: null,
          ),
        ),
      ),
    );

    expect(
      find.text(
        'No nearby events are published for this date.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('offers real event dates from the wider forecast window',
      (tester) async {
    EventDaySummary? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RecommendationPanel(
              recommendations: const [],
              eventDays: [
                EventDaySummary(
                  date: DateTime(2026, 10, 9),
                  count: 3,
                  previewTitle: 'Paris Jazz Evening',
                  previewVenue: 'Le Point Virgule',
                  providers: ['ticketmaster'],
                ),
              ],
              onEventDayPressed: (day) => selected = day,
              hourlyForecasts: const [],
              loading: false,
              filters: const RecommendationFilters(type: 'event'),
              onTypeChanged: (_) {},
              onTunePressed: () {},
              onClearFilters: () {},
              onRetry: () {},
              onRecommendationPressed: (_) {},
              showtimes: const [],
              showtimesLoading: false,
              onShowtimesRetry: () {},
              onShowtimePressed: (_) {},
              itinerary: const [],
              onAddRecommendationToPlan: (_) {},
              onAddShowtimeToPlan: (_) {},
              onRemoveFromPlan: (_) {},
              onClearPlan: () {},
              onCopyPlan: () {},
              onCalendarPlan: () {},
              onRoutePlan: null,
              onSuggestPlan: () {},
              onAdaptPlan: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Events on other forecast days'), findsOneWidget);
    expect(find.textContaining('3 events'), findsOneWidget);
    expect(find.text('Paris Jazz Evening'), findsOneWidget);

    await tester.tap(find.text('Paris Jazz Evening'));
    expect(selected?.previewTitle, 'Paris Jazz Evening');
  });
}

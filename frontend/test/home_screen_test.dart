import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/activity_availability.dart';
import 'package:weatherwise/models/advisory_notification_preferences.dart';
import 'package:weatherwise/models/cinema_showtime.dart';
import 'package:weatherwise/models/current_conditions.dart';
import 'package:weatherwise/models/daily_forecast.dart';
import 'package:weatherwise/models/forecast_result.dart';
import 'package:weatherwise/models/hourly_forecast.dart';
import 'package:weatherwise/models/itinerary_item.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/location_library.dart';
import 'package:weatherwise/models/location_search_page.dart';
import 'package:weatherwise/models/plan_recommendation.dart';
import 'package:weatherwise/models/preference_profile.dart';
import 'package:weatherwise/models/recommendation_filters.dart';
import 'package:weatherwise/models/weather_advisory.dart';
import 'package:weatherwise/l10n/app_strings.dart';
import 'package:weatherwise/screens/home_screen.dart';
import 'package:weatherwise/services/itinerary_store.dart';
import 'package:weatherwise/services/advisory_notification_planner.dart';
import 'package:weatherwise/services/advisory_notification_preferences_store.dart';
import 'package:weatherwise/services/advisory_notification_scheduler.dart';
import 'package:weatherwise/services/location_library_store.dart';
import 'package:weatherwise/services/preference_profile_store.dart';
import 'package:weatherwise/services/weather_repository.dart';

void main() {
  testWidgets('supports enlarged text with reduced motion', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: HomeScreen(repository: _FakeRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WeatherWise'), findsOneWidget);
    expect(find.text('UV max 4.8'), findsOneWidget);
    expect(find.text('Sun 07:13–18:49'), findsOneWidget);
    expect(find.text('Updated just now'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnimatedContainer &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).image != null,
      ),
      findsOneWidget,
    );
    expect(find.text('See ideas for this day'), findsOneWidget);

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose a day to shape your plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refreshes the forecast without replacing the current view',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh forecast'));
    await tester.pumpAndSettle();

    expect(repository.refreshRequested, isTrue);
    expect(find.text('Forecast updated.'), findsOneWidget);
    expect(find.text('Iași'), findsWidgets);
    expect(find.text('Updated just now'), findsOneWidget);
  });

  testWidgets('labels demo refresh without claiming live freshness',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: DemoWeatherRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demo data'), findsOneWidget);
    expect(find.text('Try live weather'), findsOneWidget);
    expect(find.text('Updated just now'), findsNothing);
  });

  testWidgets('keeps the previous forecast when refresh fails', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: _FailingRefreshRepository())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Refresh forecast'));
    await tester.pumpAndSettle();

    expect(find.text('Mainly clear'), findsOneWidget);
    expect(
      find.text(
        'Could not refresh the forecast. Showing the previous update.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders a searched location and forecast card', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRepository();
    await tester
        .pumpWidget(MaterialApp(home: HomeScreen(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('WeatherWise'), findsOneWidget);
    expect(find.text('Iași'), findsWidgets);
    expect(find.text('Mainly clear'), findsOneWidget);
    expect(
      find.text('Feels like 11° · Current estimate · as of 16:15'),
      findsOneWidget,
    );
    expect(find.text('High 14° · Low 8°'), findsOneWidget);
    expect(find.text('UV max 4.8'), findsOneWidget);
    expect(find.text('Sun 07:13–18:49'), findsOneWidget);
    expect(find.text('Best plan · Palace of Culture'), findsOneWidget);

    await tester.tap(find.text('Best plan · Palace of Culture'));
    await tester.pumpAndSettle();

    expect(find.text('Activity idea'), findsOneWidget);
    expect(find.text('Why it fits this day'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();

    expect(find.text('How the day unfolds'), findsOneWidget);
    expect(find.text('Best outdoor window · 14:00–20:00'), findsOneWidget);
    expect(find.text('Ideas matched to the forecast'), findsOneWidget);
    expect(find.text('Palace of Culture'), findsOneWidget);
    expect(find.text('A sheltered choice for rain conditions'), findsOneWidget);
    expect(find.text('Palace of Culture · 1.2 km away'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

    await tester.tap(find.text('Palace of Culture').last);
    await tester.pumpAndSettle();

    expect(find.text('Activity idea'), findsOneWidget);
    expect(find.text('Why it fits this day'), findsOneWidget);
    expect(find.text('A simple rhythm for the day'), findsOneWidget);
    expect(
        find.text(
            'Map coordinates are not available for this catalog item yet.'),
        findsOneWidget);
  });

  testWidgets('localizes the first planning viewport in Romanian',
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
        home: HomeScreen(repository: _FakeRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mai mult senin'), findsOneWidget);
    expect(find.text('Plan recomandat · Palace of Culture'), findsOneWidget);
    expect(find.text('Vezi idei pentru această zi'), findsOneWidget);
    expect(find.text('Alege o zi pentru a-ți contura planul'), findsOneWidget);
  });

  testWidgets('keeps the active plan open when the locale changes',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeRepository();
    await tester.pumpWidget(
      _localizedHome(locale: const Locale('en'), repository: repository),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    expect(find.text('How the day unfolds'), findsOneWidget);

    await tester.pumpWidget(
      _localizedHome(locale: const Locale('ro'), repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cum evoluează ziua'), findsOneWidget);
    expect(find.text('Idei potrivite prognozei'), findsOneWidget);
    expect(find.text('Planul zilei'), findsOneWidget);
    expect(find.text('Activități'), findsOneWidget);
    expect(find.text('Ajustează ideile'), findsOneWidget);
  });

  testWidgets('reloads provider recommendations after the locale changes',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final itineraryStore = MemoryItineraryStore();

    Widget app(Locale locale, WeatherRepository repository) => MaterialApp(
          locale: locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: HomeScreen(
            repository: repository,
            itineraryStore: itineraryStore,
          ),
        );

    await tester.pumpWidget(
      app(
        const Locale('en'),
        _LocalizedRecommendationRepository('Palace of Culture'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('add-recommendation-activity-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Afternoon · Palace of Culture'), findsOneWidget);

    await tester.pumpWidget(
      app(
        const Locale('ro'),
        _LocalizedRecommendationRepository('Palatul Culturii'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('După-amiază · Palatul Culturii'), findsOneWidget);
    expect(find.text('Palace of Culture'), findsNothing);
    final stored = await itineraryStore.load();
    expect(stored.values.single['afternoon']?.title, 'Palatul Culturii');
  });

  testWidgets('localizes a failed place search in Romanian', (tester) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _localizedHome(
        locale: const Locale('ro'),
        repository: _FailingLocationSearchRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Caută'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Căutarea locațiilor nu este disponibilă acum. Verifică conexiunea și încearcă din nou.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('discards an hourly request after its day is reopened',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _ControlledHourlyRepository();
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.hourlyCalls, 1);

    await tester.ensureVisible(find.text('Hide ideas'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Hide ideas').hitTestable());
    await tester.pump();
    await tester.tap(find.text('See ideas for this day').hitTestable());
    await tester.pumpAndSettle();

    expect(repository.hourlyCalls, 2);
    expect(find.text('Best outdoor window · 14:00–20:00'), findsOneWidget);

    repository.firstRequest.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('Best outdoor window · 14:00–20:00'), findsOneWidget);
    expect(
      find.text('Hourly detail is not available for this day yet.'),
      findsNothing,
    );
  });

  testWidgets('applies session recommendation filters', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tune ideas'));
    await tester.pumpAndSettle();

    expect(find.text('Tune your ideas'), findsOneWidget);
    expect(find.text('Movie mood'), findsOneWidget);
    expect(find.text('Activity style'), findsNothing);
    expect(find.text('Apply filters').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Evening'));
    await tester.tap(find.text('Mystery'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(repository.lastFilters.type, 'movie');
    expect(repository.lastFilters.genre, 'mystery');
    expect(repository.lastFilters.timeOfDay, 'evening');
    expect(find.text('Evening · Mystery movies'), findsOneWidget);
    expect(find.text('Cinema showtimes'), findsOneWidget);
    expect(find.text('Rain Story'), findsWidgets);
    expect(find.text('Central Cinema · 3.2 km away'), findsOneWidget);
    expect(find.text('19:30'), findsOneWidget);
    expect(find.text('Cinema and showtime data by MovieGlu'), findsOneWidget);
  });

  testWidgets('applies a device-local preference profile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRepository();
    final profileStore = MemoryPreferenceProfileStore(
      initial: const [
        PreferenceProfile(
          id: 'rainy-night',
          name: 'Rainy night',
          filters: RecommendationFilters(
            type: 'movie',
            genre: 'mystery',
            timeOfDay: 'evening',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          preferenceProfileStore: profileStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tune ideas'));
    await tester.pumpAndSettle();

    expect(find.text('Saved profiles'), findsOneWidget);
    await tester.tap(find.text('Rainy night'));
    await tester.pumpAndSettle();
    expect(find.text('Movie · Evening · Mystery movies'), findsOneWidget);

    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(repository.lastFilters.type, 'movie');
    expect(repository.lastFilters.genre, 'mystery');
    expect(repository.lastFilters.timeOfDay, 'evening');
  });

  testWidgets('saves a named preference profile on the device', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final profileStore = MemoryPreferenceProfileStore();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _FakeRepository(),
          preferenceProfileStore: profileStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tune ideas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Evening'));
    await tester.tap(find.text('Mystery'));
    await tester.tap(find.text('Save these choices'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Rainy night');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Rainy night'), findsOneWidget);
    final profiles = await profileStore.load();
    expect(profiles.single.name, 'Rainy night');
    expect(profiles.single.filters.genre, 'mystery');
    expect(profiles.single.filters.timeOfDay, 'evening');
  });

  testWidgets('shows a recoverable error when saved profiles cannot load',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _FakeRepository(),
          preferenceProfileStore: _FailingPreferenceProfileStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tune ideas'));
    await tester.pumpAndSettle();

    expect(find.text('Saved profiles'), findsOneWidget);
    expect(
      find.text('Saved profiles could not be loaded from this device.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Apply filters').hitTestable(), findsOneWidget);
  });

  testWidgets('opens a cinema booking handoff from a showtime', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRepository();
    Uri? launchedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          showtimeLinkLauncher: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();
    final showtimeButton = find.widgetWithText(OutlinedButton, '19:30');
    await tester.ensureVisible(showtimeButton);
    await tester.pumpAndSettle();
    await tester.tap(showtimeButton);
    await tester.pumpAndSettle();

    expect(repository.lastBookedShowtime?.id, '7:9:19:30:standard');
    expect(launchedUri, Uri.parse('https://cinema.example.test/book'));
  });

  testWidgets('builds and edits a session-only day plan', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRepository();
    final itineraryStore = MemoryItineraryStore();
    String? copiedPlan;
    Uri? calendarUri;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          itineraryStore: itineraryStore,
          planClipboardWriter: (text) async => copiedPlan = text,
          planCalendarLauncher: (uri) async {
            calendarUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    expect(find.text('Your day plan'), findsOneWidget);
    expect(find.text('Afternoon · Add an idea below'), findsOneWidget);

    final addActivity =
        find.byKey(const ValueKey('add-recommendation-activity-1'));
    await tester.ensureVisible(
      find.byKey(const ValueKey('recommendation-activity-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(addActivity);
    await tester.pumpAndSettle();

    expect(find.text('Afternoon · Palace of Culture'), findsOneWidget);
    expect(find.text('Palace of Culture'), findsOneWidget);
    expect(find.text('Local activity'), findsOneWidget);
    expect(find.text('Added to your afternoon plan.'), findsOneWidget);

    final copyPlan = find.byKey(const ValueKey('copy-day-plan'));
    await tester.ensureVisible(copyPlan);
    await tester.pumpAndSettle();
    await tester.tap(copyPlan);
    await tester.pumpAndSettle();
    expect(copiedPlan, contains('WeatherWise day plan — Iași'));
    expect(copiedPlan, contains('Friday, 2 October'));
    expect(copiedPlan, contains('Afternoon — Palace of Culture'));
    expect(find.text('Day plan copied.'), findsOneWidget);

    final calendarPlan = find.byKey(const ValueKey('calendar-day-plan'));
    await tester.ensureVisible(calendarPlan);
    await tester.pumpAndSettle();
    await tester.tap(calendarPlan);
    await tester.pumpAndSettle();
    expect(calendarUri?.host, 'calendar.google.com');
    expect(calendarUri?.queryParameters['dates'], '20261002/20261003');
    expect(
        calendarUri?.queryParameters['details'], contains('Palace of Culture'));
    expect(calendarUri?.queryParameters['ctz'], 'Europe/Bucharest');
    expect(find.text('Your plan is ready in Google Calendar.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          itineraryStore: itineraryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    expect(find.text('Afternoon · Palace of Culture'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('copy-day-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('remove-plan-afternoon')));
    await tester.pumpAndSettle();
    expect(find.text('Afternoon · Add an idea below'), findsOneWidget);
  });

  testWidgets('suggests a weather-matched plan without replacing saved slots',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final itineraryStore = MemoryItineraryStore();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _FakeRepository(),
          itineraryStore: itineraryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    final suggestButton = find.byKey(const ValueKey('suggest-day-plan'));
    await tester.ensureVisible(suggestButton);
    await tester.pumpAndSettle();
    await tester.tap(suggestButton);
    await tester.pumpAndSettle();

    expect(find.text('Morning · Palace of Culture'), findsOneWidget);
    expect(find.text('Added one weather-matched idea.'), findsOneWidget);
    expect(find.text('Afternoon · Add an idea below'), findsOneWidget);
    final stored = await itineraryStore.load();
    expect(stored.values.single['morning']?.title, 'Palace of Culture');
  });

  testWidgets('refreshes saved plan copy from the current recommendation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final itineraryStore = MemoryItineraryStore(
      initial: const {
        '1:2026-10-2': {
          'afternoon': ItineraryItem(
            sourceKey: 'activity:openstreetmap:1',
            sourceType: 'activity',
            title: 'Old catalog title',
            subtitle: 'Old catalog description',
            period: 'afternoon',
          ),
        },
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _FakeRepository(),
          itineraryStore: itineraryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();

    expect(find.text('Afternoon · Palace of Culture'), findsOneWidget);
    expect(find.text('Old catalog title'), findsNothing);
    final stored = await itineraryStore.load();
    expect(stored.values.single['afternoon']?.title, 'Palace of Culture');
    expect(stored.values.single['afternoon']?.subtitle, 'Local activity');
  });

  testWidgets('adapts an outdoor stop without clearing visible filters',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _AdaptiveFilterRepository();
    final itineraryStore = MemoryItineraryStore(
      initial: const {
        '1:2026-10-2': {
          'morning': ItineraryItem(
            sourceKey: 'activity:test:99',
            sourceType: 'activity',
            title: 'Copou walk',
            subtitle: 'Outdoor activity',
            period: 'morning',
            indoor: false,
          ),
          'afternoon': ItineraryItem(
            sourceKey: 'activity:test:100',
            sourceType: 'activity',
            title: 'Cafe stop',
            subtitle: 'Indoor activity',
            period: 'afternoon',
            indoor: true,
          ),
        },
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          itineraryStore: itineraryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tune ideas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outdoor'));
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(find.text('Outdoor'), findsOneWidget);
    final adaptButton = find.byKey(const ValueKey('adapt-day-plan'));
    await tester.ensureVisible(adaptButton);
    await tester.pumpAndSettle();
    await tester.tap(adaptButton);
    await tester.pumpAndSettle();

    expect(
      repository.recommendationRequests
          .any((filters) => filters.setting == 'indoor'),
      isTrue,
    );
    expect(find.text('Morning · Palace of Culture'), findsOneWidget);
    expect(find.text('Outdoor'), findsOneWidget);
    expect(
      find.text('1 outdoor stop was replaced with indoor options.'),
      findsOneWidget,
    );
  });

  testWidgets('moves an outdoor stop to a free safer period', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final itineraryStore = MemoryItineraryStore(
      initial: const {
        '1:2026-10-2': {
          'morning': ItineraryItem(
            sourceKey: 'activity:test:99',
            sourceType: 'activity',
            title: 'Copou walk',
            subtitle: 'Outdoor activity',
            period: 'morning',
            indoor: false,
          ),
        },
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _FakeRepository(),
          itineraryStore: itineraryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    final adaptButton = find.byKey(const ValueKey('adapt-day-plan'));
    await tester.ensureVisible(adaptButton);
    await tester.pumpAndSettle();
    await tester.tap(adaptButton);
    await tester.pumpAndSettle();

    expect(find.text('Morning · Add an idea below'), findsOneWidget);
    expect(find.text('Afternoon · Copou walk'), findsOneWidget);
    expect(
      find.text('1 outdoor stop was moved to a safer period.'),
      findsOneWidget,
    );
    final stored = await itineraryStore.load();
    expect(stored.values.single['afternoon']?.title, 'Copou walk');

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Morning · Copou walk'), findsOneWidget);
    expect(find.text('Afternoon · Add an idea below'), findsOneWidget);
    final restored = await itineraryStore.load();
    expect(restored.values.single['morning']?.title, 'Copou walk');
    expect(restored.values.single['afternoon'], isNull);
  });

  testWidgets(
      'reports outdoor stops that remain risky after partial adaptation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final itineraryStore = MemoryItineraryStore(
      initial: const {
        '1:2026-10-2': {
          'morning': ItineraryItem(
            sourceKey: 'activity:test:morning',
            sourceType: 'activity',
            title: 'Morning walk',
            subtitle: 'Outdoor activity',
            period: 'morning',
            indoor: false,
          ),
          'afternoon': ItineraryItem(
            sourceKey: 'activity:test:afternoon',
            sourceType: 'activity',
            title: 'Cafe stop',
            subtitle: 'Indoor activity',
            period: 'afternoon',
            indoor: true,
          ),
          'evening': ItineraryItem(
            sourceKey: 'activity:test:evening',
            sourceType: 'activity',
            title: 'Evening walk',
            subtitle: 'Outdoor activity',
            period: 'evening',
            indoor: false,
          ),
        },
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _FakeRepository(),
          itineraryStore: itineraryStore,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    final adaptButton = find.byKey(const ValueKey('adapt-day-plan'));
    await tester.ensureVisible(adaptButton);
    await tester.pumpAndSettle();
    await tester.tap(adaptButton);
    await tester.pumpAndSettle();

    expect(find.text('Morning · Palace of Culture'), findsOneWidget);
    expect(find.text('Evening · Evening walk'), findsOneWidget);
    expect(
      find.text(
        '1 outdoor stop was replaced with indoor options. 1 stop remains exposed to the weather.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Weather may affect 1 outdoor stop.'),
      findsOneWidget,
    );
  });

  testWidgets('adds a cinema time to the evening plan', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Movies'));
    await tester.pumpAndSettle();
    final addShowtime =
        find.byKey(const ValueKey('add-showtime-7:9:19:30:standard'));
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '19:30'));
    await tester.pumpAndSettle();
    await tester.tap(addShowtime);
    await tester.pumpAndSettle();

    expect(find.text('Evening · Rain Story'), findsOneWidget);
    expect(find.text('Central Cinema · 19:30'), findsOneWidget);

    final movieIdea = find.byKey(const ValueKey('recommendation-movie-3'));
    await tester.ensureVisible(movieIdea);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('add-recommendation-movie-3')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Movie idea'), findsOneWidget);
    expect(find.text('Evening plan updated.'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Central Cinema · 19:30'), findsOneWidget);
  });

  testWidgets('opens a date-scoped event idea', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('See ideas for this day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(repository.lastFilters.type, 'event');
    expect(find.text('Iași Jazz Evening'), findsOneWidget);
    expect(find.text('Test Hall · 19:30'), findsOneWidget);

    final eventIdea = find.byKey(const ValueKey('recommendation-event-2'));
    await tester.ensureVisible(eventIdea);
    await tester.pumpAndSettle();
    await tester.tap(eventIdea);
    await tester.pumpAndSettle();

    expect(find.text('Event idea'), findsOneWidget);
    expect(find.text('Iași Jazz Evening'), findsWidgets);
  });

  testWidgets('lets the user choose between matching places', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _AmbiguousLocationRepository();
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), 'Paris');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Which Paris?'), findsOneWidget);
    expect(find.text('Île-de-France · France'), findsOneWidget);
    expect(find.text('Texas · United States'), findsOneWidget);

    await tester.tap(find.text('Texas · United States'));
    await tester.pumpAndSettle();

    expect(repository.selectedLocation?.id, 102);
    expect(find.text('Paris'), findsWidgets);
  });

  testWidgets('suggests locations while typing and opens one directly',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _TrackingAutocompleteRepository();
    await tester.pumpWidget(
      _localizedHome(
        locale: const Locale('ro'),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), 'Pa');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(SearchBar), 'Paris');
    await tester.pump(const Duration(milliseconds: 349));
    expect(repository.suggestionQueries, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(repository.suggestionQueries, ['Paris']);
    expect(find.text('Locuri sugerate'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('location-suggestion-101')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('location-suggestion-102')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('location-suggestion-102')));
    await tester.pumpAndSettle();

    expect(repository.selectedLocation?.id, 102);
    expect(_controllerText(tester), 'Paris');
    expect(find.text('Locuri sugerate'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saves the current location in the device library',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryLocationLibraryStore();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _FakeRepository(),
          locationLibraryStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save Iași'));
    await tester.pumpAndSettle();
    expect(find.text('Iași saved on this device.'), findsOneWidget);
    expect((await store.load()).saved.single.name, 'Iași');

    await tester.tap(find.byTooltip('Saved and recent places'));
    await tester.pumpAndSettle();
    expect(find.text('Saved & recent places'), findsOneWidget);
    expect(find.text('Saved places'), findsOneWidget);
    expect(find.byKey(const ValueKey('stored-location-1')), findsOneWidget);
    expect(find.text('Stored only on this device'), findsOneWidget);
  });

  testWidgets('opens a recent place without another geocoding search',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _AmbiguousLocationRepository();
    const parisTexas = Location(
      id: 102,
      name: 'Paris',
      displayName: 'Paris, Texas, United States',
      countryCode: 'US',
      countryName: 'United States',
      adminArea: 'Texas',
      latitude: 33.6609,
      longitude: -95.5555,
      timezone: 'America/Chicago',
    );
    final store = MemoryLocationLibraryStore(
      initial: const LocationLibrary(recent: [parisTexas]),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          locationLibraryStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Saved and recent places'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stored-location-102')));
    await tester.pumpAndSettle();

    expect(repository.selectedLocation?.id, 102);
    expect(find.text('Paris'), findsWidgets);
    expect(_controllerText(tester), 'Paris');
  });

  testWidgets('surfaces a planning advisory for the selected forecast day',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(repository: _AdvisoryRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan around this forecast'), findsNothing);
    final forecastDay = find.byKey(const ValueKey('forecast-day-2'));
    await tester.ensureVisible(forecastDay);
    await tester.pumpAndSettle();
    await tester.tap(forecastDay);
    await tester.pumpAndSettle();

    expect(find.text('Plan around this forecast'), findsOneWidget);
    expect(find.text('Strong wind'), findsOneWidget);
    expect(
      find.text('Forecast guidance, not an official weather warning.'),
      findsOneWidget,
    );
  });

  testWidgets('enables opt-in forecast reminders for the current place',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryAdvisoryNotificationStore();
    final scheduler = _FakeAdvisoryNotificationScheduler();

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _AdvisoryRepository(),
          advisoryNotificationStore: store,
          advisoryNotificationScheduler: scheduler,
          advisoryNotificationPlanner: const _FixedNotificationPlanner(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Forecast reminders'));
    await tester.pumpAndSettle();
    expect(find.text('Forecast reminders'), findsOneWidget);
    expect(
      find.text('Permission is requested only after you save.'),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('advisory-reminders-switch')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-advisory-reminders')));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(scheduler.scheduled, hasLength(1));
    expect((await store.load()).locationName, 'Iași');
    expect(find.text('1 forecast reminder scheduled.'), findsOneWidget);
    expect(find.byTooltip('Forecast reminders on'), findsOneWidget);
  });

  testWidgets('keeps reminder settings open when permission is denied',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryAdvisoryNotificationStore();
    final scheduler = _FakeAdvisoryNotificationScheduler(permitted: false);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: _AdvisoryRepository(),
          advisoryNotificationStore: store,
          advisoryNotificationScheduler: scheduler,
          advisoryNotificationPlanner: const _FixedNotificationPlanner(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Forecast reminders'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('advisory-reminders-switch')),
        matching: find.byType(Switch),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-advisory-reminders')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Notification permission was not granted. Enable WeatherWise notifications in this device’s system settings, then try again.',
      ),
      findsOneWidget,
    );
    expect((await store.load()).enabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
  });
}

Widget _localizedHome({
  required Locale locale,
  required WeatherRepository repository,
}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeScreen(repository: repository),
    );

String _controllerText(WidgetTester tester) =>
    tester.widget<SearchBar>(find.byType(SearchBar)).controller!.text;

class _FakeRepository implements WeatherRepository {
  RecommendationFilters lastFilters = const RecommendationFilters();
  CinemaShowtime? lastBookedShowtime;
  bool refreshRequested = false;

  @override
  Future<ActivityAvailability> activityAvailability({
    required DailyForecast forecast,
    required PlanRecommendation recommendation,
    required String period,
  }) async =>
      ActivityAvailability(
        status: 'not_configured',
        label: 'Live hours are not available',
        detail: 'Confirm before visiting.',
        period: period,
      );

  @override
  Future<List<PlanRecommendation>> recommendations({
    required Location location,
    required DailyForecast forecast,
    RecommendationFilters filters = const RecommendationFilters(),
    Set<int> excludedMovieIds = const {},
  }) async {
    lastFilters = filters;
    if (filters.type == 'event') {
      return [
        PlanRecommendation(
          id: 2,
          type: 'event',
          title: 'Iași Jazz Evening',
          summary: 'A local jazz event scheduled for this forecast day.',
          venueName: 'Test Hall',
          indoor: true,
          genres: const ['jazz'],
          tags: const ['event', 'setting-unverified'],
          score: 70,
          reason:
              'Scheduled locally for this forecast day; venue setting is unverified',
          provider: 'ticketmaster',
          eventDate: DateTime(2026, 10, 2),
          eventTime: '19:30:00',
          eventStatus: 'onsale',
          priceLabel: '80–120 RON',
          recommendedPeriods: const ['evening'],
        ),
      ];
    }
    if (filters.type == 'movie') {
      return const [
        PlanRecommendation(
          id: 3,
          type: 'movie',
          title: 'Rain Story',
          summary: 'A mystery for a rainy evening.',
          indoor: true,
          genres: ['mystery'],
          tags: ['movie'],
          score: 80,
          reason: 'A relaxed indoor choice for this forecast',
          provider: 'tmdb',
          recommendedPeriods: ['evening'],
        ),
      ];
    }
    return const [
      PlanRecommendation(
        id: 1,
        type: 'activity',
        title: 'Palace of Culture',
        summary: 'Indoor museum visit',
        venueName: 'Palace of Culture',
        indoor: true,
        genres: [],
        tags: ['museum'],
        score: 85,
        reason: 'A sheltered choice for rain conditions',
        provider: 'openstreetmap',
        distanceKm: 1.2,
        attributionLabel: '© OpenStreetMap contributors',
      ),
    ];
  }

  @override
  Future<ForecastResult> search(String query) async => ForecastResult(
        location: const Location(
          id: 1,
          name: 'Iași',
          displayName: 'Iași, RO',
          countryCode: 'RO',
          latitude: 47.1585,
          longitude: 27.6014,
          timezone: 'Europe/Bucharest',
        ),
        forecasts: [
          DailyForecast(
            id: 1,
            date: DateTime(2026, 10, 2),
            label: 'Rain',
            weatherClass: 'rain',
            activityContext: 'indoor',
            minC: 8,
            maxC: 14,
            rainProbability: 80,
            windSpeedKph: 12,
            uvIndexMax: 4.8,
            sunriseLocal: '2026-10-02T07:13',
            sunsetLocal: '2026-10-02T18:49',
            daylightDurationSeconds: 41760,
            current: const CurrentConditions(
              observedAt: '2026-10-02T16:15',
              label: 'Mainly clear',
              weatherClass: 'clear',
              temperatureC: 13.6,
              apparentTemperatureC: 11.2,
              precipitationMm: 0,
              windSpeedKph: 9.4,
              daylight: true,
            ),
          ),
        ],
        updatedAt: DateTime.now().toUtc(),
      );

  @override
  Future<LocationSearchPage> searchLocations(
    String query, {
    int page = 1,
    int perPage = 5,
  }) async =>
      LocationSearchPage(
        locations: page == 1
            ? const [
                Location(
                  id: 1,
                  name: 'Iași',
                  displayName: 'Iași, Romania',
                  countryCode: 'RO',
                  countryName: 'Romania',
                  adminArea: 'Iași County',
                  latitude: 47.1585,
                  longitude: 27.6014,
                  timezone: 'Europe/Bucharest',
                ),
              ]
            : const [],
        page: page,
        perPage: perPage,
        hasMore: false,
      );

  @override
  Future<ForecastResult> forecastFor(
    Location location, {
    bool refresh = false,
  }) async {
    refreshRequested = refresh;
    return search(location.name);
  }

  @override
  Future<List<HourlyForecast>> hourlyForecast({
    required Location location,
    required DailyForecast forecast,
  }) async =>
      List.generate(24, (hour) {
        final outdoors = hour >= 14 && hour <= 19;
        return HourlyForecast(
          time: DateTime(2026, 10, 2, hour),
          label: outdoors ? 'Mainly clear' : 'Rain',
          weatherClass: outdoors ? 'clear' : 'rain',
          activityContext: outdoors ? 'outdoor' : 'indoor',
          temperatureC: outdoors ? 17 : 11,
          rainProbability: outdoors ? 10 : 80,
          windSpeedKph: 12,
          daylight: hour >= 7 && hour <= 19,
        );
      });

  @override
  Future<List<CinemaShowtime>> showtimes({
    required Location location,
    required DailyForecast forecast,
  }) async =>
      [
        CinemaShowtime(
          id: '7:9:19:30:standard',
          filmId: '7',
          filmTitle: 'Rain Story',
          cinemaId: '9',
          cinemaName: 'Central Cinema',
          date: forecast.date,
          format: 'Standard',
          startTime: '19:30',
          endTime: '21:40',
          distanceKm: 3.2,
          attributionLabel: 'Cinema and showtime data by MovieGlu',
        ),
      ];

  @override
  Future<Uri?> showtimeBookingLink({
    required DailyForecast forecast,
    required CinemaShowtime showtime,
  }) async {
    lastBookedShowtime = showtime;
    return Uri.parse('https://cinema.example.test/book');
  }
}

class _AdaptiveFilterRepository extends _FakeRepository {
  final List<RecommendationFilters> recommendationRequests = [];

  @override
  Future<List<PlanRecommendation>> recommendations({
    required Location location,
    required DailyForecast forecast,
    RecommendationFilters filters = const RecommendationFilters(),
    Set<int> excludedMovieIds = const {},
  }) async {
    recommendationRequests.add(filters);
    if (filters.setting == 'outdoor') {
      return const [
        PlanRecommendation(
          id: 99,
          type: 'activity',
          title: 'Copou walk',
          summary: 'An outdoor city walk.',
          indoor: false,
          genres: [],
          tags: ['outdoor'],
          score: 90,
          reason: 'Matches your outdoor preference for this day',
          provider: 'test',
          recommendedPeriods: ['morning', 'afternoon'],
        ),
      ];
    }
    return super.recommendations(
      location: location,
      forecast: forecast,
      filters: filters,
      excludedMovieIds: excludedMovieIds,
    );
  }
}

class _LocalizedRecommendationRepository extends _FakeRepository {
  _LocalizedRecommendationRepository(this.title);

  final String title;

  @override
  Future<List<PlanRecommendation>> recommendations({
    required Location location,
    required DailyForecast forecast,
    RecommendationFilters filters = const RecommendationFilters(),
    Set<int> excludedMovieIds = const {},
  }) async {
    if (filters.type != null) {
      return super.recommendations(
        location: location,
        forecast: forecast,
        filters: filters,
        excludedMovieIds: excludedMovieIds,
      );
    }
    return [
      PlanRecommendation(
        id: 1,
        type: 'activity',
        title: title,
        summary: 'Localized indoor museum visit',
        venueName: title,
        indoor: true,
        genres: const [],
        tags: const ['museum'],
        score: 85,
        reason: 'A sheltered choice for rain conditions',
        provider: 'openstreetmap',
        distanceKm: 1.2,
      ),
    ];
  }
}

class _AmbiguousLocationRepository extends _FakeRepository {
  Location? selectedLocation;

  @override
  Future<LocationSearchPage> searchLocations(
    String query, {
    int page = 1,
    int perPage = 5,
  }) async =>
      LocationSearchPage(
        locations: page == 1
            ? const [
                Location(
                  id: 101,
                  name: 'Paris',
                  displayName: 'Paris, Île-de-France, France',
                  countryCode: 'FR',
                  countryName: 'France',
                  adminArea: 'Île-de-France',
                  population: 2138551,
                  latitude: 48.8566,
                  longitude: 2.3522,
                  timezone: 'Europe/Paris',
                ),
                Location(
                  id: 102,
                  name: 'Paris',
                  displayName: 'Paris, Texas, United States',
                  countryCode: 'US',
                  countryName: 'United States',
                  adminArea: 'Texas',
                  population: 24782,
                  latitude: 33.6609,
                  longitude: -95.5555,
                  timezone: 'America/Chicago',
                ),
              ]
            : const [],
        page: page,
        perPage: perPage,
        hasMore: false,
      );

  @override
  Future<ForecastResult> forecastFor(
    Location location, {
    bool refresh = false,
  }) async {
    selectedLocation = location;
    final result = await super.search(location.name);
    return ForecastResult(
      location: location,
      forecasts: result.forecasts,
    );
  }
}

class _TrackingAutocompleteRepository extends _AmbiguousLocationRepository {
  final List<String> suggestionQueries = [];

  @override
  Future<LocationSearchPage> searchLocations(
    String query, {
    int page = 1,
    int perPage = 5,
  }) {
    suggestionQueries.add(query);
    return super.searchLocations(query, page: page, perPage: perPage);
  }
}

class _FailingLocationSearchRepository extends _FakeRepository {
  @override
  Future<LocationSearchPage> searchLocations(
    String query, {
    int page = 1,
    int perPage = 5,
  }) =>
      throw const WeatherRepositoryException('offline');
}

class _FailingRefreshRepository extends _FakeRepository {
  @override
  Future<ForecastResult> forecastFor(
    Location location, {
    bool refresh = false,
  }) {
    if (refresh) {
      throw const WeatherRepositoryException('Refresh unavailable');
    }
    return super.forecastFor(location, refresh: refresh);
  }
}

class _ControlledHourlyRepository extends _FakeRepository {
  final firstRequest = Completer<List<HourlyForecast>>();
  int hourlyCalls = 0;

  @override
  Future<List<HourlyForecast>> hourlyForecast({
    required Location location,
    required DailyForecast forecast,
  }) {
    hourlyCalls += 1;
    if (hourlyCalls == 1) return firstRequest.future;
    return super.hourlyForecast(location: location, forecast: forecast);
  }
}

class _AdvisoryRepository extends _FakeRepository {
  @override
  Future<ForecastResult> search(String query) async {
    final ordinary = await super.search(query);
    return ForecastResult(
      location: ordinary.location,
      forecasts: [
        ordinary.forecasts.single,
        DailyForecast(
          id: 2,
          date: DateTime(2026, 10, 3),
          label: 'Windy',
          weatherClass: 'cloudy',
          activityContext: 'caution',
          minC: 7,
          maxC: 13,
          rainProbability: 20,
          windSpeedKph: 48,
          advisories: const [
            WeatherAdvisory(
              code: 'strong_wind',
              severity: 'moderate',
              title: 'Strong wind',
              message:
                  'Prefer sheltered routes and reconsider exposed outdoor activities.',
            ),
          ],
        ),
      ],
    );
  }
}

class _FailingPreferenceProfileStore implements PreferenceProfileStore {
  @override
  Future<List<PreferenceProfile>> load() =>
      Future.error(StateError('Storage unavailable'));

  @override
  Future<void> save(List<PreferenceProfile> profiles) =>
      Future.error(StateError('Storage unavailable'));
}

class _FakeAdvisoryNotificationScheduler
    implements AdvisoryNotificationScheduler {
  _FakeAdvisoryNotificationScheduler({this.permitted = true});

  final bool permitted;
  int permissionRequests = 0;
  List<PlannedAdvisoryNotification> scheduled = const [];

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return permitted;
  }

  @override
  Future<void> replaceAll(
    List<PlannedAdvisoryNotification> notifications,
  ) async {
    scheduled = notifications;
  }

  @override
  Future<void> cancelAll() async => scheduled = const [];
}

class _FixedNotificationPlanner extends AdvisoryNotificationPlanner {
  const _FixedNotificationPlanner();

  @override
  List<PlannedAdvisoryNotification> build({
    required AdvisoryNotificationPreferences preferences,
    required Location location,
    required List<DailyForecast> forecasts,
    DateTime? now,
    AppStrings strings = const AppStrings(Locale('en')),
  }) =>
      preferences.follows(location)
          ? [
              PlannedAdvisoryNotification(
                id: 1,
                scheduledAt: DateTime(2099, 1, 1, 8),
                title: '${location.name}: Strong wind',
                body: 'Prefer sheltered routes.',
                payload: '{}',
              ),
            ]
          : const [];
}

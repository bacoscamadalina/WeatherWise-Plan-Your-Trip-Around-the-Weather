import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/l10n/app_strings.dart';
import 'package:weatherwise/models/advisory_notification_preferences.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/location_search_page.dart';
import 'package:weatherwise/models/weather_advisory.dart';
import 'package:weatherwise/widgets/advisory_notification_sheet.dart';
import 'package:weatherwise/widgets/forecast_advisory_panel.dart';
import 'package:weatherwise/widgets/location_library_sheet.dart';
import 'package:weatherwise/widgets/location_picker_sheet.dart';

void main() {
  testWidgets('localizes saved and recent places in Romanian', (tester) async {
    await tester.pumpWidget(
      _romanianApp(
        LocationLibrarySheet(
          saved: const [_iasi],
          recent: const [],
          onToggleSaved: (_) async => false,
        ),
      ),
    );

    expect(find.text('Locuri salvate și recente'), findsOneWidget);
    expect(find.text('Locuri salvate'), findsOneWidget);
    expect(find.text('Stocate doar pe acest dispozitiv'), findsOneWidget);
    expect(find.byTooltip('Elimină Iași din locurile salvate'), findsOneWidget);
  });

  testWidgets('localizes ambiguous location selection in Romanian',
      (tester) async {
    await tester.pumpWidget(
      _romanianApp(
        LocationPickerSheet(
          query: 'Paris',
          initialPage: const LocationSearchPage(
            locations: [_paris],
            page: 1,
            perPage: 5,
            hasMore: true,
          ),
          loadPage: (_) async => const LocationSearchPage(
            locations: [],
            page: 2,
            perPage: 5,
            hasMore: false,
          ),
        ),
      ),
    );

    expect(find.text('Care „Paris”?'), findsOneWidget);
    expect(
      find.text('Alege un oraș sau un sat pentru a vedea prognoza pe 14 zile.'),
      findsOneWidget,
    );
    expect(find.text('2.148.000 locuitori'), findsOneWidget);
    expect(find.text('Arată mai multe'), findsOneWidget);
  });

  testWidgets('localizes reminder settings in Romanian', (tester) async {
    await tester.pumpWidget(
      _romanianApp(
        AdvisoryNotificationSheet(
          location: _iasi,
          preferences: const AdvisoryNotificationPreferences(),
          supported: true,
          onSave: (_) async => 0,
        ),
      ),
    );

    expect(find.text('Mementouri pentru prognoză'), findsOneWidget);
    expect(find.text('Amintește-mi despre acest loc'), findsOneWidget);
    expect(find.text('Ora mementoului'), findsOneWidget);
    expect(find.text('Toate recomandările de planificare'), findsOneWidget);
    expect(find.text('Salvează mementourile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes structured planning advisories in Romanian',
      (tester) async {
    await tester.pumpWidget(
      _romanianApp(
        const ForecastAdvisoryPanel(
          advisories: [
            WeatherAdvisory(
              code: 'strong_wind',
              severity: 'moderate',
              title: 'Strong wind',
              message: 'Prefer sheltered routes.',
            ),
          ],
        ),
      ),
    );

    expect(
      find.text('Planifică în funcție de această prognoză'),
      findsOneWidget,
    );
    expect(find.text('Vânt puternic'), findsOneWidget);
    expect(
      find.text(
        'Preferă traseele adăpostite și reconsideră activitățile în aer liber expuse.',
      ),
      findsOneWidget,
    );
  });
}

Widget _romanianApp(Widget child) => MaterialApp(
      locale: const Locale('ro'),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

const _iasi = Location(
  id: 1,
  name: 'Iași',
  displayName: 'Iași, România',
  countryCode: 'RO',
  countryName: 'România',
  latitude: 47.1585,
  longitude: 27.6014,
  timezone: 'Europe/Bucharest',
);

const _paris = Location(
  id: 2,
  name: 'Paris',
  displayName: 'Paris, Île-de-France, France',
  countryCode: 'FR',
  countryName: 'France',
  adminArea: 'Île-de-France',
  latitude: 48.8566,
  longitude: 2.3522,
  timezone: 'Europe/Paris',
  population: 2148000,
);

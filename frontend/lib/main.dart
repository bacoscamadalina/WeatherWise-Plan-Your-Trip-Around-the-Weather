import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_strings.dart';
import 'screens/home_screen.dart';
import 'services/itinerary_store.dart';
import 'services/advisory_notification_preferences_store.dart';
import 'services/advisory_notification_scheduler.dart';
import 'services/location_library_store.dart';
import 'services/preference_profile_store.dart';
import 'services/weather_repository.dart';
import 'services/trip_repository.dart';
import 'services/auth_repository.dart';
import 'services/session_controller.dart';
import 'theme/atlas_theme.dart';

/*
THESIS: Weather becomes a sunlit travel atlas that turns conditions into a day plan, refusing the dark dashboard stack.
OWN-WORLD: Warm ivory paper, atlas-blue ink, azure rules, golden daylight, coral accents, editorial serif display type, and chromatic index tabs.
STORY: Search a place, read its daylight story, scan the forecast ribbon, then open one practical plan.
FIRST VIEWPORT: A quiet paper navigation bar leads into an asymmetric daylight field with the temperature at editorial scale, a precise weather narrative, and one white plan strip; the forecast tabs continue immediately below.
FORM: Atlas de lumină; assigned direction 4; seed 97c9e211; approved comp .impeccable/mocks/decision/atlas-de-lumina.png.
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
*/

void main() {
  runApp(const WeatherWiseApp());
}

class WeatherWiseApp extends StatefulWidget {
  const WeatherWiseApp({super.key});

  @override
  State<WeatherWiseApp> createState() => _WeatherWiseAppState();
}

class _WeatherWiseAppState extends State<WeatherWiseApp> {
  static const _localeKey = 'weatherwise.locale';
  Locale? _locale;
  late final SessionController _sessionController;
  late final ApiTripRepository _tripRepository;

  @override
  void initState() {
    super.initState();
    _sessionController = SessionController(
      repository: ApiAuthRepository(),
      tokenStore: SecureSessionTokenStore(),
    )..addListener(_onSessionChanged);
    _tripRepository = ApiTripRepository(
      tokenProvider: () => _sessionController.token,
      languageCodeProvider: () {
        final systemLanguage =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        return _locale?.languageCode ??
            (AppStrings.supportedLocales
                    .any((locale) => locale.languageCode == systemLanguage)
                ? systemLanguage
                : 'en');
      },
    );
    _sessionController.restore();
    _loadLocale();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sessionController
      ..removeListener(_onSessionChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_localeKey);
    if (!mounted || languageCode == null) return;
    if (AppStrings.supportedLocales
        .any((locale) => locale.languageCode == languageCode)) {
      setState(() => _locale = Locale(languageCode));
    }
  }

  Future<void> _changeLocale(Locale locale) async {
    if (_locale?.languageCode == locale.languageCode) return;
    setState(() => _locale = locale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final systemLanguage =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final effectiveLanguage = _locale?.languageCode ??
        (AppStrings.supportedLocales
                .any((locale) => locale.languageCode == systemLanguage)
            ? systemLanguage
            : 'en');
    return MaterialApp(
      title: 'WeatherWise',
      debugShowCheckedModeBanner: false,
      locale: Locale(effectiveLanguage),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AtlasTheme.light(),
      darkTheme: AtlasTheme.light(),
      themeMode: ThemeMode.light,
      home: HomeScreen(
        repository: ResilientWeatherRepository(
          api: ApiWeatherRepository(languageCode: effectiveLanguage),
        ),
        tripRepository: _tripRepository,
        sessionController: _sessionController,
        onLocaleChanged: _changeLocale,
        advisoryNotificationStore: SharedPreferencesAdvisoryNotificationStore(),
        advisoryNotificationScheduler: LocalAdvisoryNotificationScheduler(),
        itineraryStore: SharedPreferencesItineraryStore(),
        locationLibraryStore: SharedPreferencesLocationLibraryStore(),
        preferenceProfileStore: SharedPreferencesPreferenceProfileStore(),
      ),
    );
  }
}

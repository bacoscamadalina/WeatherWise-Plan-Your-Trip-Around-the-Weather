import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/cinema_showtime.dart';
import '../models/advisory_notification_preferences.dart';
import '../models/daily_forecast.dart';
import '../models/event_day_summary.dart';
import '../models/forecast_result.dart';
import '../models/hourly_forecast.dart';
import '../models/itinerary_item.dart';
import '../models/location.dart';
import '../models/location_library.dart';
import '../models/plan_recommendation.dart';
import '../models/preference_profile.dart';
import '../models/recommendation_filters.dart';
import '../services/day_plan_builder.dart';
import '../services/calendar_plan_link.dart';
import '../services/itinerary_route_link.dart';
import '../services/adaptive_day_plan.dart';
import '../services/itinerary_weather_planner.dart';
import '../services/itinerary_store.dart';
import '../services/advisory_notification_planner.dart';
import '../services/advisory_notification_preferences_store.dart';
import '../services/advisory_notification_scheduler.dart';
import '../services/location_library_store.dart';
import '../services/movie_rotation_ledger.dart';
import '../services/preference_profile_store.dart';
import '../services/weather_repository.dart';
import '../services/trip_repository.dart';
import '../services/session_controller.dart';
import '../theme/atlas_theme.dart';
import 'recommendation_detail_screen.dart';
import 'trip_planner_screen.dart';
import 'account_screen.dart';
import '../widgets/forecast_rail.dart';
import '../widgets/advisory_notification_sheet.dart';
import '../widgets/forecast_advisory_panel.dart';
import '../widgets/forecast_trend_chart.dart';
import '../widgets/hourly_forecast_section.dart';
import '../widgets/location_library_sheet.dart';
import '../widgets/location_picker_sheet.dart';
import '../widgets/recommendation_filter_sheet.dart';
import '../widgets/recommendation_panel.dart';
import '../widgets/weather_hero.dart';

typedef ShowtimeLinkLauncher = Future<bool> Function(Uri uri);
typedef PlanClipboardWriter = Future<void> Function(String text);
typedef PlanCalendarLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchShowtimeLink(Uri uri) => launchUrl(uri);
Future<void> _writePlanToClipboard(String text) =>
    Clipboard.setData(ClipboardData(text: text));

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.repository,
    this.tripRepository,
    this.sessionController,
    this.showtimeLinkLauncher = _launchShowtimeLink,
    this.itineraryStore,
    this.advisoryNotificationStore,
    this.advisoryNotificationScheduler,
    this.advisoryNotificationPlanner = const AdvisoryNotificationPlanner(),
    this.locationLibraryStore,
    this.preferenceProfileStore,
    this.planClipboardWriter = _writePlanToClipboard,
    this.planCalendarLauncher = _launchShowtimeLink,
    this.planRouteLauncher = _launchShowtimeLink,
    this.onLocaleChanged,
    super.key,
  });

  final WeatherRepository repository;
  final TripRepository? tripRepository;
  final SessionController? sessionController;
  final ShowtimeLinkLauncher showtimeLinkLauncher;
  final ItineraryStore? itineraryStore;
  final AdvisoryNotificationPreferencesStore? advisoryNotificationStore;
  final AdvisoryNotificationScheduler? advisoryNotificationScheduler;
  final AdvisoryNotificationPlanner advisoryNotificationPlanner;
  final LocationLibraryStore? locationLibraryStore;
  final PreferenceProfileStore? preferenceProfileStore;
  final PlanClipboardWriter planClipboardWriter;
  final PlanCalendarLauncher planCalendarLauncher;
  final PlanCalendarLauncher planRouteLauncher;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController(text: 'Iași');
  ForecastResult? _result;
  String? _error;
  bool _loading = false;
  bool _refreshing = false;
  Timer? _locationSuggestionDebounce;
  int _locationSuggestionGeneration = 0;
  List<Location> _locationSuggestions = const [];
  bool _locationSuggestionsLoading = false;
  bool _locationSuggestionsActive = false;
  bool _locationSuggestionsError = false;
  int? _expandedForecastId;
  RecommendationFilters _recommendationFilters = const RecommendationFilters();
  List<PlanRecommendation> _recommendations = const [];
  bool _recommendationsLoading = false;
  String? _recommendationsError;
  int _recommendationsRequestGeneration = 0;
  List<EventDaySummary> _eventDays = const [];
  bool _eventDaysLoading = false;
  String? _eventDaysError;
  int _eventDaysRequestGeneration = 0;
  PlanRecommendation? _recommendationPreview;
  bool _recommendationPreviewLoading = false;
  int? _recommendationPreviewForecastId;
  int _recommendationPreviewGeneration = 0;
  List<CinemaShowtime> _showtimes = const [];
  bool _showtimesLoading = false;
  String? _showtimesError;
  int? _showtimesForecastId;
  List<HourlyForecast> _hourlyForecasts = const [];
  bool _hourlyForecastsLoading = false;
  String? _hourlyForecastsError;
  int? _hourlyForecastId;
  int _hourlyRequestGeneration = 0;
  String? _bookingShowtimeId;
  int? _adaptingForecastId;
  final Map<String, Map<String, ItineraryItem>> _itineraries = {};
  final MovieRotationLedger _movieRotationLedger = MovieRotationLedger();
  static const _dayPlanBuilder = DayPlanBuilder();
  static const _calendarPlanLink = CalendarPlanLink();
  static const _itineraryRouteLink = ItineraryRouteLink();
  static const _itineraryWeatherPlanner = ItineraryWeatherPlanner();
  static const _adaptiveDayPlan = AdaptiveDayPlan();
  late final ItineraryStore _itineraryStore;
  late final Future<void> _itineraryReady;
  late final AdvisoryNotificationPreferencesStore _advisoryNotificationStore;
  late final AdvisoryNotificationScheduler _advisoryNotificationScheduler;
  late final Future<void> _advisoryNotificationReady;
  AdvisoryNotificationPreferences _advisoryNotificationPreferences =
      const AdvisoryNotificationPreferences();
  late final LocationLibraryStore _locationLibraryStore;
  late final Future<void> _locationLibraryReady;
  LocationLibrary _locationLibrary = const LocationLibrary();
  late final PreferenceProfileStore _preferenceProfileStore;
  List<PreferenceProfile> _preferenceProfiles = const [];
  bool _storageFailureShown = false;
  bool _locationStorageFailureShown = false;
  bool _notificationFailureShown = false;
  final GlobalKey _advisoryKey = GlobalKey();
  final GlobalKey _trendKey = GlobalKey();
  final GlobalKey _hourlyKey = GlobalKey();
  final GlobalKey _recommendationsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _itineraryStore = SerializedItineraryStore(
      widget.itineraryStore ?? MemoryItineraryStore(),
    );
    _advisoryNotificationStore =
        widget.advisoryNotificationStore ?? MemoryAdvisoryNotificationStore();
    _advisoryNotificationScheduler = widget.advisoryNotificationScheduler ??
        const UnsupportedAdvisoryNotificationScheduler();
    _advisoryNotificationReady = _restoreAdvisoryNotificationPreferences();
    _locationLibraryStore =
        widget.locationLibraryStore ?? MemoryLocationLibraryStore();
    _locationLibraryReady = _restoreLocationLibrary();
    _preferenceProfileStore =
        widget.preferenceProfileStore ?? MemoryPreferenceProfileStore();
    _itineraryReady = _restoreItineraries();
    unawaited(_itineraryReady);
    unawaited(_restorePreferenceProfiles());
    _search();
  }

  @override
  void dispose() {
    _locationSuggestionDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.repository, widget.repository)) return;
    final updatedRepository = widget.repository;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(widget.repository, updatedRepository)) return;
      final result = _result;
      if (result == null) return;
      final forecastId = _expandedForecastId;
      final forecast = forecastId == null
          ? result.forecasts.firstOrNull
          : result.forecasts.where((item) => item.id == forecastId).firstOrNull;
      if (forecast == null) return;
      if (forecastId == null) {
        _loadRecommendationPreview(result, forecast);
      } else {
        _loadRecommendations(forecast, filters: _recommendationFilters);
      }
    });
  }

  void _onLocationQueryChanged(String value) {
    _locationSuggestionDebounce?.cancel();
    final query = value.trim();
    final generation = ++_locationSuggestionGeneration;
    if (query.length < 2) {
      setState(() {
        _locationSuggestions = const [];
        _locationSuggestionsLoading = false;
        _locationSuggestionsActive = false;
        _locationSuggestionsError = false;
      });
      return;
    }

    setState(() {
      _locationSuggestions = const [];
      _locationSuggestionsLoading = true;
      _locationSuggestionsActive = true;
      _locationSuggestionsError = false;
    });
    _locationSuggestionDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadLocationSuggestions(query, generation),
    );
  }

  Future<void> _loadLocationSuggestions(String query, int generation) async {
    try {
      final page = await widget.repository.searchLocations(query, perPage: 5);
      if (!mounted ||
          generation != _locationSuggestionGeneration ||
          _controller.text.trim() != query) {
        return;
      }
      setState(() {
        _locationSuggestions = page.locations;
        _locationSuggestionsError = false;
      });
    } catch (_) {
      if (!mounted || generation != _locationSuggestionGeneration) return;
      setState(() {
        _locationSuggestions = const [];
        _locationSuggestionsError = true;
      });
    } finally {
      if (mounted && generation == _locationSuggestionGeneration) {
        setState(() => _locationSuggestionsLoading = false);
      }
    }
  }

  void _dismissLocationSuggestions() {
    _locationSuggestionDebounce?.cancel();
    _locationSuggestionGeneration += 1;
    if (!_locationSuggestionsActive && !_locationSuggestionsLoading) return;
    setState(() {
      _locationSuggestions = const [];
      _locationSuggestionsLoading = false;
      _locationSuggestionsActive = false;
      _locationSuggestionsError = false;
    });
  }

  void _retryLocationSuggestions() {
    final query = _controller.text.trim();
    if (query.length < 2) return;
    final generation = ++_locationSuggestionGeneration;
    setState(() {
      _locationSuggestionsLoading = true;
      _locationSuggestionsError = false;
    });
    unawaited(_loadLocationSuggestions(query, generation));
  }

  Future<void> _selectLocationSuggestion(Location location) async {
    _dismissLocationSuggestions();
    _controller.text = location.name;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.forecastFor(location);
      if (!mounted) return;
      setState(() {
        _result = result;
        _expandedForecastId = null;
        _recommendations = const [];
        _recommendationPreview = null;
        _recommendationPreviewForecastId = null;
        _recommendationPreviewLoading = false;
        _showtimes = const [];
        _showtimesForecastId = null;
        _clearHourlyForecasts();
      });
      unawaited(_rememberLocation(result.location));
      unawaited(_refreshAdvisoryNotifications(result));
      if (result.forecasts.isNotEmpty) {
        unawaited(_loadRecommendationPreview(result, result.forecasts.first));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppStrings.of(context).locationLoadFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.search(query);
      if (mounted) {
        setState(() {
          _result = result;
          _expandedForecastId = null;
          _recommendations = const [];
          _recommendationPreview = null;
          _recommendationPreviewForecastId = null;
          _recommendationPreviewLoading = false;
          _showtimes = const [];
          _showtimesForecastId = null;
          _clearHourlyForecasts();
        });
        unawaited(_rememberLocation(result.location));
        unawaited(_refreshAdvisoryNotifications(result));
        if (result.forecasts.isNotEmpty) {
          unawaited(_loadRecommendationPreview(result, result.forecasts.first));
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = AppStrings.of(context).locationLoadFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _chooseLocation() async {
    _dismissLocationSuggestions();
    final query = _controller.text.trim();
    if (query.length < 2 || _loading || _refreshing) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final firstPage = await widget.repository.searchLocations(query);
      if (!mounted) return;
      if (firstPage.locations.isEmpty) {
        setState(
          () => _error = AppStrings.of(context).noPlacesMatched(query),
        );
        return;
      }

      Location? selected;
      if (firstPage.locations.length == 1 && !firstPage.hasMore) {
        selected = firstPage.locations.first;
      } else {
        setState(() => _loading = false);
        selected = await showModalBottomSheet<Location>(
          context: context,
          isScrollControlled: true,
          showDragHandle: false,
          useSafeArea: true,
          builder: (_) => LocationPickerSheet(
            query: query,
            initialPage: firstPage,
            loadPage: (page) => widget.repository.searchLocations(
              query,
              page: page,
            ),
          ),
        );
        if (selected == null || !mounted) return;
        setState(() => _loading = true);
      }

      _controller.text = selected.name;
      final result = await widget.repository.forecastFor(selected);
      if (!mounted) return;
      setState(() {
        _result = result;
        _expandedForecastId = null;
        _recommendations = const [];
        _recommendationPreview = null;
        _recommendationPreviewForecastId = null;
        _recommendationPreviewLoading = false;
        _showtimes = const [];
        _showtimesForecastId = null;
        _clearHourlyForecasts();
      });
      unawaited(_rememberLocation(result.location));
      unawaited(_refreshAdvisoryNotifications(result));
      if (result.forecasts.isNotEmpty) {
        unawaited(_loadRecommendationPreview(result, result.forecasts.first));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppStrings.of(context).placeSearchUnavailable,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showLocationLibrary() async {
    await _locationLibraryReady;
    if (!mounted || _loading || _refreshing) return;

    final selected = await showModalBottomSheet<Location>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      builder: (_) => LocationLibrarySheet(
        saved: _locationLibrary.saved,
        recent: _locationLibrary.recent,
        onToggleSaved: _toggleSavedLocation,
      ),
    );
    if (selected != null && mounted) {
      await _loadStoredLocation(selected);
    }
  }

  Future<void> _loadStoredLocation(Location location) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _controller.text = location.name;
    try {
      final result = await widget.repository.forecastFor(location);
      if (!mounted) return;
      setState(() {
        _result = result;
        _expandedForecastId = null;
        _recommendations = const [];
        _recommendationPreview = null;
        _recommendationPreviewForecastId = null;
        _recommendationPreviewLoading = false;
        _showtimes = const [];
        _showtimesForecastId = null;
        _clearHourlyForecasts();
      });
      unawaited(_rememberLocation(result.location));
      unawaited(_refreshAdvisoryNotifications(result));
      if (result.forecasts.isNotEmpty) {
        unawaited(_loadRecommendationPreview(result, result.forecasts.first));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppStrings.of(context).savedPlaceRefreshFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshForecast() async {
    final current = _result;
    if (!mounted || current == null || _loading || _refreshing) return;

    final expandedDate = _expandedForecastId == null
        ? null
        : current.forecasts
            .where((forecast) => forecast.id == _expandedForecastId)
            .firstOrNull
            ?.date;
    setState(() => _refreshing = true);
    try {
      final refreshed = await widget.repository.forecastFor(
        current.location,
        refresh: true,
      );
      if (!mounted) return;
      final refreshedExpanded = expandedDate == null
          ? null
          : refreshed.forecasts
              .where((forecast) => forecast.date == expandedDate)
              .firstOrNull;
      setState(() {
        _result = refreshed;
        _error = null;
        _expandedForecastId = refreshedExpanded?.id;
        _recommendations = const [];
        _recommendationsError = null;
        _recommendationPreviewGeneration += 1;
        _recommendationPreview = null;
        _recommendationPreviewForecastId = null;
        _recommendationPreviewLoading = false;
        _showtimes = const [];
        _showtimesError = null;
        _showtimesForecastId = null;
        _clearHourlyForecasts();
      });
      unawaited(_rememberLocation(refreshed.location));
      unawaited(_refreshAdvisoryNotifications(refreshed));
      if (refreshedExpanded != null) {
        unawaited(_loadHourlyForecasts(refreshedExpanded, force: true));
        await _loadRecommendations(
          refreshedExpanded,
          filters: _recommendationFilters,
        );
      } else if (refreshed.forecasts.isNotEmpty) {
        unawaited(
          _loadRecommendationPreview(refreshed, refreshed.forecasts.first),
        );
      }
      if (mounted) _showMessage(AppStrings.of(context).forecastUpdated);
    } catch (_) {
      if (mounted) {
        _showMessage(AppStrings.of(context).forecastRefreshFailed);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _showAdvisoryNotificationSettings() async {
    await _advisoryNotificationReady;
    final result = _result;
    if (!mounted || result == null || _loading || _refreshing) return;

    final wasFollowing =
        _advisoryNotificationPreferences.follows(result.location);
    final scheduled = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      useSafeArea: true,
      builder: (_) => AdvisoryNotificationSheet(
        location: result.location,
        preferences: _advisoryNotificationPreferences,
        supported: _advisoryNotificationScheduler.isSupported,
        onSave: (preferences) =>
            _saveAdvisoryNotificationPreferences(preferences, result),
      ),
    );
    if (!mounted || scheduled == null) return;

    if (_advisoryNotificationPreferences.follows(result.location)) {
      _showMessage(
        scheduled == 0
            ? AppStrings.of(context).remindersNoMatches
            : AppStrings.of(context).remindersScheduled(scheduled),
      );
    } else if (wasFollowing) {
      _showMessage(AppStrings.of(context).remindersOff);
    }
  }

  Future<int> _saveAdvisoryNotificationPreferences(
    AdvisoryNotificationPreferences preferences,
    ForecastResult result,
  ) async {
    final strings = AppStrings.of(context);
    if (preferences.enabled) {
      final permitted =
          await _advisoryNotificationScheduler.requestPermission();
      if (!permitted) throw const NotificationPermissionDenied();
    }

    final notifications = widget.advisoryNotificationPlanner.build(
      preferences: preferences,
      location: result.location,
      forecasts: result.forecasts,
      strings: strings,
    );
    if (preferences.enabled) {
      await _advisoryNotificationScheduler.replaceAll(notifications);
    } else {
      await _advisoryNotificationScheduler.cancelAll();
    }
    try {
      await _advisoryNotificationStore.save(preferences);
    } catch (_) {
      // Avoid leaving a schedule the UI cannot restore or manage later.
      await _advisoryNotificationScheduler.cancelAll();
      rethrow;
    }
    if (mounted) {
      setState(() => _advisoryNotificationPreferences = preferences);
    }
    return notifications.length;
  }

  Future<void> _restoreAdvisoryNotificationPreferences() async {
    try {
      final preferences = await _advisoryNotificationStore.load();
      if (mounted) {
        setState(() => _advisoryNotificationPreferences = preferences);
      }
    } catch (_) {
      _showNotificationFailure();
    }
  }

  Future<void> _refreshAdvisoryNotifications(ForecastResult result) async {
    await _advisoryNotificationReady;
    if (!mounted) return;
    final strings = AppStrings.of(context);
    final preferences = _advisoryNotificationPreferences;
    if (!preferences.follows(result.location) ||
        !_advisoryNotificationScheduler.isSupported) {
      return;
    }
    try {
      final notifications = widget.advisoryNotificationPlanner.build(
        preferences: preferences,
        location: result.location,
        forecasts: result.forecasts,
        strings: strings,
      );
      await _advisoryNotificationScheduler.replaceAll(notifications);
    } catch (_) {
      _showNotificationFailure();
    }
  }

  void _showNotificationFailure() {
    if (!mounted || _notificationFailureShown) return;
    _notificationFailureShown = true;
    _showMessage(AppStrings.of(context).remindersUpdateFailed);
  }

  Future<bool> _toggleSavedLocation(Location location) async {
    await _locationLibraryReady;
    final updated = _locationLibrary.toggleSaved(location);
    await _locationLibraryStore.save(updated);
    if (mounted) setState(() => _locationLibrary = updated);
    return updated.isSaved(location);
  }

  Future<void> _toggleCurrentSaved(Location location) async {
    try {
      final saved = await _toggleSavedLocation(location);
      if (mounted) {
        _showMessage(
          saved
              ? AppStrings.of(context).placeSaved(location.name)
              : AppStrings.of(context).placeRemoved(location.name),
        );
      }
    } on FormatException {
      if (mounted) _showMessage(AppStrings.of(context).savedPlacesLimit);
    } catch (_) {
      _showLocationStorageFailure();
    }
  }

  Future<void> _restoreLocationLibrary() async {
    try {
      final library = await _locationLibraryStore.load();
      if (mounted) setState(() => _locationLibrary = library);
    } catch (_) {
      _showLocationStorageFailure();
    }
  }

  Future<void> _rememberLocation(Location location) async {
    await _locationLibraryReady;
    final updated = _locationLibrary.remember(location);
    if (mounted) setState(() => _locationLibrary = updated);
    try {
      await _locationLibraryStore.save(updated);
    } catch (_) {
      _showLocationStorageFailure();
    }
  }

  void _showLocationStorageFailure() {
    if (!mounted || _locationStorageFailureShown) return;
    _locationStorageFailureShown = true;
    _showMessage(AppStrings.of(context).placesStorageFailed);
  }

  void _clearHourlyForecasts() {
    _hourlyRequestGeneration += 1;
    _hourlyForecasts = const [];
    _hourlyForecastsLoading = false;
    _hourlyForecastsError = null;
    _hourlyForecastId = null;
  }

  Future<void> _toggleIdeas(
    DailyForecast forecast, {
    RecommendationFilters initialFilters = const RecommendationFilters(),
  }) async {
    if (_expandedForecastId == forecast.id) {
      setState(() {
        _expandedForecastId = null;
        _clearHourlyForecasts();
      });
      final result = _result;
      if (result != null && result.forecasts.isNotEmpty) {
        unawaited(_loadRecommendationPreview(result, result.forecasts.first));
      }
      return;
    }

    setState(() {
      _recommendationPreviewGeneration += 1;
      _expandedForecastId = forecast.id;
      _recommendationFilters = initialFilters;
      _recommendations = const [];
      _clearEventDays();
      _recommendationPreview = null;
      _recommendationPreviewForecastId = forecast.id;
      _recommendationPreviewLoading = true;
      _showtimes = const [];
      _showtimesError = null;
      _showtimesForecastId = null;
      _clearHourlyForecasts();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_scrollToPlanningContext(forecast));
    });
    unawaited(_loadHourlyForecasts(forecast));
    await _loadRecommendations(forecast, filters: initialFilters);
  }

  void _clearEventDays() {
    _eventDaysRequestGeneration += 1;
    _eventDays = const [];
    _eventDaysLoading = false;
    _eventDaysError = null;
  }

  Future<void> _scrollToPlanningContext(
    DailyForecast forecast, {
    int attempt = 0,
  }) async {
    if (!mounted || _expandedForecastId != forecast.id) return;
    final targetContext = forecast.advisories.isNotEmpty
        ? _advisoryKey.currentContext
        : _hourlyKey.currentContext ?? _recommendationsKey.currentContext;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: .04,
      );
      return;
    }

    final trendContext = _trendKey.currentContext;
    if (attempt >= 2 || trendContext == null) return;
    await Scrollable.ensureVisible(
      trendContext,
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: 1,
    );
    if (!mounted || _expandedForecastId != forecast.id) return;
    await Future<void>.delayed(Duration.zero);
    return _scrollToPlanningContext(forecast, attempt: attempt + 1);
  }

  Future<void> _loadHourlyForecasts(
    DailyForecast forecast, {
    bool force = false,
  }) async {
    if (!force && _hourlyForecastId == forecast.id) return;
    final requestGeneration = ++_hourlyRequestGeneration;
    setState(() {
      _hourlyForecastId = forecast.id;
      _hourlyForecastsLoading = true;
      _hourlyForecastsError = null;
    });
    try {
      final result = _result;
      if (result == null) return;
      final hours = await widget.repository.hourlyForecast(
        location: result.location,
        forecast: forecast,
      );
      if (mounted &&
          _expandedForecastId == forecast.id &&
          requestGeneration == _hourlyRequestGeneration) {
        setState(() => _hourlyForecasts = hours);
      }
    } catch (_) {
      if (mounted &&
          _expandedForecastId == forecast.id &&
          requestGeneration == _hourlyRequestGeneration) {
        setState(() =>
            _hourlyForecastsError = AppStrings.of(context).hourlyLoadFailed);
      }
    } finally {
      if (mounted &&
          _expandedForecastId == forecast.id &&
          requestGeneration == _hourlyRequestGeneration) {
        setState(() => _hourlyForecastsLoading = false);
      }
    }
  }

  Future<void> _loadRecommendationPreview(
    ForecastResult result,
    DailyForecast forecast,
  ) async {
    final generation = ++_recommendationPreviewGeneration;
    setState(() {
      _recommendationPreview = null;
      _recommendationPreviewForecastId = forecast.id;
      _recommendationPreviewLoading = true;
    });
    try {
      await _itineraryReady;
      _rememberSavedMoviesForContext(result.location, forecast);
      final recommendations = await widget.repository.recommendations(
        location: result.location,
        forecast: forecast,
        excludedMovieIds:
            _movieRotationLedger.exclusions(result.location, forecast),
      );
      if (mounted &&
          generation == _recommendationPreviewGeneration &&
          _selectedForecastId == forecast.id) {
        final preview = recommendations.firstOrNull;
        _movieRotationLedger.remember(result.location, forecast, [
          if (preview != null) preview,
        ]);
        setState(() => _recommendationPreview = preview);
      }
    } catch (_) {
      // The weather experience stays useful when optional ideas are offline.
    } finally {
      if (mounted &&
          generation == _recommendationPreviewGeneration &&
          _selectedForecastId == forecast.id) {
        setState(() => _recommendationPreviewLoading = false);
      }
    }
  }

  int? get _selectedForecastId =>
      _expandedForecastId ?? _result?.forecasts.firstOrNull?.id;

  Future<void> _loadRecommendations(
    DailyForecast forecast, {
    RecommendationFilters? filters,
  }) async {
    final result = _result;
    if (result == null) {
      return;
    }
    final nextFilters = filters ?? _recommendationFilters;
    final generation = ++_recommendationsRequestGeneration;
    setState(() {
      _recommendationFilters = nextFilters;
      _recommendationsLoading = true;
      _recommendationsError = null;
      if (nextFilters.type != 'event') _clearEventDays();
      if (nextFilters.type != 'movie') {
        _showtimes = const [];
        _showtimesError = null;
        _showtimesForecastId = null;
      }
    });

    if (nextFilters.type == 'movie') {
      unawaited(_loadShowtimes(forecast));
    }

    try {
      await _itineraryReady;
      _rememberSavedMoviesForContext(result.location, forecast);
      final recommendations = await widget.repository.recommendations(
        location: result.location,
        forecast: forecast,
        filters: nextFilters,
        excludedMovieIds:
            _movieRotationLedger.exclusions(result.location, forecast),
      );
      if (mounted &&
          generation == _recommendationsRequestGeneration &&
          _expandedForecastId == forecast.id &&
          _recommendationFilters == nextFilters) {
        _movieRotationLedger.remember(
          result.location,
          forecast,
          recommendations,
        );
        setState(() {
          _recommendations = recommendations;
          _recommendationPreview = recommendations.firstOrNull;
          _recommendationPreviewForecastId = forecast.id;
        });
        _syncItineraryWithCurrentRecommendations(forecast);
        if (nextFilters.type == 'event' && recommendations.isEmpty) {
          unawaited(_loadEventDays(result, forecast));
        } else if (nextFilters.type == 'event') {
          setState(_clearEventDays);
        }
      }
    } catch (_) {
      if (mounted &&
          generation == _recommendationsRequestGeneration &&
          _expandedForecastId == forecast.id) {
        setState(() =>
            _recommendationsError = AppStrings.of(context).ideasLoadFailed);
      }
    } finally {
      if (mounted &&
          generation == _recommendationsRequestGeneration &&
          _expandedForecastId == forecast.id) {
        setState(() {
          _recommendationsLoading = false;
          _recommendationPreviewLoading = false;
        });
      }
    }
  }

  Future<void> _loadEventDays(
    ForecastResult result,
    DailyForecast selectedForecast,
  ) async {
    final repository = widget.repository;
    if (repository is! EventCalendarRepository || result.forecasts.isEmpty) {
      return;
    }
    final eventRepository = repository as EventCalendarRepository;
    final generation = ++_eventDaysRequestGeneration;
    setState(() {
      _eventDays = const [];
      _eventDaysLoading = true;
      _eventDaysError = null;
    });
    try {
      final days = await eventRepository.eventDays(
        location: result.location,
        startDate: result.forecasts.first.date,
        endDate: result.forecasts.last.date,
      );
      if (!mounted ||
          generation != _eventDaysRequestGeneration ||
          _expandedForecastId != selectedForecast.id ||
          _recommendationFilters.type != 'event') {
        return;
      }
      setState(() {
        _eventDays = days
            .where((day) => !_sameDate(day.date, selectedForecast.date))
            .take(4)
            .toList(growable: false);
      });
    } catch (_) {
      if (!mounted || generation != _eventDaysRequestGeneration) return;
      setState(
          () => _eventDaysError = AppStrings.of(context).eventDaysUnavailable);
    } finally {
      if (mounted && generation == _eventDaysRequestGeneration) {
        setState(() => _eventDaysLoading = false);
      }
    }
  }

  Future<void> _openEventDay(EventDaySummary day) async {
    final forecast = _result?.forecasts
        .where((item) => _sameDate(item.date, day.date))
        .firstOrNull;
    if (forecast == null) return;
    await _toggleIdeas(
      forecast,
      initialFilters: const RecommendationFilters(type: 'event'),
    );
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  Future<void> _loadShowtimes(
    DailyForecast forecast, {
    bool force = false,
  }) async {
    final result = _result;
    if (result == null || (!force && _showtimesForecastId == forecast.id)) {
      return;
    }
    setState(() {
      _showtimesForecastId = forecast.id;
      _showtimesLoading = true;
      _showtimesError = null;
    });
    try {
      final showtimes = await widget.repository.showtimes(
        location: result.location,
        forecast: forecast,
      );
      if (mounted && _expandedForecastId == forecast.id) {
        setState(() => _showtimes = showtimes);
      }
    } catch (_) {
      if (mounted && _expandedForecastId == forecast.id) {
        setState(
            () => _showtimesError = AppStrings.of(context).showtimesLoadFailed);
      }
    } finally {
      if (mounted && _expandedForecastId == forecast.id) {
        setState(() => _showtimesLoading = false);
      }
    }
  }

  Future<void> _openShowtime(
    DailyForecast forecast,
    CinemaShowtime showtime,
  ) async {
    setState(() => _bookingShowtimeId = showtime.id);
    try {
      final uri = await widget.repository.showtimeBookingLink(
        forecast: forecast,
        showtime: showtime,
      );
      final opened = uri != null && await widget.showtimeLinkLauncher(uri);
      if (!opened && mounted) {
        _showMessage(AppStrings.of(context).bookingUnavailable);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(AppStrings.of(context).bookingOpenFailed);
      }
    } finally {
      if (mounted) setState(() => _bookingShowtimeId = null);
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openTripPlanner() async {
    final result = _result;
    final repository = widget.tripRepository;
    if (result == null || repository == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TripPlannerScreen(
          location: result.location,
          repository: repository,
        ),
      ),
    );
  }

  Future<void> _openAccount() async {
    final controller = widget.sessionController;
    final repository = widget.tripRepository;
    if (controller == null || repository is! PersonalTripRepository) return;
    final personalRepository = repository as PersonalTripRepository;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AccountScreen(
          sessionController: controller,
          tripRepository: personalRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final selectedForecast = result == null || result.forecasts.isEmpty
        ? null
        : result.forecasts.firstWhere(
            (forecast) => forecast.id == _expandedForecastId,
            orElse: () => result.forecasts.first,
          );
    final expanded =
        selectedForecast != null && _expandedForecastId == selectedForecast.id;
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      body: CustomScrollView(
        // Keep the selected day's first planning section mounted so the hero
        // action can scroll to it even after the overview chart adds height.
        scrollCacheExtent: const ScrollCacheExtent.pixels(4000),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                WeatherHero(
                  controller: _controller,
                  loading: _loading,
                  onSearch: _chooseLocation,
                  onSearchQueryChanged: _onLocationQueryChanged,
                  locationSuggestions: _locationSuggestions,
                  locationSuggestionsLoading: _locationSuggestionsLoading,
                  locationSuggestionsActive: _locationSuggestionsActive,
                  locationSuggestionsError: _locationSuggestionsError,
                  onLocationSuggestionSelected: _selectLocationSuggestion,
                  onLocationSuggestionsRetry: _retryLocationSuggestions,
                  onLocationSuggestionsDismissed: _dismissLocationSuggestions,
                  result: result,
                  forecast: selectedForecast,
                  recommendationPreview:
                      _recommendationPreviewForecastId == selectedForecast?.id
                          ? _recommendationPreview
                          : null,
                  recommendationPreviewLoading:
                      _recommendationPreviewForecastId ==
                              selectedForecast?.id &&
                          _recommendationPreviewLoading,
                  onRecommendationPreviewPressed: selectedForecast == null ||
                          _recommendationPreview == null ||
                          _recommendationPreviewForecastId !=
                              selectedForecast.id
                      ? null
                      : () => _openRecommendation(
                            selectedForecast,
                            _recommendationPreview!,
                          ),
                  ideasExpanded: expanded,
                  onIdeasPressed: selectedForecast == null
                      ? null
                      : () => _toggleIdeas(selectedForecast),
                  onPlacesPressed: _showLocationLibrary,
                  onNotificationsPressed:
                      result == null ? null : _showAdvisoryNotificationSettings,
                  notificationsEnabled: result != null &&
                      _advisoryNotificationPreferences.follows(result.location),
                  notificationsSupported:
                      _advisoryNotificationScheduler.isSupported,
                  currentLocationSaved: result != null &&
                      _locationLibrary.isSaved(result.location),
                  onToggleSaved: result == null
                      ? null
                      : () => _toggleCurrentSaved(result.location),
                  refreshing: _refreshing,
                  onRefresh:
                      result == null || _loading ? null : _refreshForecast,
                  onLocaleChanged: widget.onLocaleChanged,
                  onAccountPressed:
                      widget.sessionController == null ? null : _openAccount,
                  accountLabel: widget.sessionController?.authenticated == true
                      ? widget.sessionController!.user!.greetingName
                      : null,
                  onPlanTripPressed:
                      result == null || widget.tripRepository == null
                          ? null
                          : _openTripPlanner,
                ),
                if (result != null && selectedForecast != null) ...[
                  _contentWidth(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.of(context).chooseDay,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Georgia',
                                    letterSpacing: -.4,
                                  ),
                            ),
                          ),
                          if (!result.isDemo && result.sourceLabel != null)
                            Text(
                              result.sourceLabel!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                  _contentWidth(
                    ForecastRail(
                      forecasts: result.forecasts,
                      selectedId: selectedForecast.id,
                      onSelected: _toggleIdeas,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            ),
          if (result != null && selectedForecast != null) ...[
            SliverToBoxAdapter(
              child: _contentWidth(
                Padding(
                  key: _trendKey,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AtlasColors.paper,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x105E6D65),
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                      child: ForecastTrendChart(
                        forecasts: result.forecasts,
                        selectedId: selectedForecast.id,
                        onSelected: _toggleIdeas,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (selectedForecast.advisories.isNotEmpty)
              SliverToBoxAdapter(
                child: _contentWidth(
                  Padding(
                    key: _advisoryKey,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                    child: ForecastAdvisoryPanel(
                      advisories: selectedForecast.advisories,
                    ),
                  ),
                ),
              ),
            if (expanded)
              SliverToBoxAdapter(
                child: _contentWidth(
                  Padding(
                    key: _hourlyKey,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: HourlyForecastSection(
                      hours: _hourlyForecasts,
                      loading: _hourlyForecastsLoading,
                      error: _hourlyForecastsError,
                      onRetry: () =>
                          _loadHourlyForecasts(selectedForecast, force: true),
                    ),
                  ),
                ),
              ),
            if (expanded)
              SliverToBoxAdapter(
                child: _contentWidth(
                  Padding(
                    key: _recommendationsKey,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Builder(
                      builder: (context) {
                        final itineraryKey = _itineraryKey(selectedForecast);
                        final itinerary =
                            _itineraries[itineraryKey]?.values.toList() ??
                                const [];
                        final effectiveItinerary =
                            _itineraryWithCurrentMetadata(itinerary);
                        return RecommendationPanel(
                          hourlyForecasts: _hourlyForecasts,
                          recommendations: _recommendations,
                          eventDays: _eventDays,
                          eventDaysLoading: _eventDaysLoading,
                          eventDaysError: _eventDaysError,
                          loading: _recommendationsLoading,
                          error: _recommendationsError,
                          filters: _recommendationFilters,
                          showtimes: _showtimes,
                          showtimesLoading: _showtimesLoading,
                          showtimesError: _showtimesError,
                          bookingShowtimeId: _bookingShowtimeId,
                          itinerary: effectiveItinerary,
                          onTypeChanged: (type) => _loadRecommendations(
                            selectedForecast,
                            filters: _recommendationFilters.forType(type),
                          ),
                          onTunePressed: () =>
                              _showRecommendationFilters(selectedForecast),
                          onClearFilters: () => _loadRecommendations(
                            selectedForecast,
                            filters: RecommendationFilters(
                              type: _recommendationFilters.type,
                            ),
                          ),
                          onRetry: () => _loadRecommendations(
                            selectedForecast,
                            filters: _recommendationFilters,
                          ),
                          onShowtimesRetry: () =>
                              _loadShowtimes(selectedForecast, force: true),
                          onShowtimePressed: (showtime) =>
                              _openShowtime(selectedForecast, showtime),
                          onAddRecommendationToPlan: (item) =>
                              _addRecommendationToPlan(selectedForecast, item),
                          onAddShowtimeToPlan: (showtime) =>
                              _addShowtimeToPlan(selectedForecast, showtime),
                          onRemoveFromPlan: (period) =>
                              _removeFromPlan(selectedForecast, period),
                          onClearPlan: () => _clearPlan(selectedForecast),
                          onCopyPlan: () =>
                              _copyPlan(selectedForecast, effectiveItinerary),
                          onCalendarPlan: () => _openPlanInCalendar(
                              selectedForecast, effectiveItinerary),
                          onRoutePlan:
                              _itineraryRouteLink.build(effectiveItinerary) ==
                                      null
                                  ? null
                                  : () => _openPlanRoute(effectiveItinerary),
                          onSuggestPlan: () =>
                              _suggestDayPlan(selectedForecast),
                          onAdaptPlan: () => _adaptDayPlan(selectedForecast),
                          adaptingPlan:
                              _adaptingForecastId == selectedForecast.id,
                          onRecommendationPressed: (item) =>
                              _openRecommendation(selectedForecast, item),
                          onEventDayPressed: _openEventDay,
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _addRecommendationToPlan(
    DailyForecast forecast,
    PlanRecommendation recommendation,
  ) {
    final occupiedPeriods =
        _itineraries[_itineraryKey(forecast)]?.keys.toSet() ?? <String>{};
    final period = _recommendationPeriod(
      recommendation,
      occupiedPeriods: occupiedPeriods,
    );
    _putInPlan(
      forecast,
      _itineraryItemForRecommendation(recommendation, period),
    );
  }

  List<ItineraryItem> _itineraryWithCurrentMetadata(
    List<ItineraryItem> itinerary,
  ) {
    final recommendationsByKey = {
      for (final recommendation in _recommendations)
        _dayPlanBuilder.sourceKey(recommendation): recommendation,
    };
    return itinerary.map((item) {
      final recommendation = recommendationsByKey[item.sourceKey];
      if (recommendation == null) {
        return item;
      }
      return ItineraryItem(
        sourceKey: item.sourceKey,
        sourceType: item.sourceType,
        title: recommendation.title,
        subtitle: _recommendationSubtitle(recommendation),
        period: item.period,
        startTime: item.startTime,
        latitude: item.latitude ?? recommendation.latitude,
        longitude: item.longitude ?? recommendation.longitude,
        indoor: item.indoor ?? recommendation.indoor,
        recommendedPeriods: item.recommendedPeriods.isNotEmpty
            ? item.recommendedPeriods
            : recommendation.recommendedPeriods,
      );
    }).toList(growable: false);
  }

  ItineraryItem _itineraryItemForRecommendation(
    PlanRecommendation recommendation,
    String period,
  ) {
    return ItineraryItem(
      sourceKey: _dayPlanBuilder.sourceKey(recommendation),
      sourceType: recommendation.type,
      title: recommendation.title,
      subtitle: _recommendationSubtitle(recommendation),
      period: period,
      startTime: recommendation.eventTime == null
          ? null
          : _shortTime(recommendation.eventTime!),
      latitude: recommendation.latitude,
      longitude: recommendation.longitude,
      indoor: recommendation.indoor,
      recommendedPeriods: recommendation.recommendedPeriods,
    );
  }

  String _recommendationSubtitle(PlanRecommendation recommendation) {
    final details = [
      if (recommendation.venueName != null &&
          recommendation.venueName != recommendation.title)
        recommendation.venueName!,
      if (recommendation.eventTime != null)
        _shortTime(recommendation.eventTime!),
      if ((recommendation.venueName == null ||
              recommendation.venueName == recommendation.title) &&
          recommendation.eventTime == null)
        switch (recommendation.type) {
          'movie' => AppStrings.of(context).localMovieIdea,
          'event' => AppStrings.of(context).localEvent,
          _ => AppStrings.of(context).localActivity,
        },
    ];
    return details.join(' · ');
  }

  void _syncItineraryWithCurrentRecommendations(DailyForecast forecast) {
    final key = _itineraryKey(forecast);
    final current = _itineraries[key];
    if (current == null || current.isEmpty) return;
    final hydrated = {
      for (final item in _itineraryWithCurrentMetadata(current.values.toList()))
        item.period: item,
    };
    final changed = hydrated.entries.any(
      (entry) => !_sameItineraryItem(current[entry.key], entry.value),
    );
    if (!changed) return;
    setState(() => _itineraries[key] = hydrated);
    unawaited(_persistItineraries());
  }

  bool _sameItineraryItem(ItineraryItem? left, ItineraryItem right) {
    if (left == null ||
        left.sourceKey != right.sourceKey ||
        left.sourceType != right.sourceType ||
        left.title != right.title ||
        left.subtitle != right.subtitle ||
        left.period != right.period ||
        left.startTime != right.startTime ||
        left.latitude != right.latitude ||
        left.longitude != right.longitude ||
        left.indoor != right.indoor ||
        left.recommendedPeriods.length != right.recommendedPeriods.length) {
      return false;
    }
    for (var index = 0; index < left.recommendedPeriods.length; index += 1) {
      if (left.recommendedPeriods[index] != right.recommendedPeriods[index]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _adaptDayPlan(DailyForecast forecast) async {
    if (_adaptingForecastId != null) return;
    final key = _itineraryKey(forecast);
    final current = Map<String, ItineraryItem>.from(
      _itineraries[key] ?? const {},
    );
    final effective = _itineraryWithCurrentMetadata(current.values.toList());
    final weather = _itineraryWeatherPlanner.build(
      hours: _hourlyForecasts,
      items: effective,
    );
    final risky =
        _adaptiveDayPlan.riskyPeriods(items: effective, weather: weather);
    if (risky.isEmpty) return;

    final relocations = _adaptiveDayPlan.relocations(
      items: effective,
      weather: weather,
      riskyPeriods: risky,
    );
    final remainingRisky = risky.difference(relocations.keys.toSet());
    if (remainingRisky.isEmpty) {
      _applyPlanAdaptation(
        key: key,
        current: current,
        relocations: relocations,
        replacements: const {},
        message:
            AppStrings.of(context).adaptedDayPlanResult(relocations.length, 0),
      );
      return;
    }

    final result = _result;
    if (result == null) return;
    setState(() => _adaptingForecastId = forecast.id);

    var alternatives = <PlanRecommendation>[
      for (final recommendation in _recommendations)
        if (recommendation.indoor) recommendation,
    ];
    try {
      await _itineraryReady;
      _rememberSavedMoviesForContext(result.location, forecast);
      final fetched = await widget.repository.recommendations(
        location: result.location,
        forecast: forecast,
        filters: const RecommendationFilters(setting: 'indoor'),
        excludedMovieIds:
            _movieRotationLedger.exclusions(result.location, forecast),
      );
      if (!mounted || _expandedForecastId != forecast.id) return;
      final byKey = <String, PlanRecommendation>{
        for (final recommendation in alternatives)
          _dayPlanBuilder.sourceKey(recommendation): recommendation,
        for (final recommendation in fetched)
          _dayPlanBuilder.sourceKey(recommendation): recommendation,
      };
      alternatives = byKey.values.toList(growable: false);
    } catch (_) {
      if (!mounted || _expandedForecastId != forecast.id) return;
      if (alternatives.isEmpty) {
        if (relocations.isEmpty) {
          _showMessage(AppStrings.of(context).indoorAlternativesLoadFailed);
        } else {
          _applyPlanAdaptation(
            key: key,
            current: current,
            relocations: relocations,
            replacements: const {},
            message: AppStrings.of(context).partiallyAdaptedDayPlan(
              relocations.length,
              0,
              remainingRisky.length,
            ),
          );
        }
        return;
      }
    } finally {
      if (mounted && _adaptingForecastId == forecast.id) {
        setState(() => _adaptingForecastId = null);
      }
    }

    final replacements = _adaptiveDayPlan.replacements(
      recommendations: alternatives,
      items: effective,
      riskyPeriods: remainingRisky,
    );
    _movieRotationLedger.remember(
      result.location,
      forecast,
      replacements.values,
    );
    if (replacements.isEmpty && relocations.isEmpty) {
      _showMessage(AppStrings.of(context).noIndoorAlternatives);
      return;
    }
    final unresolved = remainingRisky.length - replacements.length;
    final strings = AppStrings.of(context);
    _applyPlanAdaptation(
      key: key,
      current: current,
      relocations: relocations,
      replacements: replacements,
      message: unresolved == 0
          ? strings.adaptedDayPlanResult(
              relocations.length,
              replacements.length,
            )
          : strings.partiallyAdaptedDayPlan(
              relocations.length,
              replacements.length,
              unresolved,
            ),
    );
  }

  void _applyPlanAdaptation({
    required String key,
    required Map<String, ItineraryItem> current,
    required Map<String, String> relocations,
    required Map<String, PlanRecommendation> replacements,
    required String message,
  }) {
    final previous = Map<String, ItineraryItem>.from(current);
    for (final entry in relocations.entries) {
      final item = current.remove(entry.key);
      if (item == null) continue;
      current[entry.value] = ItineraryItem(
        sourceKey: item.sourceKey,
        sourceType: item.sourceType,
        title: item.title,
        subtitle: item.subtitle,
        period: entry.value,
        startTime: item.startTime,
        latitude: item.latitude,
        longitude: item.longitude,
        indoor: item.indoor,
        recommendedPeriods: item.recommendedPeriods,
      );
    }
    for (final entry in replacements.entries) {
      current[entry.key] =
          _itineraryItemForRecommendation(entry.value, entry.key);
    }
    setState(() => _itineraries[key] = current);
    unawaited(_persistItineraries());
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: AppStrings.of(context).undo,
          onPressed: () {
            if (!identical(_itineraries[key], current)) return;
            final restored = Map<String, ItineraryItem>.from(previous);
            setState(() => _itineraries[key] = restored);
            unawaited(_persistItineraries());
          },
        ),
      ),
    );
  }

  void _suggestDayPlan(DailyForecast forecast) {
    final key = _itineraryKey(forecast);
    final current = Map<String, ItineraryItem>.from(
      _itineraries[key] ?? const {},
    );
    final suggestions = _dayPlanBuilder.build(
      recommendations: _recommendations,
      occupiedPeriods: current.keys.toSet(),
      usedSourceKeys: current.values.map((item) => item.sourceKey).toSet(),
    );
    if (suggestions.isEmpty) {
      _showMessage(AppStrings.of(context).noIdeasForPlan);
      return;
    }

    for (final entry in suggestions.entries) {
      current[entry.key] =
          _itineraryItemForRecommendation(entry.value, entry.key);
    }
    setState(() => _itineraries[key] = current);
    unawaited(_persistItineraries());
    _showMessage(AppStrings.of(context).suggestedPlan(suggestions.length));
  }

  void _addShowtimeToPlan(
    DailyForecast forecast,
    CinemaShowtime showtime,
  ) {
    _putInPlan(
      forecast,
      ItineraryItem(
        sourceKey: 'showtime:${showtime.id}',
        sourceType: 'showtime',
        title: showtime.filmTitle,
        subtitle: '${showtime.cinemaName} · ${showtime.startTime}',
        period: _periodForTime(showtime.startTime),
        startTime: showtime.startTime,
        indoor: true,
      ),
    );
  }

  void _putInPlan(DailyForecast forecast, ItineraryItem item) {
    final key = _itineraryKey(forecast);
    final current = Map<String, ItineraryItem>.from(
      _itineraries[key] ?? const {},
    );
    final previous = current[item.period];
    if (previous?.sourceKey == item.sourceKey) {
      _showMessage(AppStrings.of(context).periodAlreadyHasIdea(item.period));
      return;
    }

    current[item.period] = item;
    setState(() => _itineraries[key] = current);
    unawaited(_persistItineraries());
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          previous == null
              ? AppStrings.of(context).addedToPeriod(item.period)
              : AppStrings.of(context).periodPlanUpdated(item.period),
        ),
        action: previous == null
            ? null
            : SnackBarAction(
                label: AppStrings.of(context).undo,
                onPressed: () {
                  final restored = Map<String, ItineraryItem>.from(
                    _itineraries[key] ?? const {},
                  );
                  if (restored[item.period]?.sourceKey == item.sourceKey) {
                    restored[item.period] = previous;
                    setState(() => _itineraries[key] = restored);
                    unawaited(_persistItineraries());
                  }
                },
              ),
      ),
    );
  }

  void _removeFromPlan(DailyForecast forecast, String period) {
    final key = _itineraryKey(forecast);
    final current = Map<String, ItineraryItem>.from(
      _itineraries[key] ?? const {},
    )..remove(period);
    setState(() => _itineraries[key] = current);
    unawaited(_persistItineraries());
  }

  void _clearPlan(DailyForecast forecast) {
    setState(() => _itineraries.remove(_itineraryKey(forecast)));
    unawaited(_persistItineraries());
    _showMessage(AppStrings.of(context).dayPlanCleared);
  }

  Future<void> _restoreItineraries() async {
    try {
      final restored = await _itineraryStore.load();
      if (!mounted) return;
      _movieRotationLedger.seedSeenIds(
        restored.values
            .expand((periods) => periods.values)
            .map(_storedMovieId)
            .whereType<int>(),
      );
      setState(() {
        for (final entry in restored.entries) {
          _itineraries.putIfAbsent(entry.key, () => entry.value);
        }
      });
    } catch (_) {
      _showStorageFailure();
    }
  }

  void _rememberSavedMoviesForContext(
    Location location,
    DailyForecast forecast,
  ) {
    final items = _itineraries[_itineraryKey(forecast)]?.values ?? const [];
    _movieRotationLedger.rememberIds(
      location,
      forecast,
      items.map(_storedMovieId).whereType<int>(),
    );
  }

  int? _storedMovieId(ItineraryItem item) {
    if (item.sourceType != 'movie' || !item.sourceKey.startsWith('movie:')) {
      return null;
    }
    return int.tryParse(item.sourceKey.split(':').last);
  }

  Future<void> _persistItineraries() async {
    try {
      await _itineraryStore.save(_itineraries);
    } catch (_) {
      _showStorageFailure();
    }
  }

  Future<void> _restorePreferenceProfiles() async {
    try {
      await _loadPreferenceProfiles();
    } catch (_) {
      if (mounted) {
        _showMessage(AppStrings.of(context).profilesCouldNotLoad);
      }
    }
  }

  Future<List<PreferenceProfile>> _loadPreferenceProfiles() async {
    final profiles = await _preferenceProfileStore.load();
    if (mounted) setState(() => _preferenceProfiles = profiles);
    return profiles;
  }

  Future<List<PreferenceProfile>> _savePreferenceProfile(
    String name,
    RecommendationFilters filters,
  ) async {
    if (_preferenceProfiles.length >= 12) {
      throw const FormatException('Profile limit reached.');
    }
    final profile = PreferenceProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      filters: filters,
    );
    final profiles = [..._preferenceProfiles, profile];
    await _preferenceProfileStore.save(profiles);
    if (mounted) setState(() => _preferenceProfiles = profiles);
    return profiles;
  }

  Future<List<PreferenceProfile>> _deletePreferenceProfile(String id) async {
    final profiles = _preferenceProfiles
        .where((profile) => profile.id != id)
        .toList(growable: false);
    await _preferenceProfileStore.save(profiles);
    if (mounted) setState(() => _preferenceProfiles = profiles);
    return profiles;
  }

  void _showStorageFailure() {
    if (!mounted || _storageFailureShown) return;
    _storageFailureShown = true;
    _showMessage(AppStrings.of(context).plansSaveFailed);
  }

  Future<void> _copyPlan(
    DailyForecast forecast,
    List<ItineraryItem> itinerary,
  ) async {
    final result = _result;
    if (result == null || itinerary.isEmpty) return;
    try {
      await widget.planClipboardWriter(
        _planSummary(result, forecast, itinerary),
      );
      if (mounted) _showMessage(AppStrings.of(context).dayPlanCopied);
    } catch (_) {
      if (mounted) _showMessage(AppStrings.of(context).dayPlanCopyFailed);
    }
  }

  Future<void> _openPlanInCalendar(
    DailyForecast forecast,
    List<ItineraryItem> itinerary,
  ) async {
    final result = _result;
    if (result == null || itinerary.isEmpty) return;
    final uri = _calendarPlanLink.build(
      date: forecast.date,
      title: AppStrings.of(context).dayPlanTitle(result.location.name),
      details: _planSummary(result, forecast, itinerary),
      location: result.location.displayName,
      timezone: result.location.timezone,
    );
    try {
      final opened = await widget.planCalendarLauncher(uri);
      if (!mounted) return;
      _showMessage(
        opened
            ? AppStrings.of(context).calendarPlanOpened
            : AppStrings.of(context).calendarPlanOpenFailed,
      );
    } catch (_) {
      if (mounted) {
        _showMessage(AppStrings.of(context).calendarPlanOpenFailed);
      }
    }
  }

  Future<void> _openPlanRoute(List<ItineraryItem> itinerary) async {
    final uri = _itineraryRouteLink.build(itinerary);
    if (uri == null) return;
    try {
      final opened = await widget.planRouteLauncher(uri);
      if (!opened && mounted) {
        _showMessage(AppStrings.of(context).dayRouteOpenFailed);
      }
    } catch (_) {
      if (mounted) _showMessage(AppStrings.of(context).dayRouteOpenFailed);
    }
  }

  String _planSummary(
    ForecastResult result,
    DailyForecast forecast,
    List<ItineraryItem> itinerary,
  ) {
    const periods = ['morning', 'afternoon', 'evening'];
    final byPeriod = {for (final item in itinerary) item.period: item};
    final date = forecast.date;
    final strings = AppStrings.of(context);
    final lines = [
      strings.dayPlanTitle(result.location.name),
      strings.dayLabel(date),
      '${strings.weatherLabel(forecast.label)} · ${forecast.minC.toStringAsFixed(0)}–${forecast.maxC.toStringAsFixed(0)}°C',
      '',
      for (final period in periods)
        if (byPeriod[period] case final item?)
          '${strings.filterValue(period)} — ${item.title} · ${item.subtitle}',
    ];
    return lines.join('\n');
  }

  String _itineraryKey(DailyForecast forecast) {
    final locationId = _result?.location.id ?? 0;
    final date = forecast.date;
    return '$locationId:${date.year}-${date.month}-${date.day}';
  }

  String _recommendationPeriod(
    PlanRecommendation recommendation, {
    Set<String> occupiedPeriods = const {},
  }) {
    if (recommendation.eventTime != null) {
      return _periodForTime(recommendation.eventTime!);
    }
    if (_recommendationFilters.timeOfDay != null) {
      return _recommendationFilters.timeOfDay!;
    }
    if (recommendation.recommendedPeriods.isNotEmpty) {
      return recommendation.recommendedPeriods.firstWhere(
        (period) => !occupiedPeriods.contains(period),
        orElse: () => recommendation.recommendedPeriods.first,
      );
    }
    return recommendation.type == 'movie' ? 'evening' : 'afternoon';
  }

  String _periodForTime(String value) {
    final hour = int.tryParse(value.split(':').first) ?? 12;
    if (hour >= 3 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    return 'evening';
  }

  String _shortTime(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;

  void _openRecommendation(
    DailyForecast forecast,
    PlanRecommendation recommendation,
  ) {
    final result = _result;
    if (result == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecommendationDetailScreen(
          recommendation: recommendation,
          forecast: forecast,
          location: result.location,
          availabilityChecker: (period) =>
              widget.repository.activityAvailability(
            forecast: forecast,
            recommendation: recommendation,
            period: period,
          ),
        ),
      ),
    );
  }

  Future<void> _showRecommendationFilters(DailyForecast forecast) async {
    final filters = await showModalBottomSheet<RecommendationFilters>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => RecommendationFilterSheet(
        initialFilters: _recommendationFilters,
        initialProfiles: _preferenceProfiles,
        onLoadProfiles: _loadPreferenceProfiles,
        onSaveProfile: _savePreferenceProfile,
        onDeleteProfile: _deletePreferenceProfile,
      ),
    );
    if (filters != null && mounted) {
      await _loadRecommendations(forecast, filters: filters);
    }
  }

  Widget _contentWidth(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

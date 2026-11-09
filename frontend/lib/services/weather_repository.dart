import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/activity_availability.dart';
import '../models/daily_forecast.dart';
import '../models/cinema_showtime.dart';
import '../models/event_day_summary.dart';
import '../models/forecast_result.dart';
import '../models/hourly_forecast.dart';
import '../models/location.dart';
import '../models/location_search_page.dart';
import '../models/plan_recommendation.dart';
import '../models/recommendation_filters.dart';
import '../models/weather_advisory.dart';

abstract interface class WeatherRepository {
  Future<ForecastResult> search(String query);

  Future<LocationSearchPage> searchLocations(
    String query, {
    int page = 1,
    int perPage = 5,
  });

  Future<ForecastResult> forecastFor(
    Location location, {
    bool refresh = false,
  });

  Future<List<HourlyForecast>> hourlyForecast({
    required Location location,
    required DailyForecast forecast,
  });

  Future<List<PlanRecommendation>> recommendations({
    required Location location,
    required DailyForecast forecast,
    RecommendationFilters filters = const RecommendationFilters(),
    Set<int> excludedMovieIds = const {},
  });

  Future<List<CinemaShowtime>> showtimes({
    required Location location,
    required DailyForecast forecast,
  });

  Future<ActivityAvailability> activityAvailability({
    required DailyForecast forecast,
    required PlanRecommendation recommendation,
    required String period,
  });

  Future<Uri?> showtimeBookingLink({
    required DailyForecast forecast,
    required CinemaShowtime showtime,
  });
}

abstract interface class EventCalendarRepository {
  Future<List<EventDaySummary>> eventDays({
    required Location location,
    required DateTime startDate,
    required DateTime endDate,
  });
}

class ApiWeatherRepository
    implements WeatherRepository, EventCalendarRepository {
  ApiWeatherRepository({
    http.Client? client,
    this.languageCode = 'en',
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String languageCode;

  @override
  Future<ForecastResult> search(String query) async {
    final results = await searchLocations(query, perPage: 1);
    if (results.locations.isEmpty) {
      throw const WeatherRepositoryException('No locations found.');
    }
    return forecastFor(results.locations.first);
  }

  @override
  Future<LocationSearchPage> searchLocations(
    String query, {
    int page = 1,
    int perPage = 5,
  }) async {
    final locationUri = Uri.parse('$baseUrl/api/v1/locations/search').replace(
      queryParameters: {
        'q': query,
        'page': '$page',
        'per_page': '$perPage',
        'language': languageCode,
      },
    );
    final locationResponse = await _client.get(
      locationUri,
      headers: {'Accept-Language': languageCode},
    );
    _ensureSuccess(locationResponse);
    final body = jsonDecode(locationResponse.body) as Map<String, dynamic>;
    final locations = (body['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(Location.fromJson)
        .toList();
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    return LocationSearchPage(
      locations: locations,
      page: (meta['page'] as num?)?.toInt() ?? page,
      perPage: (meta['per_page'] as num?)?.toInt() ?? perPage,
      hasMore: meta['has_more'] as bool? ?? false,
    );
  }

  @override
  Future<ForecastResult> forecastFor(
    Location location, {
    bool refresh = false,
  }) async {
    final forecastUri = Uri.parse(
      '$baseUrl/api/v1/locations/${location.id}/forecasts',
    ).replace(queryParameters: {
      'days': '14',
      if (refresh) 'refresh': 'true',
      '_request': DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
    });
    final forecastResponse = await _client.get(forecastUri);
    _ensureSuccess(forecastResponse);
    final forecastBody =
        jsonDecode(forecastResponse.body) as Map<String, dynamic>;
    final data = forecastBody['data'] as Map<String, dynamic>;
    final meta = forecastBody['meta'] as Map<String, dynamic>;
    final resolvedLocation = data['location'] is Map<String, dynamic>
        ? Location.fromJson(data['location'] as Map<String, dynamic>)
        : location;
    final attribution = meta['attribution'] as Map<String, dynamic>?;
    final forecasts = (data['forecasts'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DailyForecast.fromJson)
        .toList();

    return ForecastResult(
      location: resolvedLocation,
      forecasts: forecasts,
      sourceLabel: attribution?['label'] as String?,
      sourceUrl: attribution?['url'] as String?,
      updatedAt:
          DateTime.tryParse(meta['forecast_updated_at'] as String? ?? ''),
    );
  }

  @override
  Future<List<HourlyForecast>> hourlyForecast({
    required Location location,
    required DailyForecast forecast,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/forecasts/${forecast.id}/hourly');
    final response = await _client.get(uri);
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return (data['hours'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(HourlyForecast.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<PlanRecommendation>> recommendations({
    required Location location,
    required DailyForecast forecast,
    RecommendationFilters filters = const RecommendationFilters(),
    Set<int> excludedMovieIds = const {},
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/forecasts/${forecast.id}/recommendations',
    ).replace(
      queryParameters: {
        if (filters.type != null) 'type': filters.type!,
        if (filters.genre != null) 'genre': filters.genre!,
        if (filters.activityKind != null)
          'activity_kind': filters.activityKind!,
        if (filters.setting != null) 'setting': filters.setting!,
        if (filters.maxDistanceKm != null)
          'max_distance_km': filters.maxDistanceKm!.toStringAsFixed(1),
        if (filters.timeOfDay != null) 'time_of_day': filters.timeOfDay!,
        if (excludedMovieIds.isNotEmpty)
          'exclude_movie_ids': (excludedMovieIds.toList()..sort()).join(','),
        'language': languageCode,
      },
    );
    final response = await _client.get(
      uri,
      headers: {'Accept-Language': languageCode},
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body)['data'] as Map<String, dynamic>;
    return (data['recommendations'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(PlanRecommendation.fromJson)
        .toList();
  }

  @override
  Future<List<EventDaySummary>> eventDays({
    required Location location,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/locations/${location.id}/event_days',
    ).replace(queryParameters: {
      'start_date': _dateKey(startDate),
      'end_date': _dateKey(endDate),
      'language': languageCode,
    });
    final response = await _client.get(
      uri,
      headers: {'Accept-Language': languageCode},
    );
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(EventDaySummary.fromJson)
        .toList(growable: false);
  }

  String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Future<List<CinemaShowtime>> showtimes({
    required Location location,
    required DailyForecast forecast,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/forecasts/${forecast.id}/showtimes',
    );
    final response = await _client.get(uri);
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    final meta = body['meta'] as Map<String, dynamic>;
    final attribution = meta['attribution'] as Map<String, dynamic>?;
    return (data['showtimes'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(
          (item) => CinemaShowtime.fromJson(
            item,
            attributionLabel: attribution?['label'] as String?,
            attributionUrl: attribution?['url'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<ActivityAvailability> activityAvailability({
    required DailyForecast forecast,
    required PlanRecommendation recommendation,
    required String period,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/forecasts/${forecast.id}/recommendations/${recommendation.id}/availability',
    ).replace(queryParameters: {'period': period});
    final response = await _client.get(uri);
    _ensureSuccess(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final meta = body['meta'] as Map<String, dynamic>?;
    return ActivityAvailability.fromJson(
      body['data'] as Map<String, dynamic>,
      attribution: meta?['attribution'] as Map<String, dynamic>?,
    );
  }

  @override
  Future<Uri?> showtimeBookingLink({
    required DailyForecast forecast,
    required CinemaShowtime showtime,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/api/v1/forecasts/${forecast.id}/showtimes/booking_link',
    ).replace(
      queryParameters: {
        'film_id': showtime.filmId,
        'cinema_id': showtime.cinemaId,
        'time': showtime.startTime,
      },
    );
    final response = await _client.get(uri);
    _ensureSuccess(response);
    final url = jsonDecode(response.body)['data']['url'] as String?;
    return url == null ? null : Uri.tryParse(url);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WeatherRepositoryException(
          'Weather service returned ${response.statusCode}.');
    }
  }
}

class ResilientWeatherRepository
    implements WeatherRepository, EventCalendarRepository {
  ResilientWeatherRepository({ApiWeatherRepository? api})
      : _api = api ?? ApiWeatherRepository();

  final ApiWeatherRepository _api;

  @override
  Future<ForecastResult> search(String query) async {
    try {
      return await _api.search(query);
    } catch (_) {
      // MVP fallback keeps the UI explorable before local API setup.
      if (_matchesIasi(query)) return DemoWeatherRepository().search(query);
      rethrow;
    }
  }

  @override
  Future<LocationSearchPage> searchLocations(
    String query, {
    int page = 1,
    int perPage = 5,
  }) async {
    try {
      return await _api.searchLocations(
        query,
        page: page,
        perPage: perPage,
      );
    } catch (_) {
      if (_matchesIasi(query)) {
        return DemoWeatherRepository().searchLocations(
          query,
          page: page,
          perPage: perPage,
        );
      }
      rethrow;
    }
  }

  @override
  Future<ForecastResult> forecastFor(
    Location location, {
    bool refresh = false,
  }) async {
    try {
      return await _api.forecastFor(location, refresh: refresh);
    } catch (_) {
      if (refresh) rethrow;
      if (_matchesIasi(location.name)) {
        return DemoWeatherRepository().forecastFor(location);
      }
      rethrow;
    }
  }

  @override
  Future<List<HourlyForecast>> hourlyForecast({
    required Location location,
    required DailyForecast forecast,
  }) async {
    try {
      return await _api.hourlyForecast(location: location, forecast: forecast);
    } catch (_) {
      if (_matchesIasi(location.name)) {
        return DemoWeatherRepository().hourlyForecast(
          location: location,
          forecast: forecast,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<PlanRecommendation>> recommendations({
    required Location location,
    required DailyForecast forecast,
    RecommendationFilters filters = const RecommendationFilters(),
    Set<int> excludedMovieIds = const {},
  }) async {
    try {
      return await _api.recommendations(
        location: location,
        forecast: forecast,
        filters: filters,
        excludedMovieIds: excludedMovieIds,
      );
    } catch (_) {
      if (_matchesIasi(location.name)) {
        return DemoWeatherRepository().recommendations(
          location: location,
          forecast: forecast,
          filters: filters,
          excludedMovieIds: excludedMovieIds,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<EventDaySummary>> eventDays({
    required Location location,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _api.eventDays(
        location: location,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (_) {
      if (_matchesIasi(location.name)) return const [];
      rethrow;
    }
  }

  @override
  Future<List<CinemaShowtime>> showtimes({
    required Location location,
    required DailyForecast forecast,
  }) async {
    try {
      return await _api.showtimes(location: location, forecast: forecast);
    } catch (_) {
      if (_matchesIasi(location.name)) return const [];
      rethrow;
    }
  }

  @override
  Future<ActivityAvailability> activityAvailability({
    required DailyForecast forecast,
    required PlanRecommendation recommendation,
    required String period,
  }) async {
    try {
      return await _api.activityAvailability(
        forecast: forecast,
        recommendation: recommendation,
        period: period,
      );
    } catch (_) {
      if (recommendation.provider == 'seed') {
        return DemoWeatherRepository().activityAvailability(
          forecast: forecast,
          recommendation: recommendation,
          period: period,
        );
      }
      return ActivityAvailability(
        status: 'provider_unavailable',
        label: 'Live hours could not be checked',
        detail: 'Check your connection and try again before visiting.',
        period: period,
        placeName: recommendation.venueName ?? recommendation.title,
        placeUrl: Uri.tryParse(recommendation.url ?? ''),
      );
    }
  }

  @override
  Future<Uri?> showtimeBookingLink({
    required DailyForecast forecast,
    required CinemaShowtime showtime,
  }) =>
      _api.showtimeBookingLink(forecast: forecast, showtime: showtime);

  bool _matchesIasi(String query) {
    final normalized = query.toLowerCase().replaceAll('ș', 's');
    return normalized.contains('iasi');
  }
}

class DemoWeatherRepository implements WeatherRepository {
  static const _iasi = Location(
    id: 1,
    name: 'Iași',
    displayName: 'Iași, Iași County, Romania',
    countryCode: 'RO',
    countryName: 'Romania',
    adminArea: 'Iași County',
    featureCode: 'PPLA',
    population: 378954,
    latitude: 47.1585,
    longitude: 27.6014,
    timezone: 'Europe/Bucharest',
  );

  @override
  Future<ForecastResult> search(String query) async {
    return forecastFor(_iasi);
  }

  @override
  Future<LocationSearchPage> searchLocations(
    String query, {
    int page = 1,
    int perPage = 5,
  }) async {
    final normalized = query.toLowerCase().replaceAll('ș', 's');
    final matches = normalized.contains('iasi') ||
        normalized.contains('jassy') ||
        normalized.contains('700000');
    return LocationSearchPage(
      locations: matches && page == 1 ? const [_iasi] : const [],
      page: page,
      perPage: perPage,
      hasMore: false,
    );
  }

  @override
  Future<ForecastResult> forecastFor(
    Location location, {
    bool refresh = false,
  }) async {
    const pattern = [
      ('Cloudy', 'cloudy', 'flexible', 11.0, 21.0, 10, 8.0),
      ('Rain', 'rain', 'indoor', 9.0, 15.0, 80, 14.0),
      ('Cloudy', 'cloudy', 'flexible', 10.0, 17.0, 35, 10.0),
      ('Clear', 'clear', 'outdoor', 12.0, 23.0, 5, 6.0),
      ('Rain', 'rain', 'indoor', 8.0, 16.0, 60, 18.0),
      ('Cloudy', 'cloudy', 'flexible', 10.0, 19.0, 20, 9.0),
      ('Clear', 'clear', 'outdoor', 13.0, 24.0, 5, 7.0),
    ];
    final today = DateTime.now();
    final forecasts = List.generate(14, (index) {
      final item = pattern[index % pattern.length];
      final date = DateTime(today.year, today.month, today.day + index);
      return DailyForecast(
        id: index + 1,
        date: date,
        label: item.$1,
        weatherClass: item.$2,
        activityContext: item.$3,
        minC: item.$4,
        maxC: item.$5,
        rainProbability: item.$6,
        windSpeedKph: item.$7,
        uvIndexMax: [4.2, 2.1, 3.4, 5.8, 2.8, 4.6, 8.6][index % pattern.length],
        sunriseLocal: '${_dateKey(date)}T07:15',
        sunsetLocal: '${_dateKey(date)}T18:45',
        daylightDurationSeconds: 41400,
        advisories: switch (index % pattern.length) {
          1 => const [
              WeatherAdvisory(
                code: 'rain',
                severity: 'moderate',
                title: 'A wet part of the day',
                message:
                    'Keep an indoor alternative ready and check the hourly forecast before leaving.',
              ),
            ],
          6 => const [
              WeatherAdvisory(
                code: 'very_high_uv',
                severity: 'moderate',
                title: 'Very high UV',
                message:
                    'Favor shade around midday and use sun protection for exposed plans.',
              ),
            ],
          _ => const [],
        },
      );
    });
    return ForecastResult(
      location: location,
      forecasts: forecasts,
      isDemo: true,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Future<List<HourlyForecast>> hourlyForecast({
    required Location location,
    required DailyForecast forecast,
  }) async {
    final rainFirst =
        forecast.weatherClass == 'rain' || forecast.rainProbability >= 50;
    return List.generate(24, (hour) {
      final rainy = rainFirst && hour >= 7 && hour <= 12;
      final daylight = hour >= 7 && hour <= 19;
      final clearWindow = daylight && !rainy && hour >= 14;
      return HourlyForecast(
        time: DateTime(
          forecast.date.year,
          forecast.date.month,
          forecast.date.day,
          hour,
        ),
        label: rainy ? 'Rain' : (clearWindow ? 'Mainly clear' : 'Cloudy'),
        weatherClass: rainy ? 'rain' : (clearWindow ? 'clear' : 'cloudy'),
        activityContext:
            rainy ? 'indoor' : (clearWindow ? 'outdoor' : 'flexible'),
        temperatureC: forecast.minC +
            (forecast.maxC - forecast.minC) *
                (1 - ((hour - 15).abs() / 15).clamp(0, 1)),
        rainProbability: rainy ? 80 : (clearWindow ? 10 : 30),
        windSpeedKph: forecast.windSpeedKph,
        daylight: daylight,
      );
    });
  }

  @override
  Future<List<PlanRecommendation>> recommendations({
    required Location location,
    required DailyForecast forecast,
    RecommendationFilters filters = const RecommendationFilters(),
    Set<int> excludedMovieIds = const {},
  }) async {
    const catalog = [
      PlanRecommendation(
        id: 1,
        type: 'activity',
        title: 'Explore the Palace of Culture',
        summary:
            'Spend a few hours among Iași’s history, art, and science collections.',
        venueName: 'Palace of Culture',
        indoor: true,
        genres: [],
        tags: ['museum', 'culture'],
        score: 85,
        reason: 'A sheltered choice for rainy conditions',
        provider: 'seed',
        latitude: 47.1573073,
        longitude: 27.5862609,
        url: 'https://www.openstreetmap.org/relation/399268',
      ),
      PlanRecommendation(
        id: 2,
        type: 'activity',
        title: 'Walk through Copou Park',
        summary: 'Follow the shaded paths and visit the historic linden tree.',
        venueName: 'Copou Park',
        indoor: false,
        genres: [],
        tags: ['park', 'walk'],
        score: 85,
        reason: 'Makes the most of the clear outdoor window',
        provider: 'seed',
        latitude: 47.1788875,
        longitude: 27.5668015,
        url: 'https://www.openstreetmap.org/way/61750051',
      ),
      PlanRecommendation(
        id: 5,
        type: 'activity',
        title: 'Visit the Botanical Garden',
        summary:
            'Explore glasshouses, seasonal collections, and quiet garden paths.',
        venueName: 'Anastasie Fătu Botanical Garden',
        indoor: false,
        genres: [],
        tags: ['nature', 'garden', 'walk'],
        score: 82,
        reason: 'A colorful outdoor plan for a mild, mostly dry day',
        provider: 'seed',
        latitude: 47.1873,
        longitude: 27.5557,
        url: 'https://www.openstreetmap.org/way/35603778',
      ),
      PlanRecommendation(
        id: 3,
        type: 'movie',
        title: 'Knives Out',
        summary: 'A playful modern mystery for a rainy evening.',
        indoor: true,
        genres: ['mystery', 'comedy'],
        tags: ['cozy'],
        score: 70,
        reason: 'A sheltered choice for rainy conditions',
        provider: 'seed',
        url: 'https://www.themoviedb.org/movie/546554',
      ),
      PlanRecommendation(
        id: 4,
        type: 'movie',
        title: 'Paddington 2',
        summary: 'A warm family comedy for an easy indoor plan.',
        indoor: true,
        genres: ['family', 'comedy'],
        tags: ['uplifting'],
        score: 70,
        reason: 'A flexible match for this forecast',
        provider: 'seed',
        url: 'https://www.themoviedb.org/movie/346648',
      ),
    ];

    return catalog.where((item) {
      final distance = _distanceFor(item, location);
      final matchesType = filters.type == null || item.type == filters.type;
      final unseenMovie =
          item.type != 'movie' || !excludedMovieIds.contains(item.id);
      final matchesGenre = filters.genre == null ||
          item.type != 'movie' ||
          item.genres
              .map(_normalizeGenre)
              .contains(_normalizeGenre(filters.genre!));
      final matchesSetting = filters.setting == null ||
          (filters.setting == 'indoor' ? item.indoor : !item.indoor);
      final matchesActivityKind = filters.activityKind == null ||
          item.type != 'activity' ||
          _matchesActivityKind(item.tags, filters.activityKind!);
      final matchesDistance = filters.maxDistanceKm == null ||
          item.type != 'activity' ||
          (distance != null && distance <= filters.maxDistanceKm!);
      final matchesTime = filters.timeOfDay == null ||
          _recommendedPeriods(item).contains(filters.timeOfDay);
      return matchesType &&
          unseenMovie &&
          matchesGenre &&
          matchesSetting &&
          matchesActivityKind &&
          matchesDistance &&
          matchesTime;
    }).map((item) {
      final distance = _distanceFor(item, location);
      return PlanRecommendation(
        id: item.id,
        type: item.type,
        title: item.title,
        summary: item.summary,
        venueName: item.venueName,
        indoor: item.indoor,
        genres: item.genres,
        tags: item.tags,
        url: item.url,
        provider: item.provider,
        distanceKm: distance,
        latitude: item.latitude,
        longitude: item.longitude,
        imageUrl: item.imageUrl,
        openingHours: item.openingHours,
        rating: item.rating,
        releaseDate: item.releaseDate,
        attributionLabel: item.attributionLabel,
        attributionUrl: item.attributionUrl,
        attributionNotice: item.attributionNotice,
        recommendedPeriods: _recommendedPeriods(item),
        availability: filters.timeOfDay == null || item.type != 'activity'
            ? null
            : AvailabilityGuidance(
                status:
                    item.openingHours == null ? 'not_listed' : 'check_required',
                label: item.openingHours == null
                    ? 'Hours are not listed for this place'
                    : 'Check the listed hours for the ${filters.timeOfDay}',
                period: filters.timeOfDay!,
                disclaimer:
                    'Provider-listed hours can change. Verify before visiting.',
              ),
        score: item.score,
        reason: _demoReason(item, forecast, filters, distance),
        planningNotes: _demoPlanningNotes(item, forecast),
      );
    }).toList();
  }

  @override
  Future<List<CinemaShowtime>> showtimes({
    required Location location,
    required DailyForecast forecast,
  }) async =>
      const [];

  @override
  Future<ActivityAvailability> activityAvailability({
    required DailyForecast forecast,
    required PlanRecommendation recommendation,
    required String period,
  }) async =>
      ActivityAvailability(
        status: 'not_configured',
        label: 'Live hours are not available in demo mode',
        detail:
            'Use the listed hours and confirm with the venue before visiting.',
        period: period,
        placeName: recommendation.venueName ?? recommendation.title,
        placeUrl: Uri.tryParse(recommendation.url ?? ''),
      );

  @override
  Future<Uri?> showtimeBookingLink({
    required DailyForecast forecast,
    required CinemaShowtime showtime,
  }) async =>
      null;

  List<String> _recommendedPeriods(PlanRecommendation item) {
    if (item.type == 'movie') return const ['evening'];
    if (item.tags.any(
      (tag) => const ['cinema', 'theatre', 'entertainment'].contains(tag),
    )) {
      return const ['afternoon', 'evening'];
    }
    return const ['morning', 'afternoon'];
  }

  bool _matchesActivityKind(List<String> tags, String activityKind) {
    const styles = {
      'culture': {'culture', 'museum', 'history', 'art', 'gallery'},
      'nature': {'nature', 'park', 'garden', 'walk', 'hiking', 'photography'},
      'entertainment': {
        'entertainment',
        'cinema',
        'bowling',
        'escape_room',
        'theatre',
      },
    };
    return tags.any((tag) => styles[activityKind]!.contains(tag.toLowerCase()));
  }

  double? _distanceFor(PlanRecommendation item, Location location) {
    if (item.distanceKm != null) return item.distanceKm;
    if (item.latitude == null || item.longitude == null) return null;

    const earthRadiusKm = 6371.0;
    double radians(double degrees) => degrees * math.pi / 180;
    final latitudeDelta = radians(item.latitude! - location.latitude);
    final longitudeDelta = radians(item.longitude! - location.longitude);
    final a = math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(radians(location.latitude)) *
            math.cos(radians(item.latitude!)) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    final distance = earthRadiusKm *
        2 *
        math.atan2(math.sqrt(a.toDouble()), math.sqrt(1 - a.toDouble()));
    return (distance * 10).round() / 10;
  }

  String _demoReason(
    PlanRecommendation item,
    DailyForecast forecast,
    RecommendationFilters filters,
    double? distance,
  ) {
    if (filters.timeOfDay != null) {
      return 'Fits your ${filters.timeOfDay} plan and this forecast';
    }
    if (filters.genre != null && item.type == 'movie') {
      return 'Matches your ${_titleCase(filters.genre!)} movie mood';
    }
    if (filters.activityKind != null && item.type == 'activity') {
      return 'A ${filters.activityKind} pick suited to this forecast';
    }
    if (filters.setting != null) {
      return 'Matches your ${filters.setting} preference for this day';
    }
    if (filters.maxDistanceKm != null &&
        distance != null &&
        item.type == 'activity') {
      return 'A weather-friendly option ${distance.toStringAsFixed(1)} km away';
    }
    if (item.indoor &&
        (forecast.activityContext == 'indoor' ||
            forecast.activityContext == 'caution')) {
      return 'A sheltered choice for ${forecast.label.toLowerCase()} conditions';
    }
    if (!item.indoor && forecast.activityContext == 'outdoor') {
      return 'Makes the most of the clear outdoor window';
    }
    return 'A flexible match for this forecast';
  }

  List<RecommendationPlanningNote> _demoPlanningNotes(
    PlanRecommendation item,
    DailyForecast forecast,
  ) {
    if (item.indoor || (forecast.uvIndexMax ?? 0) < 8) return const [];

    final uv = forecast.uvIndexMax!;
    return [
      RecommendationPlanningNote(
        code: uv >= 11 ? 'extreme_uv' : 'very_high_uv',
        severity: uv >= 11 ? 'high' : 'moderate',
        message:
            'UV peaks at ${uv.toStringAsFixed(1)}; favor shade around midday and use sun protection.',
      ),
    ];
  }

  String _titleCase(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _normalizeGenre(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class WeatherRepositoryException implements Exception {
  const WeatherRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

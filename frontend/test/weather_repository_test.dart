import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weatherwise/models/cinema_showtime.dart';
import 'package:weatherwise/models/daily_forecast.dart';
import 'package:weatherwise/models/location.dart';
import 'package:weatherwise/models/hourly_forecast.dart';
import 'package:weatherwise/models/recommendation_filters.dart';
import 'package:weatherwise/models/plan_recommendation.dart';
import 'package:weatherwise/services/weather_repository.dart';

void main() {
  test('demo recommendations mirror high-UV outdoor guidance', () async {
    final repository = DemoWeatherRepository();
    final result = await repository.forecastFor(_location);
    final highUvForecast = result.forecasts.firstWhere(
      (forecast) => (forecast.uvIndexMax ?? 0) >= 8,
    );

    final recommendations = await repository.recommendations(
      location: _location,
      forecast: highUvForecast,
    );
    final park = recommendations.firstWhere((item) => !item.indoor);
    final museum = recommendations.firstWhere((item) => item.indoor);

    expect(park.planningNotes.single.code, 'very_high_uv');
    expect(park.planningNotes.single.message, contains('sun protection'));
    expect(museum.planningNotes, isEmpty);
  });

  test('parses provider-neutral hourly weather', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'data': {
            'hours': [
              {
                'time': '2026-10-02T15:00:00+03:00',
                'local_time': '2026-10-02T15:00:00',
                'condition': {
                  'label': 'Mainly clear',
                  'weather_class': 'clear',
                },
                'activity_context': 'outdoor',
                'temperature_c': 20.5,
                'precipitation': {'probability': 10, 'amount_mm': 0},
                'wind_speed_kph': 8,
                'daylight': true,
              },
            ],
          },
          'meta': {'provider': 'open_meteo'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    final hours = await repository.hourlyForecast(
      location: _location,
      forecast: _forecast,
    );

    expect(requestedUri!.path, '/api/v1/forecasts/7/hourly');
    expect(hours.single, isA<HourlyForecast>());
    expect(hours.single.temperatureC, 20.5);
    expect(hours.single.time.hour, 15);
    expect(hours.single.activityContext, 'outdoor');
    expect(hours.single.daylight, isTrue);
  });

  test('parses provider-neutral planning advisories', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'data': {
            'forecasts': [
              {
                'id': 7,
                'date': '2026-10-02',
                'condition': {
                  'label': 'Storm',
                  'weather_class': 'storm',
                },
                'activity_context': 'caution',
                'temperature': {'min_c': 9, 'max_c': 16},
                'precipitation': {'probability': 95, 'amount_mm': 18},
                'wind_speed_kph': 62,
                'uv_index_max': 9.1,
                'daylight': {
                  'sunrise_local': '2026-10-02T07:13',
                  'sunset_local': '2026-10-02T18:49',
                  'duration_seconds': 41760,
                },
                'current': {
                  'observed_at': '2026-10-02T16:15',
                  'condition': {
                    'code': '1',
                    'label': 'Mainly clear',
                    'weather_class': 'clear',
                  },
                  'temperature_c': 19.7,
                  'apparent_temperature_c': 16.3,
                  'precipitation_mm': 0,
                  'wind_speed_kph': 13.7,
                  'daylight': true,
                },
                'advisories': [
                  {
                    'code': 'storm',
                    'severity': 'high',
                    'title': 'Storm risk',
                    'message': 'Prefer sheltered plans.',
                  },
                ],
              },
            ],
          },
          'meta': {
            'attribution': null,
            'forecast_updated_at': '2026-10-02T09:45:00Z',
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    final result = await repository.forecastFor(_location, refresh: true);

    expect(requestedUri!.queryParameters['refresh'], 'true');
    expect(result.forecasts.single.advisories.single.code, 'storm');
    expect(result.forecasts.single.hasHighAdvisory, isTrue);
    expect(result.forecasts.single.advisories.single.title, 'Storm risk');
    expect(result.forecasts.single.uvIndexMax, 9.1);
    expect(result.forecasts.single.daylightRange, '07:13–18:49');
    expect(result.forecasts.single.daylightDurationSeconds, 41760);
    expect(result.forecasts.single.current!.temperatureC, 19.7);
    expect(result.forecasts.single.current!.label, 'Mainly clear');
    expect(result.forecasts.single.current!.apparentTemperatureC, 16.3);
    expect(result.updatedAt, DateTime.utc(2026, 10, 2, 9, 45));
  });

  test('uses location imagery returned with the forecast', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': {
            'location': {
              'id': 1,
              'name': 'Paris',
              'display_name': 'Paris, France',
              'country_code': 'FR',
              'latitude': 48.8566,
              'longitude': 2.3522,
              'timezone': 'Europe/Paris',
              'hero_image_url': 'https://upload.wikimedia.org/paris.jpg',
              'image_attribution':
                  'Photographer · CC BY-SA 4.0 · Wikimedia Commons',
            },
            'forecasts': [],
          },
          'meta': {'attribution': null, 'forecast_updated_at': null},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    final result = await repository.forecastFor(_location);

    expect(result.location.name, 'Paris');
    expect(
        result.location.heroImageUrl, 'https://upload.wikimedia.org/paris.jpg');
    expect(result.location.imageAttribution, contains('Wikimedia Commons'));
  });

  test('parses ranked location pages and search metadata', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 42,
              'name': 'Paris',
              'display_name': 'Paris, Île-de-France, France',
              'country_code': 'FR',
              'country_name': 'France',
              'admin_area': 'Île-de-France',
              'latitude': 48.8566,
              'longitude': 2.3522,
              'timezone': 'Europe/Paris',
              'feature_code': 'PPLC',
              'population': 2138551,
            },
          ],
          'meta': {
            'page': 2,
            'per_page': 5,
            'has_more': true,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
      languageCode: 'ro',
    );

    final result = await repository.searchLocations('Paris', page: 2);

    expect(requestedUri!.queryParameters, {
      'q': 'Paris',
      'page': '2',
      'per_page': '5',
      'language': 'ro',
    });
    expect(result.locations.single.countryName, 'France');
    expect(result.locations.single.adminArea, 'Île-de-France');
    expect(result.locations.single.population, 2138551);
    expect(result.page, 2);
    expect(result.hasMore, isTrue);
  });

  test('sends recommendation preferences to the API', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'data': {'recommendations': <Object>[]},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    await repository.recommendations(
      location: _location,
      forecast: _forecast,
      excludedMovieIds: const {9, 3},
      filters: const RecommendationFilters(
        type: 'activity',
        activityKind: 'culture',
        setting: 'indoor',
        maxDistanceKm: 5,
        timeOfDay: 'afternoon',
      ),
    );

    expect(requestedUri!.path, '/api/v1/forecasts/7/recommendations');
    expect(requestedUri!.queryParameters, {
      'type': 'activity',
      'activity_kind': 'culture',
      'setting': 'indoor',
      'max_distance_km': '5.0',
      'time_of_day': 'afternoon',
      'exclude_movie_ids': '3,9',
      'language': 'en',
    });
  });

  test('parses recommendation imagery and its independent photo credit', () {
    final item = PlanRecommendation.fromJson({
      'id': 12,
      'type': 'activity',
      'title': 'City Museum',
      'summary': 'Local culture',
      'indoor': true,
      'genres': <String>[],
      'tags': <String>['museum'],
      'provider': 'openstreetmap',
      'image_url': 'https://upload.wikimedia.org/museum.jpg',
      'image_attribution': {
        'label': 'Photographer · CC BY-SA 4.0 · Wikimedia Commons',
        'url': 'https://commons.wikimedia.org/wiki/File:Museum.jpg',
      },
      'score': 90,
      'reason': 'Good indoor match',
      'planning_notes': <Object>[],
    });

    expect(item.imageUrl, 'https://upload.wikimedia.org/museum.jpg');
    expect(item.imageAttributionLabel, contains('Wikimedia Commons'));
    expect(item.imageAttributionUrl, contains('commons.wikimedia.org'));
  });

  test('parses mapped hiking metadata and weather sensitivity', () {
    final item = PlanRecommendation.fromJson({
      'id': 13,
      'type': 'activity',
      'title': 'Vârful Toaca',
      'summary': 'Summit hike',
      'indoor': false,
      'genres': <String>[],
      'tags': <String>['nature', 'hiking', 'summit'],
      'provider': 'openstreetmap',
      'activity_kind': 'nature',
      'weather_sensitive': true,
      'elevation_m': 1904,
      'route_distance_km': 8.5,
      'route_start': 'Durău',
      'route_end': 'Vârful Toaca',
      'duration_minutes': 210,
      'ascent_m': 780,
      'descent_m': 120,
      'roundtrip': false,
      'difficulty': 'mountain_hiking',
      'trail_visibility': 'good',
      'surface': 'rock',
      'route_network': 'rwn',
      'route_ref': 'bandă roșie',
      'trail_marker': 'red:white:red_bar',
      'route_operator': 'Salvamont Neamț',
      'official_url': 'https://example.test/toaca',
      'score': 92,
      'reason': 'Dry daylight window',
      'planning_notes': <Object>[],
    });

    expect(item.activityKind, 'nature');
    expect(item.weatherSensitive, isTrue);
    expect(item.elevationM, 1904);
    expect(item.routeDistanceKm, 8.5);
    expect(item.routeStart, 'Durău');
    expect(item.routeEnd, 'Vârful Toaca');
    expect(item.durationMinutes, 210);
    expect(item.ascentM, 780);
    expect(item.descentM, 120);
    expect(item.roundtrip, isFalse);
    expect(item.difficulty, 'mountain_hiking');
    expect(item.trailVisibility, 'good');
    expect(item.surface, 'rock');
    expect(item.routeNetwork, 'rwn');
    expect(item.routeRef, 'bandă roșie');
    expect(item.trailMarker, 'red:white:red_bar');
    expect(item.routeOperator, 'Salvamont Neamț');
    expect(item.officialUrl, 'https://example.test/toaca');
  });

  test('changing result type clears incompatible refinements', () {
    const filters = RecommendationFilters(
      type: 'activity',
      genre: 'mystery',
      activityKind: 'culture',
      setting: 'indoor',
      maxDistanceKm: 5,
      timeOfDay: 'afternoon',
    );

    expect(
      filters.forType('movie'),
      const RecommendationFilters(
        type: 'movie',
        genre: 'mystery',
        timeOfDay: 'afternoon',
      ),
    );
    expect(
      filters.forType('activity'),
      const RecommendationFilters(
        type: 'activity',
        activityKind: 'culture',
        setting: 'indoor',
        maxDistanceKm: 5,
        timeOfDay: 'afternoon',
      ),
    );
  });

  test('parses live cinema showtimes and provider attribution', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({
            'data': {
              'showtimes': [
                {
                  'id': '7:9:19:30:Standard',
                  'film_id': '7',
                  'film_title': 'Rain Story',
                  'cinema_id': '9',
                  'cinema_name': 'Central Cinema',
                  'date': '2026-10-02',
                  'format': 'Standard',
                  'start_time': '19:30',
                  'end_time': '21:40',
                  'distance_km': 3.2,
                  'image_url': 'https://example.test/poster.jpg',
                },
              ],
            },
            'meta': {
              'attribution': {
                'label': 'Cinema and showtime data by MovieGlu',
                'url': 'https://www.movieglu.com',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ));
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    final results = await repository.showtimes(
      location: _location,
      forecast: _forecast,
    );

    expect(results.single.filmTitle, 'Rain Story');
    expect(results.single.cinemaName, 'Central Cinema');
    expect(results.single.distanceKm, 3.2);
    expect(
      results.single.attributionLabel,
      'Cinema and showtime data by MovieGlu',
    );
  });

  test('loads real event days for a fourteen-day location window', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'data': [
            {
              'date': '2026-10-09',
              'count': 3,
              'preview': {
                'title': 'Paris Jazz Evening',
                'venue_name': 'Le Point Virgule',
                'image_url': 'https://example.test/event.jpg',
              },
              'providers': ['ticketmaster'],
            },
          ],
          'meta': {'count': 1},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
      languageCode: 'ro',
    );

    final days = await repository.eventDays(
      location: _location,
      startDate: DateTime(2026, 10, 2),
      endDate: DateTime(2026, 10, 15),
    );

    expect(requestedUri!.path, '/api/v1/locations/2/event_days');
    expect(requestedUri!.queryParameters['start_date'], '2026-10-02');
    expect(requestedUri!.queryParameters['end_date'], '2026-10-15');
    expect(requestedUri!.queryParameters['language'], 'ro');
    expect(days.single.count, 3);
    expect(days.single.previewTitle, 'Paris Jazz Evening');
    expect(days.single.providers, ['ticketmaster']);
  });

  test('requests a booking destination for the selected showtime', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'data': {'url': 'https://cinema.example.test/book'},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
    );
    final showtime = CinemaShowtime(
      id: '7:9:19:30:Standard',
      filmId: '7',
      filmTitle: 'Rain Story',
      cinemaId: '9',
      cinemaName: 'Central Cinema',
      date: _forecast.date,
      format: 'Standard',
      startTime: '19:30',
    );

    final result = await repository.showtimeBookingLink(
      forecast: _forecast,
      showtime: showtime,
    );

    expect(result, Uri.parse('https://cinema.example.test/book'));
    expect(
      requestedUri!.path,
      '/api/v1/forecasts/7/showtimes/booking_link',
    );
    expect(requestedUri!.queryParameters, {
      'film_id': '7',
      'cinema_id': '9',
      'time': '19:30',
    });
  });

  test('parses on-demand activity availability and attribution', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'data': {
            'status': 'verified_open',
            'label': 'Provider lists this place open in the afternoon',
            'detail': 'Checked against current provider hours.',
            'period': 'afternoon',
            'provider': 'google_places',
            'checked_at': '2026-10-01T09:00:00Z',
            'place_name': 'Palace of Culture',
            'place_url': 'https://maps.google.com/example',
          },
          'meta': {
            'attribution': {
              'label': 'Google Maps',
              'url': 'https://maps.google.com',
            },
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiWeatherRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    final result = await repository.activityAvailability(
      forecast: _forecast,
      recommendation: const PlanRecommendation(
        id: 42,
        type: 'activity',
        title: 'Palace of Culture',
        summary: 'Museum',
        indoor: true,
        genres: [],
        tags: ['museum'],
        score: 80,
        reason: 'A sheltered choice',
      ),
      period: 'afternoon',
    );

    expect(
      requestedUri!.path,
      '/api/v1/forecasts/7/recommendations/42/availability',
    );
    expect(requestedUri!.queryParameters['period'], 'afternoon');
    expect(result.isOpen, isTrue);
    expect(result.attributionLabel, 'Google Maps');
  });
}

const _location = Location(
  id: 2,
  name: 'Iași',
  displayName: 'Iași, RO',
  countryCode: 'RO',
  latitude: 47.1585,
  longitude: 27.6014,
  timezone: 'Europe/Bucharest',
);

final _forecast = DailyForecast(
  id: 7,
  date: DateTime(2026, 10, 2),
  label: 'Rain',
  weatherClass: 'rain',
  activityContext: 'indoor',
  minC: 8,
  maxC: 14,
  rainProbability: 80,
  windSpeedKph: 12,
);

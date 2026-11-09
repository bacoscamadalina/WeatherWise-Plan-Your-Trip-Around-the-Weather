import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:weatherwise/models/trip_plan.dart';
import 'package:weatherwise/services/trip_repository.dart';

void main() {
  test('sends edited settings when replanning a personal trip', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'data': {
            'id': 7,
            'name': 'Weekend în Iași',
            'starts_on': '2026-10-08',
            'ends_on': '2026-10-10',
            'arrival_time': '14:30',
            'departure_time': '11:15',
            'party_size': 2,
            'pace': 'relaxed',
            'transport_mode': 'public_transport',
            'max_distance_km': 20,
            'preferences': {
              'budget': 'moderate',
              'dietary': ['vegan'],
              'interests': ['nature'],
            },
            'status': 'planned',
            'location': {
              'id': 1,
              'name': 'Iași',
              'display_name': 'Iași, România',
              'country_code': 'RO',
              'latitude': 47.1585,
              'longitude': 27.6014,
              'timezone': 'Europe/Bucharest',
            },
            'days': [],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiTripRepository(
      client: client,
      baseUrl: 'https://example.test',
      tokenProvider: () => 'session-token',
      languageCode: 'ro',
    );

    final plan = await repository.replanTrip(
      7,
      startsOn: DateTime(2026, 10, 8),
      endsOn: DateTime(2026, 10, 10),
      arrivalTime: '14:30',
      departureTime: '11:15',
      partySize: 2,
      pace: 'relaxed',
      transportMode: 'public_transport',
      maxDistanceKm: 20,
      preferences: const TripPreferences(
        budget: 'moderate',
        dietary: ['vegan'],
        interests: ['nature'],
      ),
    );

    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/v1/trips/7/replan');
    expect(captured!.headers['authorization'], 'Bearer session-token');
    expect(captured!.headers['accept-language'], 'ro');
    final trip = (jsonDecode(captured!.body) as Map<String, dynamic>)['trip']
        as Map<String, dynamic>;
    expect(trip, {
      'starts_on': '2026-10-08',
      'ends_on': '2026-10-10',
      'arrival_time': '14:30',
      'departure_time': '11:15',
      'party_size': 2,
      'pace': 'relaxed',
      'transport_mode': 'public_transport',
      'max_distance_km': 20.0,
      'preferences': {
        'budget': 'moderate',
        'dietary': ['vegan'],
        'interests': ['nature'],
      },
    });
    expect(plan.partySize, 2);
    expect(plan.arrivalTime, '14:30');
    expect(plan.departureTime, '11:15');
    expect(plan.pace, 'relaxed');
    expect(plan.maxDistanceKm, 20);
    expect(plan.preferences.budget, 'moderate');
    expect(plan.preferences.dietary, ['vegan']);
    expect(plan.preferences.interests, ['nature']);
  });

  test('requests a replacement for one itinerary item', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'data': {
            'id': 7,
            'name': 'Weekend în Iași',
            'starts_on': '2026-10-08',
            'ends_on': '2026-10-08',
            'party_size': 1,
            'pace': 'balanced',
            'transport_mode': 'car',
            'max_distance_km': 50,
            'status': 'planned',
            'location': {
              'id': 1,
              'name': 'Iași',
              'display_name': 'Iași, România',
              'country_code': 'RO',
              'latitude': 47.1585,
              'longitude': 27.6014,
              'timezone': 'Europe/Bucharest',
            },
            'days': [],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repository = ApiTripRepository(
      client: client,
      baseUrl: 'https://example.test',
      tokenProvider: () => 'session-token',
      languageCode: 'ro',
    );

    await repository.replaceItem(7, 42);

    expect(captured!.method, 'POST');
    expect(captured!.url.path, '/api/v1/trips/7/replace_item');
    expect(jsonDecode(captured!.body), {'item_id': 42, 'language': 'ro'});
    expect(captured!.headers['authorization'], 'Bearer session-token');
  });

  test('preserves the API error code for replacement recovery copy', () async {
    final client = MockClient((request) async => http.Response(
          jsonEncode({
            'error': {
              'code': 'no_alternative',
              'message': 'No different stop is available',
            },
          }),
          422,
          headers: {'content-type': 'application/json'},
        ));
    final repository = ApiTripRepository(
      client: client,
      baseUrl: 'https://example.test',
    );

    await expectLater(
      repository.replaceItem(7, 42),
      throwsA(
        isA<TripRepositoryException>()
            .having((error) => error.code, 'code', 'no_alternative'),
      ),
    );
  });
}

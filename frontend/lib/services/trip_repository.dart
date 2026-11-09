import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/location.dart';
import '../models/trip_plan.dart';

abstract interface class TripRepository {
  Future<TripPlan> createTrip({
    required Location location,
    required DateTime startsOn,
    required DateTime endsOn,
    required String pace,
    required String transportMode,
    required double maxDistanceKm,
    String? arrivalTime,
    String? departureTime,
    int partySize = 1,
    TripPreferences preferences = const TripPreferences(),
  });
}

abstract interface class PersonalTripRepository {
  Future<List<TripPlan>> listTrips();
  Future<TripPlan> getTrip(int id);
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
  });
  Future<TripPlan> replaceItem(int tripId, int itemId);
  Future<TripPlan> renameTrip(int id, String name);
  Future<void> deleteTrip(int id);
}

class ApiTripRepository implements TripRepository, PersonalTripRepository {
  ApiTripRepository({
    http.Client? client,
    this.languageCode = 'en',
    this.languageCodeProvider,
    this.tokenProvider,
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String languageCode;
  final String Function()? languageCodeProvider;
  final String? Function()? tokenProvider;

  @override
  Future<TripPlan> createTrip({
    required Location location,
    required DateTime startsOn,
    required DateTime endsOn,
    required String pace,
    required String transportMode,
    required double maxDistanceKm,
    String? arrivalTime,
    String? departureTime,
    int partySize = 1,
    TripPreferences preferences = const TripPreferences(),
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/trips'),
      headers: _headers(),
      body: jsonEncode({
        'language': _languageCode,
        'trip': {
          'location_id': location.id,
          'name': _languageCode == 'ro'
              ? 'Călătorie în ${location.name}'
              : 'Trip to ${location.name}',
          'starts_on': _date(startsOn),
          'ends_on': _date(endsOn),
          if (arrivalTime != null) 'arrival_time': arrivalTime,
          if (departureTime != null) 'departure_time': departureTime,
          'party_size': partySize,
          'pace': pace,
          'transport_mode': transportMode,
          'max_distance_km': maxDistanceKm,
          'preferences': preferences.toJson(),
        },
      }),
    );
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'] as Map<String, dynamic>?;
      throw TripRepositoryException(
        error?['message']?.toString() ?? 'Could not create trip.',
        code: error?['code']?.toString(),
      );
    }
    return TripPlan.fromJson(payload['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<TripPlan>> listTrips() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/trips'),
      headers: _headers(),
    );
    final data = _payload(response)['data'] as List<dynamic>? ?? const [];
    return data
        .cast<Map<String, dynamic>>()
        .map(TripPlan.fromJson)
        .toList(growable: false);
  }

  @override
  Future<TripPlan> getTrip(int id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/trips/$id'),
      headers: _headers(),
    );
    return TripPlan.fromJson(
      _payload(response)['data'] as Map<String, dynamic>,
    );
  }

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
    final trip = <String, dynamic>{
      if (startsOn != null) 'starts_on': _date(startsOn),
      if (endsOn != null) 'ends_on': _date(endsOn),
      if (arrivalTime != null) 'arrival_time': arrivalTime,
      if (departureTime != null) 'departure_time': departureTime,
      if (partySize != null) 'party_size': partySize,
      if (pace != null) 'pace': pace,
      if (transportMode != null) 'transport_mode': transportMode,
      if (maxDistanceKm != null) 'max_distance_km': maxDistanceKm,
      if (preferences != null) 'preferences': preferences.toJson(),
    };
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/trips/$id/replan'),
      headers: _headers(),
      body: trip.isEmpty ? null : jsonEncode({'trip': trip}),
    );
    return TripPlan.fromJson(
      _payload(response)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<TripPlan> replaceItem(int tripId, int itemId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/trips/$tripId/replace_item'),
      headers: _headers(),
      body: jsonEncode({'item_id': itemId, 'language': _languageCode}),
    );
    return TripPlan.fromJson(
      _payload(response)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<TripPlan> renameTrip(int id, String name) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/api/v1/trips/$id'),
      headers: _headers(),
      body: jsonEncode({
        'trip': {'name': name}
      }),
    );
    return TripPlan.fromJson(
      _payload(response)['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteTrip(int id) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/v1/trips/$id'),
      headers: _headers(),
    );
    if (response.statusCode != 204) _payload(response);
  }

  Map<String, String> _headers() {
    final token = tokenProvider?.call();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Accept-Language': _languageCode,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String get _languageCode => languageCodeProvider?.call() ?? languageCode;

  Map<String, dynamic> _payload(http.Response response) {
    final payload = response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload['error'] as Map<String, dynamic>?;
      throw TripRepositoryException(
        error?['message']?.toString() ?? 'Trip request failed.',
        code: error?['code']?.toString(),
      );
    }
    return payload;
  }

  String _date(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class TripRepositoryException implements Exception {
  const TripRepositoryException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

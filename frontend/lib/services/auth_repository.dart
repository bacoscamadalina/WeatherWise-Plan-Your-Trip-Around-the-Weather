import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthSession> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? displayName,
  });

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthUser> me(String token);
  Future<void> logout(String token);
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? displayName,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'display_name': displayName,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    return AuthSession.fromJson(_data(response));
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return AuthSession.fromJson(_data(response));
  }

  @override
  Future<AuthUser> me(String token) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/v1/auth/me'),
      headers: _jsonHeaders(token),
    );
    return AuthUser.fromJson(_data(response));
  }

  @override
  Future<void> logout(String token) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/api/v1/auth/logout'),
      headers: _jsonHeaders(token),
    );
    if (response.statusCode != 204 && response.statusCode != 401) {
      _data(response);
    }
  }

  Map<String, String> _jsonHeaders([String? token]) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _data(http.Response response) {
    final payload = response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = (payload['error'] as Map<String, dynamic>?)?['message'];
      throw AuthRepositoryException(
        message?.toString() ?? 'Authentication request failed.',
      );
    }
    return payload['data'] as Map<String, dynamic>;
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

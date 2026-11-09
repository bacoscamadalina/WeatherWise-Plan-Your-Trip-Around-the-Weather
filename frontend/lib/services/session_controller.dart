import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_user.dart';
import 'auth_repository.dart';

abstract interface class SessionTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureSessionTokenStore implements SessionTokenStore {
  SecureSessionTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'weatherwise.session_token.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _tokenKey);
}

class SessionController extends ChangeNotifier {
  SessionController({
    required this.repository,
    required this.tokenStore,
  });

  final AuthRepository repository;
  final SessionTokenStore tokenStore;

  AuthUser? _user;
  String? _token;
  bool _restoring = true;
  bool _busy = false;

  AuthUser? get user => _user;
  String? get token => _token;
  bool get restoring => _restoring;
  bool get busy => _busy;
  bool get authenticated => _user != null && _token != null;

  Future<void> restore() async {
    try {
      final token = await tokenStore.read();
      if (token == null) return;
      _user = await repository.me(token);
      _token = token;
    } catch (_) {
      await tokenStore.clear();
      _user = null;
      _token = null;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _run(() => repository.login(email: email, password: password));
  }

  Future<void> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? displayName,
  }) async {
    await _run(
      () => repository.register(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        displayName: displayName,
      ),
    );
  }

  Future<void> logout() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    final token = _token;
    try {
      if (token != null) await repository.logout(token);
    } finally {
      await tokenStore.clear();
      _user = null;
      _token = null;
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _run(Future<AuthSession> Function() request) async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      final session = await request();
      await tokenStore.write(session.accessToken);
      _user = session.user;
      _token = session.accessToken;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}

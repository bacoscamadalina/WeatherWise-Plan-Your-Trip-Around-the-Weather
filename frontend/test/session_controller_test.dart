import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/auth_user.dart';
import 'package:weatherwise/services/auth_repository.dart';
import 'package:weatherwise/services/session_controller.dart';

void main() {
  test('restores a valid session and clears an invalid token', () async {
    final validStore = _MemoryTokenStore('valid-token');
    final valid = SessionController(
      repository: _FakeAuthRepository(),
      tokenStore: validStore,
    );

    await valid.restore();
    expect(valid.authenticated, isTrue);
    expect(valid.user?.email, 'mara@example.com');

    final invalidStore = _MemoryTokenStore('expired-token');
    final invalid = SessionController(
      repository: _FakeAuthRepository(),
      tokenStore: invalidStore,
    );
    await invalid.restore();
    expect(invalid.authenticated, isFalse);
    expect(invalidStore.token, isNull);
  });

  test('stores login token and clears it on logout', () async {
    final store = _MemoryTokenStore();
    final controller = SessionController(
      repository: _FakeAuthRepository(),
      tokenStore: store,
    );

    await controller.login(
        email: 'mara@example.com', password: 'password-2026');
    expect(controller.authenticated, isTrue);
    expect(store.token, 'valid-token');

    await controller.logout();
    expect(controller.authenticated, isFalse);
    expect(store.token, isNull);
  });
}

class _MemoryTokenStore implements SessionTokenStore {
  _MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

class _FakeAuthRepository implements AuthRepository {
  static const user =
      AuthUser(id: 1, email: 'mara@example.com', displayName: 'Mara');

  @override
  Future<AuthSession> login(
          {required String email, required String password}) async =>
      AuthSession(
        user: user,
        accessToken: 'valid-token',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

  @override
  Future<void> logout(String token) async {}

  @override
  Future<AuthUser> me(String token) async {
    if (token != 'valid-token') throw const AuthRepositoryException('Expired');
    return user;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? displayName,
  }) =>
      login(email: email, password: password);
}

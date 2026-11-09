import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/l10n/app_strings.dart';
import 'package:weatherwise/models/auth_user.dart';
import 'package:weatherwise/models/trip_plan.dart';
import 'package:weatherwise/screens/account_screen.dart';
import 'package:weatherwise/services/auth_repository.dart';
import 'package:weatherwise/services/session_controller.dart';
import 'package:weatherwise/services/trip_repository.dart';
import 'package:weatherwise/theme/atlas_theme.dart';

void main() {
  testWidgets('shows a stable restoration state before authentication resolves',
      (tester) async {
    final controller = SessionController(
      repository: _AccountAuthRepository(),
      tokenStore: _MemoryTokenStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ro'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AtlasTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: AccountScreen(
            sessionController: controller,
            tripRepository: _EmptyTripsRepository(),
          ),
        ),
      ),
    );

    expect(find.text('Pregătim contul tău.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await controller.restore();
    await tester.pumpAndSettle();
    expect(find.text('Intră în cont'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates an account and reveals the personal trip library',
      (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = SessionController(
      repository: _AccountAuthRepository(),
      tokenStore: _MemoryTokenStore(),
    );
    await controller.restore();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ro'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          AppStrings.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AtlasTheme.light(),
        home: AccountScreen(
          sessionController: controller,
          tripRepository: _EmptyTripsRepository(),
        ),
      ),
    );

    await tester.tap(find.text('Cont nou'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Mara');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'mara@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'password-2026');
    await tester.enterText(find.byType(TextFormField).at(3), 'password-2026');
    await tester.ensureVisible(find.text('Creează contul'));
    await tester.tap(find.text('Creează contul'));
    await tester.pumpAndSettle();

    expect(find.text('Bun venit, Mara.'), findsOneWidget);
    expect(find.text('Călătoriile mele'), findsOneWidget);
    expect(controller.authenticated, isTrue);
  });
}

class _MemoryTokenStore implements SessionTokenStore {
  String? token;

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

class _AccountAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String passwordConfirmation,
    String? displayName,
  }) async =>
      AuthSession(
        user: AuthUser(id: 1, email: email, displayName: displayName),
        accessToken: 'account-token',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );

  @override
  Future<AuthSession> login(
          {required String email, required String password}) =>
      register(
        email: email,
        password: password,
        passwordConfirmation: password,
        displayName: 'Mara',
      );

  @override
  Future<void> logout(String token) async {}

  @override
  Future<AuthUser> me(String token) async =>
      const AuthUser(id: 1, email: 'mara@example.com', displayName: 'Mara');
}

class _EmptyTripsRepository implements PersonalTripRepository {
  @override
  Future<void> deleteTrip(int id) async {}

  @override
  Future<TripPlan> getTrip(int id) => throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<TripPlan> replaceItem(int tripId, int itemId) =>
      throw UnimplementedError();

  @override
  Future<List<TripPlan>> listTrips() async => const [];

  @override
  Future<TripPlan> renameTrip(int id, String name) =>
      throw UnimplementedError();
}

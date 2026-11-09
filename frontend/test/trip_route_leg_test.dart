import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/trip_plan.dart';
import 'package:weatherwise/theme/atlas_theme.dart';
import 'package:weatherwise/widgets/trip_route_leg.dart';

void main() {
  testWidgets('shows a live point-to-point route and return leg',
      (tester) async {
    const item = TripPlanItem(
      id: 7,
      slot: 'morning',
      kind: 'activity',
      title: 'Grădina Botanică',
      status: 'suggested',
      metadata: {
        'route_origin_name': 'Palatul Culturii',
        'route_status': 'provider_route',
        'route_duration_minutes': 18,
        'route_distance_km': 6.2,
        'route_transport_mode': 'car',
        'route_departure_at': '09:42',
        'return_destination_name': 'Iași, România',
        'return_route_status': 'provider_route',
        'return_route_duration_minutes': 21,
        'return_route_distance_km': 7.1,
        'return_route_arrival_at': '12:21',
        'return_route_fits_day': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: const Scaffold(body: TripRouteLeg(item: item, romanian: true)),
      ),
    );

    expect(find.byKey(const ValueKey('trip-route-leg-7')), findsOneWidget);
    expect(find.textContaining('Plecare estimată ~09:42 · 18 min cu mașina'),
        findsOneWidget);
    expect(find.textContaining('6,2 km din Palatul Culturii'), findsOneWidget);
    expect(find.textContaining('Întoarcere la Iași, România: 21 min'),
        findsOneWidget);
    expect(find.textContaining('sosire estimată ~12:21'), findsOneWidget);
  });

  testWidgets('does not present a rhythm buffer as a live route',
      (tester) async {
    const item = TripPlanItem(
      id: 8,
      slot: 'morning',
      kind: 'activity',
      title: 'Muzeu',
      status: 'suggested',
      metadata: {
        'route_origin_name': 'Iași',
        'route_status': 'estimated_buffer',
        'route_duration_minutes': 25,
        'route_transport_mode': 'walking',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: const Scaffold(body: TripRouteLeg(item: item, romanian: true)),
      ),
    );

    expect(find.textContaining('~25 min rezervate pe jos'), findsOneWidget);
    expect(find.textContaining('rută calculată indisponibilă'), findsOneWidget);
  });

  testWidgets('labels an estimated return without false precision',
      (tester) async {
    const item = TripPlanItem(
      id: 9,
      slot: 'afternoon',
      kind: 'activity',
      title: 'Parc',
      status: 'suggested',
      metadata: {
        'route_origin_name': 'Muzeu',
        'route_status': 'estimated_buffer',
        'route_duration_minutes': 20,
        'route_transport_mode': 'car',
        'return_destination_name': 'Iași',
        'return_route_status': 'estimated_buffer',
        'return_route_duration_minutes': 20,
        'return_route_arrival_at': '18:20',
        'return_route_fits_day': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: const Scaffold(body: TripRouteLeg(item: item, romanian: true)),
      ),
    );

    expect(
      find.textContaining(
          'Întoarcere la Iași: ~20 min rezervate · sosire estimată ~18:20 · rută calculată indisponibilă'),
      findsOneWidget,
    );
  });

  testWidgets('warns when the return exceeds the selected daily rhythm',
      (tester) async {
    const item = TripPlanItem(
      id: 10,
      slot: 'evening',
      kind: 'activity',
      title: 'Belvedere',
      status: 'suggested',
      metadata: {
        'route_origin_name': 'Centru',
        'route_status': 'provider_route',
        'route_duration_minutes': 25,
        'route_transport_mode': 'car',
        'return_destination_name': 'Iași',
        'return_route_status': 'provider_route',
        'return_route_duration_minutes': 35,
        'return_route_arrival_at': '22:55',
        'return_route_fits_day': false,
        'return_after_day_end_minutes': 25,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: const Scaffold(body: TripRouteLeg(item: item, romanian: true)),
      ),
    );

    expect(
      find.textContaining('depășește programul zilei cu 25 min'),
      findsOneWidget,
    );
    expect(find.textContaining('alege una mai aproape'), findsOneWidget);
  });

  testWidgets('labels an after-midnight return as the next day',
      (tester) async {
    const item = TripPlanItem(
      id: 11,
      slot: 'evening',
      kind: 'activity',
      title: 'Excursie regională',
      status: 'suggested',
      metadata: {
        'route_origin_name': 'Centru',
        'route_status': 'provider_route',
        'route_duration_minutes': 45,
        'route_transport_mode': 'car',
        'return_destination_name': 'Iași',
        'return_route_status': 'provider_route',
        'return_route_duration_minutes': 120,
        'return_route_arrival_at': '00:20',
        'return_route_fits_day': false,
        'return_after_day_end_minutes': 110,
        'return_arrives_next_day': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: const Scaffold(body: TripRouteLeg(item: item, romanian: true)),
      ),
    );

    expect(find.textContaining('~00:20 a doua zi'), findsNWidgets(2));
  });

  testWidgets('keeps a long return warning readable on a narrow scaled screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const item = TripPlanItem(
      id: 12,
      slot: 'evening',
      kind: 'activity',
      title: 'Belvedere îndepărtat',
      status: 'suggested',
      metadata: {
        'route_origin_name': 'Un punct de plecare cu un nume local foarte lung',
        'route_status': 'provider_route',
        'route_duration_minutes': 48,
        'route_transport_mode': 'public_transport',
        'return_destination_name':
            'Localitatea de cazare cu denumire foarte lungă',
        'return_route_status': 'provider_route',
        'return_route_duration_minutes': 120,
        'return_route_arrival_at': '00:20',
        'return_route_fits_day': false,
        'return_after_day_end_minutes': 110,
        'return_arrives_next_day': true,
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: TripRouteLeg(item: item, romanian: true),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('a doua zi'), findsNWidgets(2));
  });
}

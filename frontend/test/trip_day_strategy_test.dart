import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/theme/atlas_theme.dart';
import 'package:weatherwise/widgets/trip_day_strategy.dart';

void main() {
  testWidgets('presents the localized day strategy as one readable explanation',
      (tester) async {
    const summary =
        'Ploaie dimineața; activitățile exterioare rămân pentru după-amiază.';

    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: const Scaffold(
          body: TripDayStrategy(summary: summary, romanian: true),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('trip-day-strategy')), findsOneWidget);
    expect(find.text('Strategia zilei'), findsOneWidget);
    expect(find.text(summary), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('trip-day-strategy'))),
      matchesSemantics(
        label: 'Strategia zilei. $summary',
      ),
    );
  });

  testWidgets('uses the English label when requested', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AtlasTheme.light(),
        home: const Scaffold(
          body: TripDayStrategy(
            summary: 'The dry afternoon window is reserved for outdoors.',
            romanian: false,
          ),
        ),
      ),
    );

    expect(find.text('Day strategy'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/itinerary_item.dart';
import 'package:weatherwise/services/itinerary_store.dart';

void main() {
  test('serializes rapid saves and keeps the newest plan', () async {
    final delegate = _ControlledItineraryStore();
    final store = SerializedItineraryStore(delegate);
    final firstPlan = _plan('Morning walk');

    final firstSave = store.save(firstPlan);
    firstPlan['day']!['morning'] = _item('Changed after save');
    await delegate.firstSaveStarted.future;

    final secondSave = store.save(_plan('Museum visit'));
    await Future<void>.delayed(Duration.zero);
    expect(delegate.saveCalls, 1);

    delegate.releaseFirstSave.complete();
    await Future.wait([firstSave, secondSave]);

    expect(delegate.saveCalls, 2);
    expect(delegate.saved['day']!['morning']!.title, 'Museum visit');
    expect(delegate.firstSavedTitle, 'Morning walk');
  });

  test('continues the save queue after an earlier write fails', () async {
    final delegate = _ControlledItineraryStore(failFirstSave: true);
    final store = SerializedItineraryStore(delegate);

    final firstSave = store.save(_plan('Morning walk'));
    await delegate.firstSaveStarted.future;
    final secondSave = store.save(_plan('Museum visit'));
    delegate.releaseFirstSave.complete();

    await expectLater(firstSave, throwsA(isA<StateError>()));
    await secondSave;

    expect(delegate.saveCalls, 2);
    expect(delegate.saved['day']!['morning']!.title, 'Museum visit');
  });
}

Map<String, Map<String, ItineraryItem>> _plan(String title) => {
      'day': {'morning': _item(title)},
    };

ItineraryItem _item(String title) => ItineraryItem(
      sourceKey: 'activity:test:$title',
      sourceType: 'activity',
      title: title,
      subtitle: 'Local activity',
      period: 'morning',
    );

class _ControlledItineraryStore implements ItineraryStore {
  _ControlledItineraryStore({this.failFirstSave = false});

  final bool failFirstSave;
  final firstSaveStarted = Completer<void>();
  final releaseFirstSave = Completer<void>();
  int saveCalls = 0;
  String? firstSavedTitle;
  Map<String, Map<String, ItineraryItem>> saved = {};

  @override
  Future<Map<String, Map<String, ItineraryItem>>> load() async => saved;

  @override
  Future<void> save(
    Map<String, Map<String, ItineraryItem>> itineraries,
  ) async {
    saveCalls += 1;
    if (saveCalls == 1) {
      firstSavedTitle = itineraries['day']!['morning']!.title;
      firstSaveStarted.complete();
      await releaseFirstSave.future;
      if (failFirstSave) throw StateError('storage unavailable');
    }
    saved = itineraries;
  }
}

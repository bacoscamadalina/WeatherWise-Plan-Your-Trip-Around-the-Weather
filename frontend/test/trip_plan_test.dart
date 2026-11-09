import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/trip_plan.dart';

void main() {
  test('parses the daily logistics truth from the trip payload', () {
    final plan = TripPlan.fromJson({
      'id': 7,
      'name': 'Weekend în Iași',
      'starts_on': '2026-10-08',
      'ends_on': '2026-10-08',
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
      'days': [
        {
          'id': 9,
          'date': '2026-10-08',
          'weather': <String, dynamic>{},
          'items': <Map<String, dynamic>>[],
          'logistics': {
            'planned_stops': 3,
            'located_stops': 3,
            'route_available': true,
            'travel_minutes': 70,
            'distance_km': 23.4,
            'estimated': false,
            'first_departure_at': '09:10',
            'return_arrival_at': '21:40',
            'return_fits_day': true,
          },
        },
      ],
    });

    final logistics = plan.days.single.logistics;
    expect(logistics.plannedStops, 3);
    expect(logistics.travelMinutes, 70);
    expect(logistics.distanceKm, 23.4);
    expect(logistics.estimated, isFalse);
    expect(logistics.returnArrivalAt, '21:40');
    expect(logistics.returnFitsDay, isTrue);
  });
}

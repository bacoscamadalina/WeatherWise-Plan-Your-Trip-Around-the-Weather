import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/itinerary_item.dart';
import 'package:weatherwise/services/itinerary_route_link.dart';

void main() {
  test('orders located stops by day period and builds a walking route', () {
    final uri = const ItineraryRouteLink().build([
      _item('evening', 47.18, 27.58),
      _item('morning', 47.16, 27.60),
      _item('afternoon', 47.17, 27.59),
    ]);

    expect(uri?.host, 'www.google.com');
    expect(uri?.path, '/maps/dir/');
    expect(uri?.queryParameters['origin'], '47.16,27.6');
    expect(uri?.queryParameters['waypoints'], '47.17,27.59');
    expect(uri?.queryParameters['destination'], '47.18,27.58');
    expect(uri?.queryParameters['travelmode'], 'walking');
  });

  test('ignores unlocated ideas and returns null without a real stop', () {
    const movie = ItineraryItem(
      sourceKey: 'movie:1',
      sourceType: 'movie',
      title: 'Arrival',
      subtitle: 'Movie idea',
      period: 'evening',
    );

    expect(const ItineraryRouteLink().build([movie]), isNull);
  });
}

ItineraryItem _item(String period, double latitude, double longitude) =>
    ItineraryItem(
      sourceKey: 'activity:$period',
      sourceType: 'activity',
      title: period,
      subtitle: 'Local activity',
      period: period,
      latitude: latitude,
      longitude: longitude,
    );

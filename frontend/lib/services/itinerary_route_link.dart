import '../models/itinerary_item.dart';

class ItineraryRouteLink {
  const ItineraryRouteLink();

  Uri? build(List<ItineraryItem> items) {
    final stops = items
        .where((item) => item.latitude != null && item.longitude != null)
        .toList(growable: false)
      ..sort(
          (a, b) => _periodOrder(a.period).compareTo(_periodOrder(b.period)));
    if (stops.isEmpty) return null;

    final parameters = <String, String>{
      'api': '1',
      'destination': _coordinates(stops.last),
      'travelmode': 'walking',
    };
    if (stops.length > 1) {
      parameters['origin'] = _coordinates(stops.first);
    }
    if (stops.length > 2) {
      parameters['waypoints'] =
          stops.sublist(1, stops.length - 1).map(_coordinates).join('|');
    }
    return Uri.https('www.google.com', '/maps/dir/', parameters);
  }

  String _coordinates(ItineraryItem item) =>
      '${item.latitude},${item.longitude}';

  int _periodOrder(String period) => switch (period) {
        'morning' => 0,
        'afternoon' => 1,
        _ => 2,
      };
}

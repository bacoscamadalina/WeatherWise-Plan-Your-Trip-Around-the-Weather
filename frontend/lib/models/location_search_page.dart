import 'location.dart';

class LocationSearchPage {
  const LocationSearchPage({
    required this.locations,
    required this.page,
    required this.perPage,
    required this.hasMore,
  });

  final List<Location> locations;
  final int page;
  final int perPage;
  final bool hasMore;
}

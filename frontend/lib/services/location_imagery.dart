import '../models/location.dart';
import '../models/plan_recommendation.dart';

/// Resolves editorial imagery without coupling the UI to a specific provider.
///
/// The backend may supply a licensed `hero_image_url` for any location. The
/// bundled Iași set keeps the laboratory location visually complete offline.
/// A future image provider can populate the same field for global coverage.
class LocationImagery {
  const LocationImagery._();

  static String? heroAsset(Location? location) {
    if (!_isIasi(location)) return null;
    return 'assets/locations/iasi/palace-of-culture-hero.jpg';
  }

  static String? recommendationAsset(PlanRecommendation item) {
    if (item.provider != 'seed') return null;
    final identity = '${item.title} ${item.venueName ?? ''}'.toLowerCase();
    if (identity.contains('botanic')) {
      return 'assets/recommendations/iasi-botanical-garden.jpg';
    }
    if (item.type == 'movie' || identity.contains('cinema')) {
      return 'assets/recommendations/iasi-cinema.jpg';
    }
    if (identity.contains('palace of culture') ||
        identity.contains('palatul culturii')) {
      return 'assets/locations/iasi/palace-of-culture-hero.jpg';
    }
    return null;
  }

  static bool _isIasi(Location? location) {
    if (location == null || location.countryCode.toUpperCase() != 'RO') {
      return false;
    }
    final name =
        location.name.toLowerCase().replaceAll('ș', 's').replaceAll('ş', 's');
    return name == 'iasi';
  }
}

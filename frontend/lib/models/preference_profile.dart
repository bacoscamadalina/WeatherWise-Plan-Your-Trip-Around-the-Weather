import 'recommendation_filters.dart';

class PreferenceProfile {
  const PreferenceProfile({
    required this.id,
    required this.name,
    required this.filters,
  });

  final String id;
  final String name;
  final RecommendationFilters filters;

  factory PreferenceProfile.fromJson(Map<String, dynamic> json) =>
      PreferenceProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        filters: RecommendationFilters.fromJson(
          json['filters'] as Map<String, dynamic>,
        ),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'filters': filters.toJson(),
      };
}

class Location {
  const Location({
    required this.id,
    required this.name,
    required this.displayName,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.countryName,
    this.adminArea,
    this.featureCode,
    this.population,
    this.heroImageUrl,
    this.imageAttribution,
  });

  final int id;
  final String name;
  final String displayName;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String timezone;
  final String? countryName;
  final String? adminArea;
  final String? featureCode;
  final int? population;
  final String? heroImageUrl;
  final String? imageAttribution;

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['id'] as int,
        name: json['name'] as String,
        displayName: json['display_name'] as String,
        countryCode: json['country_code'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone'] as String,
        countryName: json['country_name'] as String?,
        adminArea: json['admin_area'] as String?,
        featureCode: json['feature_code'] as String?,
        population: (json['population'] as num?)?.toInt(),
        heroImageUrl: json['hero_image_url'] as String?,
        imageAttribution: json['image_attribution'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'display_name': displayName,
        'country_code': countryCode,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        if (countryName != null) 'country_name': countryName,
        if (adminArea != null) 'admin_area': adminArea,
        if (featureCode != null) 'feature_code': featureCode,
        if (population != null) 'population': population,
        if (heroImageUrl != null) 'hero_image_url': heroImageUrl,
        if (imageAttribution != null) 'image_attribution': imageAttribution,
      };
}

class ItineraryItem {
  const ItineraryItem({
    required this.sourceKey,
    required this.sourceType,
    required this.title,
    required this.subtitle,
    required this.period,
    this.startTime,
    this.latitude,
    this.longitude,
    this.indoor,
    this.recommendedPeriods = const [],
  });

  final String sourceKey;
  final String sourceType;
  final String title;
  final String subtitle;
  final String period;
  final String? startTime;
  final double? latitude;
  final double? longitude;
  final bool? indoor;
  final List<String> recommendedPeriods;

  factory ItineraryItem.fromJson(Map<String, dynamic> json) {
    return ItineraryItem(
      sourceKey: json['source_key'] as String,
      sourceType: json['source_type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      period: json['period'] as String,
      startTime: json['start_time'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      indoor: json['indoor'] as bool?,
      recommendedPeriods:
          (json['recommended_periods'] as List<dynamic>? ?? const [])
              .cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'source_key': sourceKey,
        'source_type': sourceType,
        'title': title,
        'subtitle': subtitle,
        'period': period,
        if (startTime != null) 'start_time': startTime,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (indoor != null) 'indoor': indoor,
        if (recommendedPeriods.isNotEmpty)
          'recommended_periods': recommendedPeriods,
      };
}

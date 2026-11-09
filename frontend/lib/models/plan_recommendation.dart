class PlanRecommendation {
  const PlanRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.indoor,
    required this.genres,
    required this.tags,
    required this.score,
    required this.reason,
    this.planningNotes = const [],
    this.venueName,
    this.url,
    this.provider,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.openingHours,
    this.activityKind,
    this.weatherSensitive = false,
    this.elevationM,
    this.routeDistanceKm,
    this.routeStart,
    this.routeEnd,
    this.durationMinutes,
    this.ascentM,
    this.descentM,
    this.roundtrip,
    this.difficulty,
    this.trailVisibility,
    this.surface,
    this.routeNetwork,
    this.routeRef,
    this.trailMarker,
    this.routeOperator,
    this.officialUrl,
    this.rating,
    this.releaseDate,
    this.attributionLabel,
    this.attributionUrl,
    this.attributionNotice,
    this.imageAttributionLabel,
    this.imageAttributionUrl,
    this.recommendedPeriods = const [],
    this.availability,
    this.eventDate,
    this.eventTime,
    this.eventTimezone,
    this.eventStatus,
    this.priceLabel,
  });

  final int id;
  final String type;
  final String title;
  final String summary;
  final String? venueName;
  final bool indoor;
  final List<String> genres;
  final List<String> tags;
  final String? url;
  final String? provider;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String? openingHours;
  final String? activityKind;
  final bool weatherSensitive;
  final int? elevationM;
  final double? routeDistanceKm;
  final String? routeStart;
  final String? routeEnd;
  final int? durationMinutes;
  final int? ascentM;
  final int? descentM;
  final bool? roundtrip;
  final String? difficulty;
  final String? trailVisibility;
  final String? surface;
  final String? routeNetwork;
  final String? routeRef;
  final String? trailMarker;
  final String? routeOperator;
  final String? officialUrl;
  final double? rating;
  final DateTime? releaseDate;
  final String? attributionLabel;
  final String? attributionUrl;
  final String? attributionNotice;
  final String? imageAttributionLabel;
  final String? imageAttributionUrl;
  final List<String> recommendedPeriods;
  final AvailabilityGuidance? availability;
  final DateTime? eventDate;
  final String? eventTime;
  final String? eventTimezone;
  final String? eventStatus;
  final String? priceLabel;
  final int score;
  final String reason;
  final List<RecommendationPlanningNote> planningNotes;

  factory PlanRecommendation.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>?;
    return PlanRecommendation(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      venueName: json['venue_name'] as String?,
      indoor: json['indoor'] as bool,
      genres: (json['genres'] as List<dynamic>).cast<String>(),
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      url: json['url'] as String?,
      provider: json['provider'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      latitude: (coordinates?['latitude'] as num?)?.toDouble(),
      longitude: (coordinates?['longitude'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      openingHours: json['opening_hours'] as String?,
      activityKind: json['activity_kind'] as String?,
      weatherSensitive: json['weather_sensitive'] as bool? ?? false,
      elevationM: (json['elevation_m'] as num?)?.round(),
      routeDistanceKm: (json['route_distance_km'] as num?)?.toDouble(),
      routeStart: json['route_start'] as String?,
      routeEnd: json['route_end'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.round(),
      ascentM: (json['ascent_m'] as num?)?.round(),
      descentM: (json['descent_m'] as num?)?.round(),
      roundtrip: json['roundtrip'] as bool?,
      difficulty: json['difficulty'] as String?,
      trailVisibility: json['trail_visibility'] as String?,
      surface: json['surface'] as String?,
      routeNetwork: json['route_network'] as String?,
      routeRef: json['route_ref'] as String?,
      trailMarker: json['trail_marker'] as String?,
      routeOperator: json['route_operator'] as String?,
      officialUrl: json['official_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      releaseDate: json['release_date'] == null
          ? null
          : DateTime.tryParse(json['release_date'] as String),
      attributionLabel:
          (json['attribution'] as Map<String, dynamic>?)?['label'] as String?,
      attributionUrl:
          (json['attribution'] as Map<String, dynamic>?)?['url'] as String?,
      attributionNotice:
          (json['attribution'] as Map<String, dynamic>?)?['notice'] as String?,
      imageAttributionLabel: (json['image_attribution']
          as Map<String, dynamic>?)?['label'] as String?,
      imageAttributionUrl: (json['image_attribution']
          as Map<String, dynamic>?)?['url'] as String?,
      recommendedPeriods:
          (json['recommended_periods'] as List<dynamic>? ?? const [])
              .cast<String>(),
      availability: json['availability'] == null
          ? null
          : AvailabilityGuidance.fromJson(
              json['availability'] as Map<String, dynamic>,
            ),
      eventDate: json['event_date'] == null
          ? null
          : DateTime.tryParse(json['event_date'] as String),
      eventTime: json['event_time'] as String?,
      eventTimezone: json['event_timezone'] as String?,
      eventStatus: json['event_status'] as String?,
      priceLabel: json['price_label'] as String?,
      score: json['score'] as int,
      reason: json['reason'] as String,
      planningNotes: (json['planning_notes'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(RecommendationPlanningNote.fromJson)
          .toList(growable: false),
    );
  }
}

class RecommendationPlanningNote {
  const RecommendationPlanningNote({
    required this.code,
    required this.severity,
    required this.message,
  });

  final String code;
  final String severity;
  final String message;

  factory RecommendationPlanningNote.fromJson(Map<String, dynamic> json) {
    return RecommendationPlanningNote(
      code: json['code'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
    );
  }
}

class AvailabilityGuidance {
  const AvailabilityGuidance({
    required this.status,
    required this.label,
    required this.period,
    required this.disclaimer,
  });

  final String status;
  final String label;
  final String period;
  final String disclaimer;

  factory AvailabilityGuidance.fromJson(Map<String, dynamic> json) {
    return AvailabilityGuidance(
      status: json['status'] as String,
      label: json['label'] as String,
      period: json['period'] as String,
      disclaimer: json['disclaimer'] as String,
    );
  }
}

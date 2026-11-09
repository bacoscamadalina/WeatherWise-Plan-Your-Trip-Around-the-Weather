import 'location.dart';

class TripPreferences {
  const TripPreferences({
    this.budget = 'flexible',
    this.dietary = const [],
    this.interests = const [],
  });

  final String budget;
  final List<String> dietary;
  final List<String> interests;

  bool get isDefault =>
      budget == 'flexible' && dietary.isEmpty && interests.isEmpty;

  Map<String, dynamic> toJson() => {
        'budget': budget,
        'dietary': dietary,
        'interests': interests,
      };

  factory TripPreferences.fromJson(Map<String, dynamic>? json) =>
      TripPreferences(
        budget: json?['budget'] as String? ?? 'flexible',
        dietary:
            List<String>.from(json?['dietary'] as List<dynamic>? ?? const []),
        interests:
            List<String>.from(json?['interests'] as List<dynamic>? ?? const []),
      );
}

class TripPlan {
  const TripPlan({
    required this.id,
    required this.name,
    required this.location,
    required this.startsOn,
    required this.endsOn,
    required this.maxDistanceKm,
    required this.pace,
    required this.transportMode,
    required this.status,
    required this.days,
    this.arrivalTime,
    this.departureTime,
    this.partySize = 1,
    this.preferences = const TripPreferences(),
    this.rhythm = const TripRhythm(),
  });

  final int id;
  final String name;
  final Location location;
  final DateTime startsOn;
  final DateTime endsOn;
  final String? arrivalTime;
  final String? departureTime;
  final double maxDistanceKm;
  final String pace;
  final String transportMode;
  final String status;
  final List<TripPlanDay> days;
  final int partySize;
  final TripPreferences preferences;
  final TripRhythm rhythm;

  factory TripPlan.fromJson(Map<String, dynamic> json) => TripPlan(
        id: json['id'] as int,
        name: json['name'] as String,
        location: Location.fromJson(json['location'] as Map<String, dynamic>),
        startsOn: DateTime.parse(json['starts_on'] as String),
        endsOn: DateTime.parse(json['ends_on'] as String),
        arrivalTime: json['arrival_time'] as String?,
        departureTime: json['departure_time'] as String?,
        maxDistanceKm: (json['max_distance_km'] as num).toDouble(),
        pace: json['pace'] as String,
        transportMode: json['transport_mode'] as String,
        status: json['status'] as String,
        partySize: (json['party_size'] as num?)?.toInt() ?? 1,
        preferences: TripPreferences.fromJson(
          json['preferences'] as Map<String, dynamic>?,
        ),
        rhythm: TripRhythm.fromJson(
          json['rhythm'] as Map<String, dynamic>?,
          fallbackPace: json['pace'] as String? ?? 'balanced',
        ),
        days: (json['days'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(TripPlanDay.fromJson)
            .toList(growable: false),
      );
}

class TripRhythm {
  const TripRhythm({
    this.pace = 'balanced',
    this.label = 'Balanced',
    this.description = '',
    this.dayStart = '08:30',
    this.dayEnd = '22:30',
    this.plannedActivityCount = 3,
    this.travelBufferMinutes = 20,
  });

  final String pace;
  final String label;
  final String description;
  final String dayStart;
  final String dayEnd;
  final int plannedActivityCount;
  final int travelBufferMinutes;

  factory TripRhythm.fromJson(
    Map<String, dynamic>? json, {
    String fallbackPace = 'balanced',
  }) =>
      TripRhythm(
        pace: json?['pace'] as String? ?? fallbackPace,
        label: json?['label'] as String? ?? 'Balanced',
        description: json?['description'] as String? ?? '',
        dayStart: json?['day_start'] as String? ?? '08:30',
        dayEnd: json?['day_end'] as String? ?? '22:30',
        plannedActivityCount:
            (json?['planned_activity_count'] as num?)?.toInt() ?? 3,
        travelBufferMinutes:
            (json?['travel_buffer_minutes'] as num?)?.toInt() ?? 20,
      );
}

class TripPlanDay {
  const TripPlanDay({
    required this.id,
    required this.date,
    required this.weatherClass,
    required this.activityContext,
    required this.summary,
    required this.weather,
    required this.items,
    this.logistics = const TripDayLogistics(),
    this.availableFrom,
    this.availableUntil,
  });

  final int id;
  final DateTime date;
  final String? weatherClass;
  final String? activityContext;
  final String? summary;
  final Map<String, dynamic> weather;
  final List<TripPlanItem> items;
  final TripDayLogistics logistics;
  final String? availableFrom;
  final String? availableUntil;

  factory TripPlanDay.fromJson(Map<String, dynamic> json) => TripPlanDay(
        id: json['id'] as int,
        date: DateTime.parse(json['date'] as String),
        weatherClass: json['weather_class'] as String?,
        activityContext: json['activity_context'] as String?,
        summary: json['summary'] as String?,
        weather: (json['weather'] as Map<String, dynamic>?) ??
            const <String, dynamic>{},
        availableFrom: json['available_from'] as String?,
        availableUntil: json['available_until'] as String?,
        logistics: TripDayLogistics.fromJson(
          json['logistics'] as Map<String, dynamic>?,
        ),
        items: (json['items'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(TripPlanItem.fromJson)
            .toList(growable: false),
      );
}

class TripDayLogistics {
  const TripDayLogistics({
    this.plannedStops = 0,
    this.locatedStops = 0,
    this.routeAvailable = false,
    this.travelMinutes,
    this.distanceKm,
    this.estimated = false,
    this.firstDepartureAt,
    this.returnArrivalAt,
    this.returnFitsDay,
  });

  final int plannedStops;
  final int locatedStops;
  final bool routeAvailable;
  final int? travelMinutes;
  final double? distanceKm;
  final bool estimated;
  final String? firstDepartureAt;
  final String? returnArrivalAt;
  final bool? returnFitsDay;

  factory TripDayLogistics.fromJson(Map<String, dynamic>? json) =>
      TripDayLogistics(
        plannedStops: (json?['planned_stops'] as num?)?.toInt() ?? 0,
        locatedStops: (json?['located_stops'] as num?)?.toInt() ?? 0,
        routeAvailable: json?['route_available'] as bool? ?? false,
        travelMinutes: (json?['travel_minutes'] as num?)?.toInt(),
        distanceKm: (json?['distance_km'] as num?)?.toDouble(),
        estimated: json?['estimated'] as bool? ?? false,
        firstDepartureAt: json?['first_departure_at'] as String?,
        returnArrivalAt: json?['return_arrival_at'] as String?,
        returnFitsDay: json?['return_fits_day'] as bool?,
      );
}

class TripPlanItem {
  const TripPlanItem({
    required this.id,
    required this.slot,
    required this.kind,
    required this.title,
    required this.status,
    this.summary,
    this.venueName,
    this.startsAt,
    this.endsAt,
    this.distanceKm,
    this.provider,
    this.url,
    this.imageUrl,
    this.rating,
    this.ratingCount,
    this.metadata = const {},
  });

  final int id;
  final String slot;
  final String kind;
  final String title;
  final String status;
  final String? summary;
  final String? venueName;
  final String? startsAt;
  final String? endsAt;
  final double? distanceKm;
  final String? provider;
  final String? url;
  final String? imageUrl;
  final double? rating;
  final int? ratingCount;
  final Map<String, dynamic> metadata;

  bool get available => status != 'unavailable';

  factory TripPlanItem.fromJson(Map<String, dynamic> json) => TripPlanItem(
        id: json['id'] as int,
        slot: json['slot'] as String,
        kind: json['kind'] as String,
        title: json['title'] as String,
        status: json['status'] as String,
        summary: json['summary'] as String?,
        venueName: json['venue_name'] as String?,
        startsAt: json['starts_at'] as String?,
        endsAt: json['ends_at'] as String?,
        distanceKm: (json['distance_km'] as num?)?.toDouble(),
        provider: json['provider'] as String?,
        url: json['url'] as String?,
        imageUrl: json['image_url'] as String?,
        rating: (json['rating'] as num?)?.toDouble(),
        ratingCount: (json['rating_count'] as num?)?.toInt(),
        metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      );
}

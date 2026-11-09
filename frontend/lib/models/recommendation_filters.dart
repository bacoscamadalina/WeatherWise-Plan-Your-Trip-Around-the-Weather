class RecommendationFilters {
  const RecommendationFilters({
    this.type,
    this.genre,
    this.activityKind,
    this.setting,
    this.maxDistanceKm,
    this.timeOfDay,
  });

  static const _unset = Object();

  final String? type;
  final String? genre;
  final String? activityKind;
  final String? setting;
  final double? maxDistanceKm;
  final String? timeOfDay;

  factory RecommendationFilters.fromJson(Map<String, dynamic> json) =>
      RecommendationFilters(
        type: json['type'] as String?,
        genre: json['genre'] as String?,
        activityKind: json['activity_kind'] as String?,
        setting: json['setting'] as String?,
        maxDistanceKm: (json['max_distance_km'] as num?)?.toDouble(),
        timeOfDay: json['time_of_day'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'genre': genre,
        'activity_kind': activityKind,
        'setting': setting,
        'max_distance_km': maxDistanceKm,
        'time_of_day': timeOfDay,
      };

  bool get hasRefinements =>
      genre != null ||
      activityKind != null ||
      setting != null ||
      maxDistanceKm != null ||
      timeOfDay != null;

  int get refinementCount => [
        genre,
        activityKind,
        setting,
        maxDistanceKm,
        timeOfDay,
      ].where((value) => value != null).length;

  RecommendationFilters forType(String? value) {
    if (value == 'movie') {
      return RecommendationFilters(
        type: value,
        genre: genre,
        timeOfDay: timeOfDay,
      );
    }
    if (value == 'activity') {
      return RecommendationFilters(
        type: value,
        activityKind: activityKind,
        setting: setting,
        maxDistanceKm: maxDistanceKm,
        timeOfDay: timeOfDay,
      );
    }
    if (value == 'event') {
      return RecommendationFilters(type: value, timeOfDay: timeOfDay);
    }
    return copyWith(type: value);
  }

  RecommendationFilters copyWith({
    Object? type = _unset,
    Object? genre = _unset,
    Object? activityKind = _unset,
    Object? setting = _unset,
    Object? maxDistanceKm = _unset,
    Object? timeOfDay = _unset,
  }) {
    return RecommendationFilters(
      type: identical(type, _unset) ? this.type : type as String?,
      genre: identical(genre, _unset) ? this.genre : genre as String?,
      activityKind: identical(activityKind, _unset)
          ? this.activityKind
          : activityKind as String?,
      setting: identical(setting, _unset) ? this.setting : setting as String?,
      maxDistanceKm: identical(maxDistanceKm, _unset)
          ? this.maxDistanceKm
          : maxDistanceKm as double?,
      timeOfDay:
          identical(timeOfDay, _unset) ? this.timeOfDay : timeOfDay as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RecommendationFilters &&
      type == other.type &&
      genre == other.genre &&
      activityKind == other.activityKind &&
      setting == other.setting &&
      maxDistanceKm == other.maxDistanceKm &&
      timeOfDay == other.timeOfDay;

  @override
  int get hashCode =>
      Object.hash(type, genre, activityKind, setting, maxDistanceKm, timeOfDay);
}

import 'location.dart';

class AdvisoryNotificationPreferences {
  const AdvisoryNotificationPreferences({
    this.enabled = false,
    this.locationId,
    this.locationName,
    this.hour = 8,
    this.minute = 0,
    this.highOnly = false,
  });

  final bool enabled;
  final int? locationId;
  final String? locationName;
  final int hour;
  final int minute;
  final bool highOnly;

  bool follows(Location location) => enabled && locationId == location.id;

  AdvisoryNotificationPreferences forLocation(
    Location location, {
    required bool enabled,
    required int hour,
    required int minute,
    required bool highOnly,
  }) =>
      AdvisoryNotificationPreferences(
        enabled: enabled,
        locationId: enabled ? location.id : null,
        locationName: enabled ? location.name : null,
        hour: hour,
        minute: minute,
        highOnly: highOnly,
      );

  factory AdvisoryNotificationPreferences.fromJson(
    Map<String, dynamic> json,
  ) =>
      AdvisoryNotificationPreferences(
        enabled: json['enabled'] as bool? ?? false,
        locationId: (json['location_id'] as num?)?.toInt(),
        locationName: json['location_name'] as String?,
        hour: ((json['hour'] as num?)?.toInt() ?? 8).clamp(0, 23),
        minute: ((json['minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
        highOnly: json['high_only'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        if (locationId != null) 'location_id': locationId,
        if (locationName != null) 'location_name': locationName,
        'hour': hour,
        'minute': minute,
        'high_only': highOnly,
      };
}

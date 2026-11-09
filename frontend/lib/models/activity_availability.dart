class ActivityAvailability {
  const ActivityAvailability({
    required this.status,
    required this.label,
    required this.detail,
    required this.period,
    this.provider,
    this.checkedAt,
    this.placeName,
    this.placeUrl,
    this.attributionLabel,
    this.attributionUrl,
  });

  final String status;
  final String label;
  final String detail;
  final String period;
  final String? provider;
  final DateTime? checkedAt;
  final String? placeName;
  final Uri? placeUrl;
  final String? attributionLabel;
  final Uri? attributionUrl;

  bool get isOpen => status == 'verified_open';

  bool get isClosed => const {
        'verified_closed',
        'temporarily_closed',
        'permanently_closed',
      }.contains(status);

  factory ActivityAvailability.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? attribution,
  }) {
    return ActivityAvailability(
      status: json['status'] as String,
      label: json['label'] as String,
      detail: json['detail'] as String,
      period: json['period'] as String,
      provider: json['provider'] as String?,
      checkedAt: json['checked_at'] == null
          ? null
          : DateTime.tryParse(json['checked_at'] as String),
      placeName: json['place_name'] as String?,
      placeUrl: _optionalUri(json['place_url'] as String?),
      attributionLabel: attribution?['label'] as String?,
      attributionUrl: _optionalUri(attribution?['url'] as String?),
    );
  }

  static Uri? _optionalUri(String? value) {
    if (value == null || value.isEmpty) return null;
    return Uri.tryParse(value);
  }
}

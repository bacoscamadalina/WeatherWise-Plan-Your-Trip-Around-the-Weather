class EventDaySummary {
  const EventDaySummary({
    required this.date,
    required this.count,
    required this.previewTitle,
    required this.providers,
    this.previewVenue,
    this.previewImageUrl,
  });

  final DateTime date;
  final int count;
  final String previewTitle;
  final String? previewVenue;
  final String? previewImageUrl;
  final List<String> providers;

  factory EventDaySummary.fromJson(Map<String, dynamic> json) {
    final preview = json['preview'] as Map<String, dynamic>? ?? const {};
    return EventDaySummary(
      date: DateTime.parse(json['date'] as String),
      count: (json['count'] as num).toInt(),
      previewTitle: preview['title'] as String,
      previewVenue: preview['venue_name'] as String?,
      previewImageUrl: preview['image_url'] as String?,
      providers:
          ((json['providers'] as List<dynamic>?) ?? const []).cast<String>(),
    );
  }
}

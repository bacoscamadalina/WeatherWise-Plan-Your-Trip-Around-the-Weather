class CinemaShowtime {
  const CinemaShowtime({
    required this.id,
    required this.filmId,
    required this.filmTitle,
    required this.cinemaId,
    required this.cinemaName,
    required this.date,
    required this.format,
    required this.startTime,
    this.endTime,
    this.distanceKm,
    this.imageUrl,
    this.attributionLabel,
    this.attributionUrl,
  });

  final String id;
  final String filmId;
  final String filmTitle;
  final String cinemaId;
  final String cinemaName;
  final DateTime date;
  final String format;
  final String startTime;
  final String? endTime;
  final double? distanceKm;
  final String? imageUrl;
  final String? attributionLabel;
  final String? attributionUrl;

  factory CinemaShowtime.fromJson(
    Map<String, dynamic> json, {
    String? attributionLabel,
    String? attributionUrl,
  }) {
    return CinemaShowtime(
      id: json['id'].toString(),
      filmId: json['film_id'].toString(),
      filmTitle: json['film_title'] as String,
      cinemaId: json['cinema_id'].toString(),
      cinemaName: json['cinema_name'] as String,
      date: DateTime.parse(json['date'] as String),
      format: json['format'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
      attributionLabel: attributionLabel,
      attributionUrl: attributionUrl,
    );
  }
}

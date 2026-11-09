import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/cinema_showtime.dart';

class CinemaShowtimeSection extends StatelessWidget {
  const CinemaShowtimeSection({
    required this.showtimes,
    required this.loading,
    required this.onShowtimePressed,
    required this.onAddToPlan,
    required this.onRetry,
    this.error,
    this.timeOfDay,
    this.bookingShowtimeId,
    super.key,
  });

  final List<CinemaShowtime> showtimes;
  final bool loading;
  final String? error;
  final String? timeOfDay;
  final String? bookingShowtimeId;
  final ValueChanged<CinemaShowtime> onShowtimePressed;
  final ValueChanged<CinemaShowtime> onAddToPlan;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final visibleShowtimes = showtimes
        .where((showtime) => _matchesPeriod(showtime.startTime, timeOfDay))
        .toList();
    final films = _groupShowtimes(visibleShowtimes);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_movies_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                strings.cinemaShowtimes,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            strings.cinemaShowtimesSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (loading) const LinearProgressIndicator(),
          if (!loading && error != null)
            _ShowtimeMessage(
              icon: Icons.sync_problem_outlined,
              message: error!,
              actionLabel: strings.tryAgain,
              onAction: onRetry,
            ),
          if (!loading && error == null && films.isEmpty)
            _ShowtimeMessage(
              icon: Icons.schedule_outlined,
              message: showtimes.isNotEmpty && timeOfDay != null
                  ? strings.noShowtimesForPeriod
                  : strings.noLiveCinemaTimes,
            ),
          if (!loading && error == null)
            for (final film in films) _filmShowtimes(group: film),
          if (!loading &&
              error == null &&
              visibleShowtimes.isNotEmpty &&
              visibleShowtimes.first.attributionLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              visibleShowtimes.first.attributionLabel!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _filmShowtimes({required _FilmGroup group}) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final cinema in group.cinemas) ...[
              Text(
                [
                  cinema.name,
                  if (cinema.distanceKm != null)
                    AppStrings.of(context).distanceAway(cinema.distanceKm!),
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final showtime in cinema.showtimes)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: bookingShowtimeId == null
                                ? () => onShowtimePressed(showtime)
                                : null,
                            child: bookingShowtimeId == showtime.id
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    showtime.format.toLowerCase() == 'standard'
                                        ? showtime.startTime
                                        : '${showtime.startTime} · ${showtime.format}',
                                  ),
                          ),
                        ),
                        IconButton(
                          key: ValueKey('add-showtime-${showtime.id}'),
                          tooltip: AppStrings.of(context).addShowtimeToPlan,
                          onPressed: () => onAddToPlan(showtime),
                          icon: const Icon(Icons.playlist_add),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShowtimeMessage extends StatelessWidget {
  const _ShowtimeMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _FilmGroup {
  const _FilmGroup({required this.title, required this.cinemas});

  final String title;
  final List<_CinemaGroup> cinemas;
}

class _CinemaGroup {
  const _CinemaGroup({
    required this.name,
    required this.showtimes,
    this.distanceKm,
  });

  final String name;
  final double? distanceKm;
  final List<CinemaShowtime> showtimes;
}

List<_FilmGroup> _groupShowtimes(List<CinemaShowtime> showtimes) {
  final films = <String, List<CinemaShowtime>>{};
  for (final showtime in showtimes) {
    films.putIfAbsent(showtime.filmId, () => []).add(showtime);
  }

  return films.values.map((filmShowtimes) {
    final cinemas = <String, List<CinemaShowtime>>{};
    for (final showtime in filmShowtimes) {
      cinemas.putIfAbsent(showtime.cinemaId, () => []).add(showtime);
    }
    return _FilmGroup(
      title: filmShowtimes.first.filmTitle,
      cinemas: cinemas.values.map((cinemaShowtimes) {
        cinemaShowtimes.sort((a, b) => a.startTime.compareTo(b.startTime));
        return _CinemaGroup(
          name: cinemaShowtimes.first.cinemaName,
          distanceKm: cinemaShowtimes.first.distanceKm,
          showtimes: cinemaShowtimes,
        );
      }).toList(),
    );
  }).toList();
}

bool _matchesPeriod(String value, String? period) {
  if (period == null) return true;
  final hour = int.tryParse(value.split(':').first);
  if (hour == null) return false;

  return switch (period) {
    'morning' => hour >= 3 && hour < 12,
    'afternoon' => hour >= 12 && hour < 17,
    'evening' => hour >= 17 || hour < 3,
    _ => true,
  };
}

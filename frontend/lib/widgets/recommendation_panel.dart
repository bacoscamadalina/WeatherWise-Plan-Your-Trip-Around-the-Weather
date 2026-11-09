import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_strings.dart';
import '../models/cinema_showtime.dart';
import '../models/event_day_summary.dart';
import '../models/itinerary_item.dart';
import '../models/hourly_forecast.dart';
import '../models/plan_recommendation.dart';
import '../models/recommendation_filters.dart';
import '../services/location_imagery.dart';
import '../theme/atlas_theme.dart';
import 'cinema_showtime_section.dart';
import 'day_itinerary_section.dart';

class RecommendationPanel extends StatelessWidget {
  const RecommendationPanel({
    required this.recommendations,
    required this.loading,
    required this.filters,
    required this.onTypeChanged,
    required this.onTunePressed,
    required this.onClearFilters,
    required this.onRetry,
    required this.onRecommendationPressed,
    required this.showtimes,
    required this.showtimesLoading,
    required this.onShowtimesRetry,
    required this.onShowtimePressed,
    required this.itinerary,
    required this.onAddRecommendationToPlan,
    required this.onAddShowtimeToPlan,
    required this.onRemoveFromPlan,
    required this.onClearPlan,
    required this.onCopyPlan,
    required this.onCalendarPlan,
    required this.onRoutePlan,
    required this.onSuggestPlan,
    required this.hourlyForecasts,
    required this.onAdaptPlan,
    this.eventDays = const [],
    this.eventDaysLoading = false,
    this.onEventDayPressed,
    this.adaptingPlan = false,
    this.error,
    this.eventDaysError,
    this.showtimesError,
    this.bookingShowtimeId,
    super.key,
  });

  final List<PlanRecommendation> recommendations;
  final List<EventDaySummary> eventDays;
  final bool eventDaysLoading;
  final String? eventDaysError;
  final ValueChanged<EventDaySummary>? onEventDayPressed;
  final bool loading;
  final RecommendationFilters filters;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onTunePressed;
  final VoidCallback onClearFilters;
  final VoidCallback onRetry;
  final ValueChanged<PlanRecommendation> onRecommendationPressed;
  final List<CinemaShowtime> showtimes;
  final bool showtimesLoading;
  final VoidCallback onShowtimesRetry;
  final ValueChanged<CinemaShowtime> onShowtimePressed;
  final List<ItineraryItem> itinerary;
  final ValueChanged<PlanRecommendation> onAddRecommendationToPlan;
  final ValueChanged<CinemaShowtime> onAddShowtimeToPlan;
  final ValueChanged<String> onRemoveFromPlan;
  final VoidCallback onClearPlan;
  final VoidCallback onCopyPlan;
  final VoidCallback onCalendarPlan;
  final VoidCallback? onRoutePlan;
  final VoidCallback onSuggestPlan;
  final List<HourlyForecast> hourlyForecasts;
  final VoidCallback? onAdaptPlan;
  final bool adaptingPlan;
  final String? error;
  final String? showtimesError;
  final String? bookingShowtimeId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.ideasTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              strings.ideasSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filter(strings.all, null),
                _filter(strings.activities, 'activity'),
                _filter(strings.events, 'event'),
                _filter(strings.movies, 'movie'),
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 18),
                  label: Text(
                    strings.tuneIdeas(filters.refinementCount),
                  ),
                  onPressed: onTunePressed,
                ),
              ],
            ),
            if (filters.hasRefinements) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _filterSummary(strings),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: onClearFilters,
                    child: Text(strings.clear),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            DayItinerarySection(
              items: itinerary,
              onRemove: onRemoveFromPlan,
              onClear: onClearPlan,
              onCopy: onCopyPlan,
              onCalendar: onCalendarPlan,
              onRoute: onRoutePlan,
              onSuggest: onSuggestPlan,
              canSuggest: !loading &&
                  recommendations.isNotEmpty &&
                  itinerary.length < 3,
              hourlyForecasts: hourlyForecasts,
              onAdapt: onAdaptPlan,
              adapting: adaptingPlan,
            ),
            if (filters.type == 'movie')
              CinemaShowtimeSection(
                showtimes: showtimes,
                loading: showtimesLoading,
                error: showtimesError,
                timeOfDay: filters.timeOfDay,
                bookingShowtimeId: bookingShowtimeId,
                onRetry: onShowtimesRetry,
                onShowtimePressed: onShowtimePressed,
                onAddToPlan: onAddShowtimeToPlan,
              ),
            if (loading) ..._skeletons(colors),
            if (!loading && error != null)
              _ErrorState(message: error!, onRetry: onRetry),
            if (!loading &&
                error == null &&
                recommendations.isEmpty &&
                !(filters.type == 'movie' && showtimes.isNotEmpty))
              _EmptyState(
                hasFilters: filters.hasRefinements,
                eventCategory: filters.type == 'event',
                eventDays: eventDays,
                eventDaysLoading: eventDaysLoading,
                eventDaysError: eventDaysError,
                onEventDayPressed: onEventDayPressed,
                onClearFilters: onClearFilters,
              ),
            if (!loading && error == null)
              _RecommendationGallery(
                items: recommendations,
                onPressed: onRecommendationPressed,
                onAddToPlan: onAddRecommendationToPlan,
              ),
            if (!loading && error == null && recommendations.isNotEmpty)
              _ProviderAttribution(items: recommendations),
          ],
        ),
      ),
    );
  }

  Widget _filter(String label, String? value) {
    return ChoiceChip(
      label: Text(label),
      selected: filters.type == value,
      onSelected: (_) => onTypeChanged(value),
    );
  }

  String _filterSummary(AppStrings strings) {
    return [
      if (filters.setting != null) strings.filterValue(filters.setting!),
      if (filters.timeOfDay != null) strings.filterValue(filters.timeOfDay!),
      if (filters.activityKind != null)
        strings.filterValue(filters.activityKind!),
      if (filters.genre != null) strings.movieFilter(filters.genre!),
      if (filters.maxDistanceKm != null)
        strings.withinDistance(filters.maxDistanceKm!),
    ].join(' · ');
  }

  List<Widget> _skeletons(ColorScheme colors) => List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      widthFactor: index.isEven ? 0.55 : 0.7,
                      child: Container(
                        height: 12,
                        color: colors.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 9,
                      color: colors.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _RecommendationGallery extends StatelessWidget {
  const _RecommendationGallery({
    required this.items,
    required this.onPressed,
    required this.onAddToPlan,
  });

  final List<PlanRecommendation> items;
  final ValueChanged<PlanRecommendation> onPressed;
  final ValueChanged<PlanRecommendation> onAddToPlan;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final orderedItems = [...items]..sort((left, right) {
        int priority(PlanRecommendation item) {
          final title = item.title.toLowerCase();
          if (item.type == 'movie') return 0;
          if (title.contains('botanic')) return 1;
          return 2;
        }

        final comparison = priority(left).compareTo(priority(right));
        return comparison == 0 ? 0 : comparison;
      });
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final gap = 14.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in orderedItems)
              SizedBox(
                width: width,
                child: _RecommendationRow(
                  item: item,
                  onPressed: () => onPressed(item),
                  onAddToPlan: () => onAddToPlan(item),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({
    required this.item,
    required this.onPressed,
    required this.onAddToPlan,
  });

  final PlanRecommendation item;
  final VoidCallback onPressed;
  final VoidCallback onAddToPlan;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: AtlasColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('recommendation-${item.type}-${item.id}'),
        onTap: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 184,
              width: double.infinity,
              child: Hero(
                tag: _heroTag(item),
                child: _RecommendationMedia(item: item),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 17,
                              color: AtlasColors.ink,
                              fontWeight: FontWeight.w700,
                            )),
                        if (item.venueName != null ||
                            item.distanceKm != null ||
                            item.eventTime != null)
                          Text(
                            [
                              if (item.venueName != null) item.venueName!,
                              if (item.eventTime != null)
                                _shortTime(item.eventTime!),
                              if (item.distanceKm != null)
                                AppStrings.of(context)
                                    .distanceAway(item.distanceKm!),
                            ].join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (item.elevationM != null ||
                            item.routeDistanceKm != null ||
                            item.durationMinutes != null ||
                            item.difficulty != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (item.elevationM != null)
                                AppStrings.of(context)
                                    .elevationValue(item.elevationM!),
                              if (item.routeDistanceKm != null)
                                AppStrings.of(context)
                                    .routeLengthValue(item.routeDistanceKm!),
                              if (item.durationMinutes != null)
                                AppStrings.of(context)
                                    .durationValue(item.durationMinutes!),
                              if (item.difficulty != null)
                                AppStrings.of(context)
                                    .trailDifficultyValue(item.difficulty!),
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                            AppStrings.of(context)
                                .recommendationReason(item.reason),
                            style: TextStyle(color: colors.primary)),
                        for (final note in item.planningNotes) ...[
                          const SizedBox(height: 5),
                          Builder(builder: (context) {
                            final localizedMessage = AppStrings.of(context)
                                .planningNoteMessage(note.code, note.message);
                            return Semantics(
                              label: AppStrings.of(context)
                                  .planningNote(localizedMessage),
                              excludeSemantics: true,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    note.code.contains('uv')
                                        ? Icons.wb_sunny_outlined
                                        : Icons.info_outline,
                                    size: 16,
                                    color: colors.tertiary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      localizedMessage,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: colors.tertiary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        if (item.availability != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                item.availability!.status == 'listed_open'
                                    ? Icons.schedule
                                    : Icons.info_outline,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.availability!.label,
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          item.summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.openingHours != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.of(context)
                                .listedHours(item.openingHours!),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                        if (item.rating != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.of(context).tmdbRating(item.rating!),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey(
                      'add-recommendation-${item.type}-${item.id}',
                    ),
                    tooltip: AppStrings.of(context).addToDayPlan,
                    onPressed: onAddToPlan,
                    icon: Icon(Icons.arrow_forward_rounded,
                        color: colors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationMedia extends StatelessWidget {
  const _RecommendationMedia({required this.item});

  final PlanRecommendation item;

  @override
  Widget build(BuildContext context) {
    final localAsset = LocationImagery.recommendationAsset(item);
    final fallback = localAsset == null
        ? _RecommendationArtwork(item: item)
        : DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(localAsset),
                fit: BoxFit.cover,
              ),
            ),
          );
    final media = item.imageUrl == null
        ? fallback
        : Image.network(
            item.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );
    final movie = item.type == 'movie';
    final event = item.type == 'event';
    final label = movie
        ? AppStrings.of(context).recommendationMovieLabel
        : event
            ? AppStrings.of(context).recommendationEventLabel
            : AppStrings.of(context).recommendationActivityLabel;
    return Stack(
      fit: StackFit.expand,
      children: [
        media,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x15000000), Color(0x52000000)],
              stops: [0.45, 1],
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: movie
                  ? AtlasColors.coral
                  : event
                      ? AtlasColors.gold
                      : AtlasColors.mint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  movie
                      ? Icons.movie_outlined
                      : event
                          ? Icons.event_outlined
                          : Icons.eco_outlined,
                  size: 16,
                  color: movie ? Colors.white : AtlasColors.ink,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: movie ? Colors.white : AtlasColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationArtwork extends StatelessWidget {
  const _RecommendationArtwork({required this.item});

  final PlanRecommendation item;

  @override
  Widget build(BuildContext context) {
    final movie = item.type == 'movie';
    final event = item.type == 'event';
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: movie
              ? const [Color(0xFF173A5A), Color(0xFF386C85)]
              : event
                  ? const [Color(0xFFFFE2A2), Color(0xFFF5A86E)]
                  : const [Color(0xFFDDF3E9), Color(0xFF93CDB5)],
        ),
      ),
      child: Center(
        child: Icon(
          movie
              ? Icons.movie_outlined
              : event
                  ? Icons.event_outlined
                  : Icons.local_florist_outlined,
          size: 44,
          color: movie ? Colors.white : AtlasColors.ink,
        ),
      ),
    );
  }
}

String _heroTag(PlanRecommendation item) =>
    'recommendation-${item.provider ?? 'local'}-${item.id}';

String _shortTime(String value) =>
    value.length >= 5 ? value.substring(0, 5) : value;

class _ProviderAttribution extends StatelessWidget {
  const _ProviderAttribution({required this.items});

  final List<PlanRecommendation> items;

  @override
  Widget build(BuildContext context) {
    final hasOpenStreetMap =
        items.any((item) => item.provider == 'openstreetmap');
    final hasTicketmaster =
        items.any((item) => item.provider == 'ticketmaster');
    final hasPredictHq = items.any((item) => item.provider == 'predicthq');
    final tmdbItem = items.cast<PlanRecommendation?>().firstWhere(
          (item) => item?.provider == 'tmdb',
          orElse: () => null,
        );
    final imageCredits = items
        .map((item) => item.imageAttributionLabel)
        .whereType<String>()
        .where((credit) => credit.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (!hasOpenStreetMap &&
        !hasTicketmaster &&
        !hasPredictHq &&
        tmdbItem == null &&
        imageCredits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.of(context).dataCredits,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          if (hasOpenStreetMap)
            Text(
              '© OpenStreetMap contributors',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          if (hasTicketmaster) ...[
            if (hasOpenStreetMap) const SizedBox(height: 6),
            Text(
              AppStrings.of(context).eventDataByTicketmaster,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          if (hasPredictHq) ...[
            if (hasOpenStreetMap || hasTicketmaster) const SizedBox(height: 6),
            Text(
              AppStrings.of(context).eventDataByPredictHq,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          if (imageCredits.isNotEmpty) ...[
            if (hasOpenStreetMap || hasTicketmaster) const SizedBox(height: 6),
            for (final credit in imageCredits)
              Text(
                'Photo: $credit',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
          if (tmdbItem != null) ...[
            if (hasOpenStreetMap || hasTicketmaster) const SizedBox(height: 8),
            SvgPicture.asset(
              'assets/tmdb_logo.svg',
              height: 22,
              semanticsLabel: 'The Movie Database',
            ),
            const SizedBox(height: 5),
            Text(
              tmdbItem.attributionNotice ??
                  'This product uses the TMDB API but is not endorsed or certified by TMDB.',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        TextButton(
          onPressed: onRetry,
          child: Text(AppStrings.of(context).tryAgain),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasFilters,
    required this.eventCategory,
    required this.eventDays,
    required this.eventDaysLoading,
    required this.eventDaysError,
    required this.onEventDayPressed,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final bool eventCategory;
  final List<EventDaySummary> eventDays;
  final bool eventDaysLoading;
  final String? eventDaysError;
  final ValueChanged<EventDaySummary>? onEventDayPressed;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
        container: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: eventCategory
                          ? AtlasColors.paleGold
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      eventCategory
                          ? Icons.event_busy_outlined
                          : Icons.search_off_outlined,
                      color: AtlasColors.ink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasFilters
                          ? strings.noFilteredIdeas
                          : eventCategory
                              ? strings.noEventIdeas
                              : strings.noCategoryIdeas,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AtlasColors.ink,
                            height: 1.45,
                          ),
                    ),
                  ),
                ],
              ),
              if (hasFilters)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onClearFilters,
                    child: Text(strings.clearFilters),
                  ),
                ),
              if (eventCategory && !hasFilters) ...[
                const SizedBox(height: 16),
                if (eventDaysLoading)
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(strings.searchingEventDays),
                    ],
                  )
                else if (eventDaysError != null)
                  Text(
                    eventDaysError!,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else if (eventDays.isNotEmpty) ...[
                  Text(
                    strings.upcomingEventDays,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AtlasColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final day in eventDays)
                    _EventDayRow(
                      day: day,
                      onPressed: onEventDayPressed == null
                          ? null
                          : () => onEventDayPressed!(day),
                    ),
                ],
              ],
            ],
          ),
        ));
  }
}

class _EventDayRow extends StatelessWidget {
  const _EventDayRow({required this.day, required this.onPressed});

  final EventDaySummary day;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final date = MaterialLocalizations.of(context).formatMediumDate(day.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AtlasColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AtlasColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: day.previewImageUrl == null
                        ? const ColoredBox(
                            color: AtlasColors.paleGold,
                            child: Icon(Icons.event_outlined,
                                color: AtlasColors.ink),
                          )
                        : Image.network(
                            day.previewImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: AtlasColors.paleGold,
                              child: Icon(Icons.event_outlined,
                                  color: AtlasColors.ink),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$date · ${strings.eventCount(day.count)}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AtlasColors.azure,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.previewTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AtlasColors.ink,
                        ),
                      ),
                      if (day.previewVenue != null)
                        Text(
                          day.previewVenue!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: AtlasColors.azure),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

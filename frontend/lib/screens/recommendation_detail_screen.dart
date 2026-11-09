import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/activity_availability.dart';
import '../models/daily_forecast.dart';
import '../models/location.dart';
import '../models/plan_recommendation.dart';

const _mapTileUrl = String.fromEnvironment(
  'MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);
const _mapAttributionLabel = String.fromEnvironment(
  'MAP_ATTRIBUTION_LABEL',
  defaultValue: 'OpenStreetMap contributors',
);
const _mapAttributionUrl = String.fromEnvironment(
  'MAP_ATTRIBUTION_URL',
  defaultValue: 'https://www.openstreetmap.org/copyright',
);

typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);
typedef AvailabilityChecker = Future<ActivityAvailability> Function(
  String period,
);

Future<bool> launchExternalLink(Uri uri) => launchUrl(uri);

class RecommendationDetailScreen extends StatelessWidget {
  const RecommendationDetailScreen({
    required this.recommendation,
    required this.forecast,
    required this.location,
    this.linkLauncher = launchExternalLink,
    this.availabilityChecker,
    super.key,
  });

  final PlanRecommendation recommendation;
  final DailyForecast forecast;
  final Location location;
  final ExternalLinkLauncher linkLauncher;
  final AvailabilityChecker? availabilityChecker;

  bool get _hasCoordinates =>
      recommendation.latitude != null && recommendation.longitude != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).ideaType(recommendation.type)),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroSummary(
              recommendation: recommendation,
              forecast: forecast,
              location: location,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WhyItFits(recommendation: recommendation),
                      if (recommendation.type == 'activity' &&
                          recommendation.weatherSensitive) ...[
                        const SizedBox(height: 30),
                        _TrailPreparationSection(
                          recommendation: recommendation,
                        ),
                      ],
                      if (recommendation.type != 'movie') ...[
                        const SizedBox(height: 30),
                        _PlaceSection(
                          recommendation: recommendation,
                          linkLauncher: linkLauncher,
                        ),
                      ],
                      if (recommendation.type == 'activity' &&
                          !recommendation.weatherSensitive &&
                          availabilityChecker != null) ...[
                        const SizedBox(height: 30),
                        _LiveAvailabilitySection(
                          recommendation: recommendation,
                          checker: availabilityChecker!,
                          linkLauncher: linkLauncher,
                        ),
                      ],
                      const SizedBox(height: 30),
                      _DayPlan(
                        recommendation: recommendation,
                        forecast: forecast,
                      ),
                      const SizedBox(height: 30),
                      _DetailsSection(recommendation: recommendation),
                      const SizedBox(height: 28),
                      _ActionBar(
                        recommendation: recommendation,
                        hasCoordinates: _hasCoordinates,
                        linkLauncher: linkLauncher,
                      ),
                      if (recommendation.provider == 'tmdb') ...[
                        const SizedBox(height: 28),
                        const _TmdbCredit(),
                      ],
                      if (recommendation.provider == 'ticketmaster') ...[
                        const SizedBox(height: 28),
                        const _TicketmasterCredit(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.recommendation,
    required this.forecast,
    required this.location,
  });

  final PlanRecommendation recommendation;
  final DailyForecast forecast;
  final Location location;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.primaryContainer,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: _heroTag(recommendation),
                  child: Material(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(
                        recommendation.type == 'movie'
                            ? Icons.movie_outlined
                            : recommendation.type == 'event'
                                ? Icons.event_outlined
                                : Icons.place_outlined,
                        color: colors.onPrimary,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      if (recommendation.venueName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          recommendation.venueName!,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: colors.onPrimaryContainer,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '${location.name} · ${_dateLabel(context, forecast.date)} · ${AppStrings.of(context).weatherLabel(forecast.label)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onPrimaryContainer,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhyItFits extends StatelessWidget {
  const _WhyItFits({required this.recommendation});

  final PlanRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.of(context).whyItFits,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_awesome_outlined, color: colors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.of(context)
                    .recommendationReason(recommendation.reason),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(recommendation.summary,
            style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _TrailPreparationSection extends StatelessWidget {
  const _TrailPreparationSection({required this.recommendation});

  final PlanRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final facts = <(IconData, String, String)>[
      if (recommendation.routeDistanceKm != null)
        (
          Icons.route_outlined,
          strings.routeLength,
          strings.routeLengthValue(recommendation.routeDistanceKm!),
        ),
      if (recommendation.routeStart != null)
        (Icons.flag_outlined, strings.routeStart, recommendation.routeStart!),
      if (recommendation.routeEnd != null)
        (Icons.outlined_flag, strings.routeEnd, recommendation.routeEnd!),
      if (recommendation.durationMinutes != null)
        (
          Icons.schedule_outlined,
          strings.mappedDuration,
          strings.durationValue(recommendation.durationMinutes!),
        ),
      if (recommendation.ascentM != null)
        (
          Icons.trending_up,
          strings.ascent,
          strings.elevationValue(recommendation.ascentM!),
        ),
      if (recommendation.descentM != null)
        (
          Icons.trending_down,
          strings.descent,
          strings.elevationValue(recommendation.descentM!),
        ),
      if (recommendation.roundtrip != null)
        (
          recommendation.roundtrip!
              ? Icons.loop_outlined
              : Icons.arrow_forward_outlined,
          strings.routeShape,
          strings.roundtripValue(recommendation.roundtrip!),
        ),
      if (recommendation.routeNetwork != null)
        (
          Icons.account_tree_outlined,
          strings.routeNetwork,
          strings.routeNetworkValue(recommendation.routeNetwork!),
        ),
      if (recommendation.routeRef != null)
        (
          Icons.signpost_outlined,
          strings.routeReference,
          recommendation.routeRef!,
        ),
      if (recommendation.trailMarker != null)
        (
          Icons.assistant_direction_outlined,
          strings.trailMarker,
          strings.trailMarkerValue(recommendation.trailMarker!),
        ),
      if (recommendation.routeOperator != null)
        (
          Icons.shield_outlined,
          strings.routeOperator,
          recommendation.routeOperator!,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.trailPlanTitle,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(strings.trailPlanSubtitle),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (facts.isNotEmpty)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final factWidth = constraints.maxWidth >= 520
                        ? (constraints.maxWidth - 20) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 20,
                      runSpacing: 16,
                      children: [
                        for (final fact in facts)
                          SizedBox(
                            width: factWidth,
                            child: _TrailFact(
                              icon: fact.$1,
                              label: fact.$2,
                              value: fact.$3,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              if (facts.isNotEmpty) const SizedBox(height: 18),
              for (final note in recommendation.planningNotes) ...[
                _TrailNotice(
                  icon: note.code.contains('uv')
                      ? Icons.wb_sunny_outlined
                      : Icons.cloud_outlined,
                  message: strings.planningNoteMessage(
                    note.code,
                    note.message,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _TrailNotice(
                icon: Icons.health_and_safety_outlined,
                message: strings.verifyMountainConditions,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailFact extends StatelessWidget {
  const _TrailFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailNotice extends StatelessWidget {
  const _TrailNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.tertiary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _PlaceSection extends StatelessWidget {
  const _PlaceSection(
      {required this.recommendation, required this.linkLauncher});

  final PlanRecommendation recommendation;
  final ExternalLinkLauncher linkLauncher;

  @override
  Widget build(BuildContext context) {
    final latitude = recommendation.latitude;
    final longitude = recommendation.longitude;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.of(context).whereYouGo,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (latitude != null && longitude != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 240,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 14.5,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _mapTileUrl,
                    userAgentPackageName: 'app.weatherwise.client',
                    panBuffer: 0,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(latitude, longitude),
                        width: 48,
                        height: 48,
                        child: const Icon(Icons.location_pin,
                            color: Color(0xFFB43B32), size: 42),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomRight,
                    attributions: [
                      TextSourceAttribution(
                        _mapAttributionLabel,
                        onTap: () => linkLauncher(
                          Uri.parse(_mapAttributionUrl),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(AppStrings.of(context).mapUnavailable)),
              ],
            ),
          ),
      ],
    );
  }
}

class _LiveAvailabilitySection extends StatefulWidget {
  const _LiveAvailabilitySection({
    required this.recommendation,
    required this.checker,
    required this.linkLauncher,
  });

  final PlanRecommendation recommendation;
  final AvailabilityChecker checker;
  final ExternalLinkLauncher linkLauncher;

  @override
  State<_LiveAvailabilitySection> createState() =>
      _LiveAvailabilitySectionState();
}

class _LiveAvailabilitySectionState extends State<_LiveAvailabilitySection> {
  ActivityAvailability? _result;
  bool _loading = false;
  String? _error;

  String get _period => _preferredPeriod(widget.recommendation);

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await widget.checker(_period);
      if (mounted) {
        setState(() => _result = result);
        await SemanticsService.sendAnnouncement(
          View.of(context),
          result.label,
          Directionality.of(context),
        );
      }
    } catch (_) {
      if (mounted) {
        final message = AppStrings.of(context).liveHoursFailed;
        setState(() => _error = message);
        await SemanticsService.sendAnnouncement(
          View.of(context),
          message,
          Directionality.of(context),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.of(context).checkBeforeYouGo,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.of(context).liveHoursDescription(_period),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        if (result != null)
          Semantics(
            liveRegion: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.isOpen
                    ? colors.primaryContainer
                    : result.isClosed
                        ? colors.errorContainer
                        : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    result.isOpen
                        ? Icons.event_available_outlined
                        : result.isClosed
                            ? Icons.event_busy_outlined
                            : Icons.info_outline,
                    color: result.isOpen
                        ? colors.onPrimaryContainer
                        : result.isClosed
                            ? colors.onErrorContainer
                            : colors.onSurface,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(result.detail),
                        if (result.provider != null &&
                            result.placeName != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.of(context)
                                .matchedPlace(result.placeName!),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                        if (result.checkedAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.of(context)
                                .checkedAt(_checkedTime(result.checkedAt!)),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (result.placeUrl != null) ...[
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: () =>
                                widget.linkLauncher(result.placeUrl!),
                            style: const ButtonStyle(
                              minimumSize: WidgetStatePropertyAll(Size(0, 48)),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: Text(
                              result.provider == null
                                  ? AppStrings.of(context).openVenueSource
                                  : AppStrings.of(context).openProviderPlace,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_error != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: TextStyle(color: colors.error),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _loading ? null : _check,
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll(Size.fromHeight(48)),
            ),
            icon: _loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(result == null ? Icons.sync : Icons.refresh),
            label: Text(
              _loading
                  ? AppStrings.of(context).checkingLiveHours
                  : result == null
                      ? AppStrings.of(context).checkLiveHours
                      : AppStrings.of(context).checkAgain,
            ),
          ),
        ),
        if (result?.attributionLabel case final label?) ...[
          const SizedBox(height: 6),
          if (result?.attributionUrl case final attributionUrl?)
            TextButton(
              onPressed: () => widget.linkLauncher(attributionUrl),
              style: const ButtonStyle(
                minimumSize: WidgetStatePropertyAll(Size(0, 48)),
              ),
              child: Text(AppStrings.of(context).liveHoursBy(label)),
            )
          else
            Text(
              AppStrings.of(context).liveHoursBy(label),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ],
    );
  }

  String _checkedTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return AppStrings.of(context).isRomanian
        ? '${_dateLabel(context, local)}, $hour:$minute'
        : '${_dateLabel(context, local)} at $hour:$minute';
  }
}

class _DayPlan extends StatelessWidget {
  const _DayPlan({required this.recommendation, required this.forecast});

  final PlanRecommendation recommendation;
  final DailyForecast forecast;

  @override
  Widget build(BuildContext context) {
    const periods = ['morning', 'afternoon', 'evening'];
    final selectedPeriod = _preferredPeriod(recommendation);
    final selectedIndex = periods.indexOf(selectedPeriod);
    final entries = [
      (
        AppStrings.of(context).filterValue('morning'),
        recommendation.type == 'event' && selectedPeriod == 'morning'
            ? recommendation.title
            : forecast.rainProbability >= 50
                ? AppStrings.of(context).flexibleStart
                : AppStrings.of(context).coolStart
      ),
      (
        AppStrings.of(context).filterValue('afternoon'),
        recommendation.type == 'event' && selectedPeriod == 'afternoon'
            ? recommendation.title
            : recommendation.type == 'movie'
                ? AppStrings.of(context).beforeMovie
                : recommendation.title
      ),
      (
        AppStrings.of(context).filterValue('evening'),
        recommendation.type == 'event' && selectedPeriod == 'evening'
            ? recommendation.title
            : recommendation.type == 'movie'
                ? recommendation.title
                : AppStrings.of(context).indoorBackup
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.of(context).dayRhythm,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.of(context).dayRhythmSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < entries.length; index++)
          _TimelineEntry(
            label: entries[index].$1,
            text: entries[index].$2,
            highlighted: index == selectedIndex,
            showLine: index != entries.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.label,
    required this.text,
    required this.highlighted,
    required this.showLine,
  });

  final String label;
  final String text;
  final bool highlighted;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlighted
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                ),
                if (showLine)
                  Expanded(
                      child: Container(width: 2, color: colors.outlineVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              highlighted ? FontWeight.w700 : FontWeight.normal,
                          color: highlighted ? colors.primary : null,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.recommendation});

  final PlanRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final details = <(IconData, String, String)>[
      if (recommendation.distanceKm != null)
        (
          Icons.directions_walk_outlined,
          AppStrings.of(context).distance,
          AppStrings.of(context).distanceAway(recommendation.distanceKm!)
        ),
      if (recommendation.elevationM != null)
        (
          Icons.terrain_outlined,
          AppStrings.of(context).elevation,
          AppStrings.of(context).elevationValue(recommendation.elevationM!)
        ),
      if (recommendation.routeDistanceKm != null)
        (
          Icons.route_outlined,
          AppStrings.of(context).routeLength,
          AppStrings.of(context)
              .routeLengthValue(recommendation.routeDistanceKm!)
        ),
      if (recommendation.durationMinutes != null)
        (
          Icons.schedule_outlined,
          AppStrings.of(context).mappedDuration,
          AppStrings.of(context).durationValue(recommendation.durationMinutes!)
        ),
      if (recommendation.routeStart != null)
        (
          Icons.flag_outlined,
          AppStrings.of(context).routeStart,
          recommendation.routeStart!
        ),
      if (recommendation.routeEnd != null)
        (
          Icons.outlined_flag,
          AppStrings.of(context).routeEnd,
          recommendation.routeEnd!
        ),
      if (recommendation.difficulty != null)
        (
          Icons.hiking_outlined,
          AppStrings.of(context).trailDifficulty,
          AppStrings.of(context)
              .trailDifficultyValue(recommendation.difficulty!)
        ),
      if (recommendation.trailVisibility != null &&
          recommendation.trailVisibility != recommendation.difficulty)
        (
          Icons.visibility_outlined,
          AppStrings.of(context).trailVisibility,
          AppStrings.of(context)
              .trailVisibilityValue(recommendation.trailVisibility!)
        ),
      if (recommendation.surface != null)
        (
          Icons.landscape_outlined,
          AppStrings.of(context).surface,
          AppStrings.of(context).surfaceValue(recommendation.surface!)
        ),
      if (recommendation.openingHours != null)
        (
          Icons.schedule_outlined,
          AppStrings.of(context).listedHoursLabel,
          AppStrings.of(context).listedHours(recommendation.openingHours!)
        ),
      if (recommendation.availability != null)
        (
          recommendation.availability!.status == 'listed_open'
              ? Icons.event_available_outlined
              : Icons.info_outline,
          AppStrings.of(context).hoursGuidance,
          '${recommendation.availability!.label}. ${recommendation.availability!.disclaimer}'
        ),
      if (recommendation.recommendedPeriods.isNotEmpty)
        (
          Icons.schedule_outlined,
          AppStrings.of(context).bestTime,
          recommendation.recommendedPeriods
              .map(AppStrings.of(context).filterValue)
              .join(AppStrings.of(context).isRomanian ? ' sau ' : ' or ')
        ),
      if (recommendation.eventDate != null || recommendation.eventTime != null)
        (
          Icons.event_outlined,
          AppStrings.of(context).eventTime,
          [
            if (recommendation.eventDate != null)
              _dateLabel(context, recommendation.eventDate!),
            if (recommendation.eventTime != null)
              _shortTime(recommendation.eventTime!),
          ].join(' · ')
        ),
      if (recommendation.eventStatus != null)
        (
          Icons.confirmation_number_outlined,
          AppStrings.of(context).eventStatus,
          AppStrings.of(context).filterValue(recommendation.eventStatus!)
        ),
      if (recommendation.priceLabel != null)
        (
          Icons.payments_outlined,
          AppStrings.of(context).listedPrice,
          recommendation.priceLabel!
        ),
      if (recommendation.rating != null)
        (
          Icons.star_outline,
          'TMDB',
          '${recommendation.rating!.toStringAsFixed(1)}/10'
        ),
      if (recommendation.releaseDate != null)
        (
          Icons.calendar_today_outlined,
          AppStrings.of(context).released,
          recommendation.releaseDate!.year.toString()
        ),
      if (recommendation.genres.isNotEmpty)
        (
          Icons.category_outlined,
          AppStrings.of(context).genres,
          recommendation.genres
              .map(AppStrings.of(context).filterValue)
              .join(', ')
        ),
    ];
    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.of(context).usefulDetails,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final detail in details)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(detail.$1, size: 21),
                const SizedBox(width: 12),
                SizedBox(width: 92, child: Text(detail.$2)),
                Expanded(
                    child: Text(detail.$3,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.recommendation,
    required this.hasCoordinates,
    required this.linkLauncher,
  });

  final PlanRecommendation recommendation;
  final bool hasCoordinates;
  final ExternalLinkLauncher linkLauncher;

  @override
  Widget build(BuildContext context) {
    final sourceUri =
        recommendation.url == null ? null : Uri.tryParse(recommendation.url!);
    final officialUri = recommendation.officialUrl == null
        ? null
        : Uri.tryParse(recommendation.officialUrl!);
    final directionsUri = hasCoordinates
        ? Uri.https('www.openstreetmap.org', '/directions', {
            'from': '',
            'to': '${recommendation.latitude},${recommendation.longitude}',
          })
        : null;

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: [
        if (directionsUri != null)
          FilledButton.icon(
            onPressed: () => _open(context, directionsUri),
            icon: const Icon(Icons.directions_outlined),
            label: Text(AppStrings.of(context).openDirections),
          ),
        if (officialUri != null && officialUri != sourceUri)
          FilledButton.tonalIcon(
            onPressed: () => _open(context, officialUri),
            icon: const Icon(Icons.hiking_outlined),
            label: Text(AppStrings.of(context).officialTrailPage),
          ),
        if (sourceUri != null)
          OutlinedButton.icon(
            onPressed: () => _open(context, sourceUri),
            icon: Icon(recommendation.type == 'movie'
                ? Icons.open_in_new
                : Icons.info_outline),
            label: Text(
              AppStrings.of(context).sourceAction(recommendation.type),
            ),
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    if (await linkLauncher(uri) || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).linkOpenFailed)),
    );
  }
}

class _TmdbCredit extends StatelessWidget {
  const _TmdbCredit();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset('assets/tmdb_logo.svg',
            height: 24, semanticsLabel: 'The Movie Database'),
        const SizedBox(height: 7),
        Text(
          'This product uses the TMDB API but is not endorsed or certified by TMDB.',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _TicketmasterCredit extends StatelessWidget {
  const _TicketmasterCredit();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.confirmation_number_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppStrings.of(context).eventDataByTicketmaster,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

String _heroTag(PlanRecommendation item) =>
    'recommendation-${item.provider ?? 'local'}-${item.id}';

String _preferredPeriod(PlanRecommendation recommendation) {
  return recommendation.availability?.period ??
      (recommendation.recommendedPeriods.contains('afternoon')
          ? 'afternoon'
          : recommendation.recommendedPeriods.isNotEmpty
              ? recommendation.recommendedPeriods.first
              : recommendation.type == 'movie'
                  ? 'evening'
                  : 'afternoon');
}

String _dateLabel(BuildContext context, DateTime date) =>
    '${date.day} ${AppStrings.of(context).shortMonth(date)}';

String _shortTime(String value) =>
    value.length >= 5 ? value.substring(0, 5) : value;

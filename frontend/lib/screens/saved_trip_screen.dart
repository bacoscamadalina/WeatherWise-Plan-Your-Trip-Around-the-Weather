import 'package:flutter/material.dart';

import '../models/trip_plan.dart';
import '../services/trip_repository.dart';
import '../theme/atlas_theme.dart';
import '../widgets/trip_settings_sheet.dart';
import '../widgets/trip_day_strategy.dart';
import '../widgets/trip_day_availability.dart';
import '../widgets/trip_day_logistics.dart';
import '../widgets/trip_route_leg.dart';
import '../widgets/trip_period_weather.dart';

class SavedTripScreen extends StatefulWidget {
  const SavedTripScreen({
    required this.plan,
    required this.repository,
    super.key,
  });

  final TripPlan plan;
  final PersonalTripRepository repository;

  @override
  State<SavedTripScreen> createState() => _SavedTripScreenState();
}

class _SavedTripScreenState extends State<SavedTripScreen> {
  late TripPlan _plan = widget.plan;
  bool _replanning = false;
  int? _replacingItemId;

  bool get _romanian => Localizations.localeOf(context).languageCode == 'ro';
  bool get _busy => _replanning || _replacingItemId != null;

  Future<void> _confirmReplan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_romanian
            ? 'Replănuiești după vremea nouă?'
            : 'Replan for the latest weather?'),
        content: Text(_romanian
            ? 'Verificăm din nou prognoza și înlocuim opririle sugerate pentru fiecare zi. Planul actual rămâne vizibil dacă actualizarea nu reușește.'
            : 'We will refresh the forecast and replace the suggested stops for each day. Your current plan stays visible if the update fails.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_romanian ? 'Păstrează planul' : 'Keep this plan'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(_romanian ? 'Replănuiește' : 'Replan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _performReplan();
  }

  Future<void> _editTrip() async {
    final values = await showModalBottomSheet<TripEditValues>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AtlasColors.paper,
      constraints: const BoxConstraints(maxWidth: 840),
      builder: (context) {
        final viewport = MediaQuery.sizeOf(context);
        final height = viewport.width < 720
            ? viewport.height * .92
            : (viewport.height * .68).clamp(480.0, 560.0).toDouble();
        return SizedBox(
          height: height,
          child: TripSettingsSheet(
            plan: _plan,
            romanian: _romanian,
          ),
        );
      },
    );
    if (values == null || !mounted) return;
    await _performReplan(values);
  }

  Future<void> _performReplan([TripEditValues? values]) async {
    if (_busy) return;

    setState(() => _replanning = true);
    try {
      final updated = await widget.repository.replanTrip(
        _plan.id,
        startsOn: values?.startsOn,
        endsOn: values?.endsOn,
        arrivalTime: values?.arrivalTime,
        departureTime: values?.departureTime,
        partySize: values?.partySize,
        pace: values?.pace,
        transportMode: values?.transportMode,
        maxDistanceKm: values?.maxDistanceKm,
        preferences: values?.preferences,
      );
      if (!mounted) return;
      setState(() => _plan = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_romanian
              ? 'Planul a fost adaptat la cea mai nouă prognoză.'
              : 'Your plan was adapted to the latest forecast.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_romanian
              ? 'Nu am putut actualiza planul. Versiunea anterioară a fost păstrată.'
              : 'We could not update the plan. Your previous version was kept.'),
          action: SnackBarAction(
            label: _romanian ? 'Reîncearcă' : 'Retry',
            onPressed: () => _performReplan(values),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _replanning = false);
    }
  }

  Future<void> _replaceItem(TripPlanItem item) async {
    if (_busy) return;
    setState(() => _replacingItemId = item.id);
    try {
      final updated = await widget.repository.replaceItem(_plan.id, item.id);
      if (!mounted) return;
      setState(() => _plan = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_romanian
              ? 'Am găsit o alternativă potrivită și am păstrat restul planului.'
              : 'We found a suitable alternative and kept the rest of your plan.'),
        ),
      );
    } on TripRepositoryException catch (error) {
      if (!mounted) return;
      _showReplacementFailure(
        item,
        noAlternative: error.code == 'no_alternative',
      );
    } catch (_) {
      if (!mounted) return;
      _showReplacementFailure(item, noAlternative: false);
    } finally {
      if (mounted) setState(() => _replacingItemId = null);
    }
  }

  void _showReplacementFailure(
    TripPlanItem item, {
    required bool noAlternative,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(noAlternative
            ? (_romanian
                ? 'Nu am găsit acum o alternativă diferită. Oprirea actuală a fost păstrată.'
                : 'No different alternative is available right now. The current stop was kept.')
            : (_romanian
                ? 'Serviciul de recomandări nu răspunde momentan. Oprirea actuală a fost păstrată.'
                : 'The recommendation service is unavailable right now. The current stop was kept.')),
        action: SnackBarAction(
          label: _romanian ? 'Reîncearcă' : 'Retry',
          onPressed: () => _replaceItem(item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      appBar: AppBar(
        backgroundColor: AtlasColors.paper,
        surfaceTintColor: Colors.transparent,
        title: Text(_plan.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
        children: [
          Text(_plan.location.displayName,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            '${_plan.days.length} ${_dayCountLabel(_plan.days.length)} · '
            '${_romanian ? 'rază maximă de întoarcere' : 'maximum return radius'} '
            '${_plan.maxDistanceKm.round()} km',
            style: const TextStyle(color: AtlasColors.mutedInk),
          ),
          const SizedBox(height: 4),
          Text(
            _romanian
                ? '${_plan.rhythm.plannedActivityCount} activități/zi · ${_plan.rhythm.travelBufferMinutes} min între opriri'
                : '${_plan.rhythm.plannedActivityCount} activities/day · ${_plan.rhythm.travelBufferMinutes} min between stops',
            style: const TextStyle(color: AtlasColors.mutedInk),
          ),
          const SizedBox(height: 4),
          Text(
            '${_plan.partySize} ${_romanian ? (_plan.partySize == 1 ? 'călător' : 'călători') : (_plan.partySize == 1 ? 'traveler' : 'travelers')} · '
            '${_paceLabel(_plan.pace)} ${_plan.rhythm.dayStart}–${_plan.rhythm.dayEnd} · '
            '${_transportLabel(_plan.transportMode)}',
            style: const TextStyle(color: AtlasColors.mutedInk),
          ),
          if (_plan.arrivalTime != null || _plan.departureTime != null) ...[
            const SizedBox(height: 4),
            Text(
              _romanian
                  ? 'Sosire ${_plan.arrivalTime ?? '—'} · plecare ${_plan.departureTime ?? '—'}'
                  : 'Arrival ${_plan.arrivalTime ?? '—'} · departure ${_plan.departureTime ?? '—'}',
              style: const TextStyle(
                color: AtlasColors.mutedInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (!_plan.preferences.isDefault) ...[
            const SizedBox(height: 4),
            Text(
              _preferenceSummary(_plan.preferences),
              style: const TextStyle(color: AtlasColors.mutedInk),
            ),
          ],
          const SizedBox(height: 20),
          _ReplanPanel(
            romanian: _romanian,
            busy: _replanning,
            onPressed: _busy ? null : _confirmReplan,
            onEdit: _busy ? null : _editTrip,
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < _plan.days.length; index++)
            _SavedDay(
              day: _plan.days[index],
              rhythm: _plan.rhythm,
              index: index,
              romanian: _romanian,
              replacingItemId: _replacingItemId,
              onReplace: _busy ? null : _replaceItem,
            ),
        ],
      ),
    );
  }

  String _dayCountLabel(int count) {
    if (_romanian) return count == 1 ? 'zi' : 'zile';
    return count == 1 ? 'day' : 'days';
  }

  String _paceLabel(String pace) => switch (pace) {
        'relaxed' => _romanian ? 'ritm relaxat' : 'relaxed pace',
        'active' => _romanian ? 'ritm activ' : 'active pace',
        _ => _romanian ? 'ritm echilibrat' : 'balanced pace',
      };

  String _transportLabel(String mode) => switch (mode) {
        'walking' => _romanian ? 'pe jos' : 'walking',
        'public_transport' =>
          _romanian ? 'transport public' : 'public transport',
        'bicycle' => _romanian ? 'bicicletă' : 'bicycle',
        _ => _romanian ? 'mașină' : 'car',
      };

  String _preferenceSummary(TripPreferences preferences) {
    final labels = <String>[
      if (preferences.interests.isNotEmpty)
        preferences.interests.map(_interestLabel).join(', '),
      if (preferences.dietary.isNotEmpty)
        preferences.dietary.map(_dietaryLabel).join(', '),
      if (preferences.budget != 'flexible') _budgetLabel(preferences.budget),
    ];
    return labels.join(' · ');
  }

  String _interestLabel(String value) => switch (value) {
        'culture' => _romanian ? 'cultură' : 'culture',
        'nature' => _romanian ? 'natură' : 'nature',
        _ => _romanian ? 'divertisment' : 'entertainment',
      };

  String _dietaryLabel(String value) => switch (value) {
        'vegetarian' => 'vegetarian',
        'vegan' => 'vegan',
        _ => _romanian ? 'fără gluten' : 'gluten-free',
      };

  String _budgetLabel(String value) => value == 'value'
      ? (_romanian ? 'buget economic' : 'value budget')
      : (_romanian ? 'buget moderat' : 'moderate budget');
}

class _ReplanPanel extends StatelessWidget {
  const _ReplanPanel({
    required this.romanian,
    required this.busy,
    required this.onPressed,
    required this.onEdit,
  });

  final bool romanian;
  final bool busy;
  final VoidCallback? onPressed;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AtlasColors.sky,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.15;
              final message = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    romanian
                        ? 'Vremea se schimbă. Planul poate ține pasul.'
                        : 'Weather changes. Your plan can keep up.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    romanian
                        ? 'Reverificăm prognoza și alegem din nou activitățile și localurile potrivite.'
                        : 'Refresh the forecast and choose suitable activities and venues again.',
                    style: const TextStyle(color: AtlasColors.mutedInk),
                  ),
                ],
              );
              final action = SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: onPressed,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(busy
                      ? (romanian ? 'Adaptăm planul…' : 'Adapting plan…')
                      : (romanian
                          ? 'Actualizează după vreme'
                          : 'Update for weather')),
                ),
              );
              final editAction = SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const ValueKey('edit-trip-details'),
                  onPressed: onEdit,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(romanian ? 'Modifică detaliile' : 'Edit details'),
                ),
              );
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    message,
                    const SizedBox(height: 16),
                    action,
                    const SizedBox(height: 10),
                    editAction,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: message),
                  const SizedBox(width: 24),
                  editAction,
                  const SizedBox(width: 10),
                  action,
                ],
              );
            },
          ),
        ),
      );
}

class _SavedDay extends StatelessWidget {
  const _SavedDay({
    required this.day,
    required this.rhythm,
    required this.index,
    required this.romanian,
    required this.replacingItemId,
    required this.onReplace,
  });

  final TripPlanDay day;
  final TripRhythm rhythm;
  final int index;
  final bool romanian;
  final int? replacingItemId;
  final ValueChanged<TripPlanItem>? onReplace;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${romanian ? 'Ziua' : 'Day'} ${index + 1} · ${day.date.day}.${day.date.month}.${day.date.year}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (day.summary != null) ...[
                const SizedBox(height: 10),
                TripDayStrategy(summary: day.summary!, romanian: romanian),
              ],
              if ((day.availableFrom != null &&
                      day.availableFrom != rhythm.dayStart) ||
                  (day.availableUntil != null &&
                      day.availableUntil != rhythm.dayEnd)) ...[
                const SizedBox(height: 12),
                TripDayAvailability(
                  from: day.availableFrom ?? rhythm.dayStart,
                  until: day.availableUntil ?? rhythm.dayEnd,
                  romanian: romanian,
                  afterArrival: day.availableFrom != null &&
                      day.availableFrom != rhythm.dayStart,
                  beforeDeparture: day.availableUntil != null &&
                      day.availableUntil != rhythm.dayEnd,
                ),
              ],
              if (day.logistics.plannedStops > 0) ...[
                const SizedBox(height: 12),
                TripDayLogisticsBand(
                  logistics: day.logistics,
                  romanian: romanian,
                ),
              ],
              const SizedBox(height: 14),
              for (final item in day.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 78,
                            child: Text(
                              item.endsAt == null
                                  ? (item.startsAt ?? '')
                                  : '${item.startsAt ?? ''}\n${item.endsAt}',
                              style: const TextStyle(
                                color: AtlasColors.mutedInk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(_icon(item), size: 20, color: AtlasColors.azure),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TripPeriodWeather(
                                  item: item,
                                  romanian: romanian,
                                ),
                                TripRouteLeg(item: item, romanian: romanian),
                                Text(item.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                if (item.summary != null)
                                  Text(item.summary!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                if (item.provider != null)
                                  Text(
                                    '${romanian ? 'Sursă' : 'Source'}: ${item.provider!.replaceAll('_', ' ')}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                if (item.metadata['duration_minutes'] != null)
                                  Text(
                                    _durationLabel(item),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AtlasColors.mutedInk,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: SizedBox(
                                    height: 48,
                                    child: TextButton.icon(
                                      key: ValueKey(
                                        'replace-trip-item-${item.id}',
                                      ),
                                      onPressed: onReplace == null
                                          ? null
                                          : () => onReplace!(item),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AtlasColors.ink,
                                      ),
                                      icon: replacingItemId == item.id
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.swap_horiz_rounded,
                                            ),
                                      label: Text(
                                        replacingItemId == item.id
                                            ? (romanian
                                                ? 'Căutăm alternativa…'
                                                : 'Finding alternative…')
                                            : (romanian
                                                ? 'Schimbă oprirea'
                                                : 'Replace stop'),
                                      ),
                                    ),
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
            ],
          ),
        ),
      );

  IconData _icon(TripPlanItem item) => switch (item.slot) {
        'breakfast' => Icons.coffee_outlined,
        'lunch' || 'dinner' => Icons.restaurant_outlined,
        'evening' => Icons.nightlife_outlined,
        _ => Icons.explore_outlined,
      };

  String _durationLabel(TripPlanItem item) {
    final duration = (item.metadata['duration_minutes'] as num).round();
    return romanian ? 'durată estimată $duration min' : 'about $duration min';
  }
}

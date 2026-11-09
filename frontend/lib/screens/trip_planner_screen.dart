import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../models/location.dart';
import '../models/trip_plan.dart';
import '../services/trip_repository.dart';
import '../theme/atlas_theme.dart';
import '../widgets/trip_preferences_fields.dart';
import '../widgets/trip_day_strategy.dart';
import '../widgets/trip_day_availability.dart';
import '../widgets/trip_day_logistics.dart';
import '../widgets/trip_route_leg.dart';
import '../widgets/trip_period_weather.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({
    required this.location,
    required this.repository,
    super.key,
  });

  final Location location;
  final TripRepository repository;

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  late DateTime _startsOn;
  late DateTime _endsOn;
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _departureTime = const TimeOfDay(hour: 18, minute: 0);
  String _pace = 'balanced';
  String _transportMode = 'car';
  int _partySize = 1;
  double _maxDistanceKm = 50;
  String _budget = 'flexible';
  final Set<String> _dietary = {};
  final Set<String> _interests = {};
  bool _loading = false;
  String? _error;
  TripPlan? _plan;

  bool get _romanian => AppStrings.of(context).isRomanian;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _startsOn = today;
    _endsOn = today.add(const Duration(days: 2));
  }

  Future<void> _chooseDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final result = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 13)),
      initialDateRange: DateTimeRange(start: _startsOn, end: _endsOn),
      helpText: _romanian ? 'Alege perioada călătoriei' : 'Choose trip dates',
      saveText: _romanian ? 'Folosește perioada' : 'Use dates',
    );
    if (result == null) return;
    setState(() {
      _startsOn = result.start;
      _endsOn = result.end;
      _plan = null;
    });
  }

  Future<void> _createPlan() async {
    if (_startsOn == _endsOn &&
        _clockMinutes(_arrivalTime) >= _clockMinutes(_departureTime)) {
      setState(() {
        _error = _romanian
            ? 'Pentru o călătorie de o zi, plecarea trebuie să fie după sosire.'
            : 'For a one-day trip, departure must be after arrival.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final plan = await widget.repository.createTrip(
        location: widget.location,
        startsOn: _startsOn,
        endsOn: _endsOn,
        arrivalTime: _clock(_arrivalTime),
        departureTime: _clock(_departureTime),
        pace: _pace,
        transportMode: _transportMode,
        maxDistanceKm: _maxDistanceKm,
        partySize: _partySize,
        preferences: TripPreferences(
          budget: _budget,
          dietary: _dietary.toList(growable: false),
          interests: _interests.toList(growable: false),
        ),
      );
      if (!mounted) return;
      setState(() => _plan = plan);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _romanian
            ? 'Planul nu a putut fi creat. ${error.toString()}'
            : 'The plan could not be created. ${error.toString()}';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.ivory,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AtlasColors.paper,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text(
              'WeatherWise',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontWeight: FontWeight.w700,
                color: AtlasColors.ink,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _plannerForm()),
          if (_error != null) SliverToBoxAdapter(child: _errorPanel()),
          if (_plan != null) ...[
            SliverToBoxAdapter(child: _planHeader(_plan!)),
            SliverList.builder(
              itemCount: _plan!.days.length,
              itemBuilder: (context, index) => _daySection(
                _plan!.days[index],
                index,
                _plan!.days.length,
                _plan!,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AtlasColors.ivory, AtlasColors.paleGold, AtlasColors.sky],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 38, 20, 42),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final text = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _romanian
                          ? 'Călătoria ta, în ritmul vremii.'
                          : 'Your trip, paced by the weather.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontSize: wide ? 46 : 36,
                            height: 1.05,
                            letterSpacing: -1.2,
                          ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 650),
                      child: Text(
                        _romanian
                            ? 'Alege perioada. WeatherWise combină prognoza, locurile, evenimentele și mesele într-un traseu zilnic care se întoarce la ${widget.location.name}.'
                            : 'Choose your dates. WeatherWise combines forecasts, places, events and meals into a daily route that returns to ${widget.location.name}.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AtlasColors.mutedInk,
                              fontSize: 17,
                            ),
                      ),
                    ),
                  ],
                );
                final location = _LocationStamp(location: widget.location);
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [text, const SizedBox(height: 24), location],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: 36),
                    location
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _plannerForm() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AtlasColors.paper,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1C5E6D65),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1040;
                  final controls = [
                    _dateControl(),
                    _travelWindowControl(),
                    _partyControl(),
                    _paceControl(),
                    _transportControl(),
                    _distanceControl(),
                  ];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: controls
                              .map((item) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 14),
                                      child: item,
                                    ),
                                  ))
                              .toList(),
                        )
                      else
                        ...controls.expand(
                          (item) => [item, const SizedBox(height: 18)],
                        ),
                      const Divider(height: 34),
                      TripPreferencesFields(
                        romanian: _romanian,
                        enabled: !_loading,
                        budget: _budget,
                        dietary: _dietary,
                        interests: _interests,
                        onBudgetChanged: (value) => _changePreference(
                          () => _budget = value,
                        ),
                        onDietaryChanged: (value, selected) =>
                            _changePreference(() {
                          selected
                              ? _dietary.add(value)
                              : _dietary.remove(value);
                        }),
                        onInterestChanged: (value, selected) =>
                            _changePreference(() {
                          selected
                              ? _interests.add(value)
                              : _interests.remove(value);
                        }),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _createPlan,
                          icon: _loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.route_rounded),
                          label: Text(
                            _loading
                                ? (_romanian
                                    ? 'Construim traseul…'
                                    : 'Building your route…')
                                : (_romanian
                                    ? 'Construiește planul'
                                    : 'Build my plan'),
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changePreference(VoidCallback change) => setState(() {
        change();
        _plan = null;
        _error = null;
      });

  Widget _dateControl() => _FormField(
        icon: Icons.calendar_month_outlined,
        label: _romanian ? 'Perioada' : 'Dates',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _loading ? null : _chooseDates,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '${_shortDate(_startsOn)} — ${_shortDate(_endsOn)}\n'
              '${_endsOn.difference(_startsOn).inDays + 1} ${_romanian ? 'zile' : 'days'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );

  Widget _partyControl() => _FormField(
        icon: Icons.group_outlined,
        label: _romanian ? 'Călători' : 'Travelers',
        child: DropdownButtonFormField<int>(
          key: const ValueKey('trip-create-party-size'),
          initialValue: _partySize,
          decoration: const InputDecoration(isDense: true),
          items: List.generate(
            20,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: Text('${index + 1}'),
            ),
          ),
          onChanged: _loading
              ? null
              : (value) => setState(() {
                    _partySize = value!;
                    _plan = null;
                    _error = null;
                  }),
        ),
      );

  Widget _travelWindowControl() => _FormField(
        icon: Icons.flight_land_rounded,
        label: _romanian ? 'Sosire și plecare' : 'Arrival and departure',
        child: Row(
          children: [
            Expanded(
              child: _TimeButton(
                key: const ValueKey('trip-arrival-time'),
                label: _romanian ? 'Sosire' : 'Arrival',
                value: MaterialLocalizations.of(context)
                    .formatTimeOfDay(_arrivalTime),
                onTap: _loading ? null : () => _chooseTime(arrival: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TimeButton(
                key: const ValueKey('trip-departure-time'),
                label: _romanian ? 'Plecare' : 'Departure',
                value: MaterialLocalizations.of(context)
                    .formatTimeOfDay(_departureTime),
                onTap: _loading ? null : () => _chooseTime(arrival: false),
              ),
            ),
          ],
        ),
      );

  Future<void> _chooseTime({required bool arrival}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: arrival ? _arrivalTime : _departureTime,
      helpText: arrival
          ? (_romanian ? 'Ora sosirii' : 'Arrival time')
          : (_romanian ? 'Ora plecării' : 'Departure time'),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (arrival) {
        _arrivalTime = selected;
      } else {
        _departureTime = selected;
      }
      _plan = null;
      _error = null;
    });
  }

  int _clockMinutes(TimeOfDay value) => (value.hour * 60) + value.minute;

  String _clock(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Widget _paceControl() => _FormField(
        icon: Icons.speed_rounded,
        label: _romanian ? 'Ritmul zilelor' : 'Daily pace',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _pace,
              decoration: const InputDecoration(isDense: true),
              items: [
                DropdownMenuItem(
                    value: 'relaxed',
                    child: Text(_romanian ? 'Relaxat' : 'Relaxed')),
                DropdownMenuItem(
                    value: 'balanced',
                    child: Text(_romanian ? 'Echilibrat' : 'Balanced')),
                DropdownMenuItem(
                    value: 'active',
                    child: Text(_romanian ? 'Activ' : 'Active')),
              ],
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                        _pace = value!;
                        _plan = null;
                        _error = null;
                      }),
            ),
            const SizedBox(height: 7),
            Text(
              _paceDescription(_pace),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AtlasColors.mutedInk,
                    height: 1.3,
                  ),
            ),
          ],
        ),
      );

  String _paceDescription(String pace) => switch (pace) {
        'relaxed' => _romanian
            ? '09:00–22:00 · 2 activități și seară liberă'
            : '09:00–22:00 · 2 activities and a free evening',
        'active' => _romanian
            ? '07:30–22:30 · 3 activități și pauze scurte'
            : '07:30–22:30 · 3 activities and shorter pauses',
        _ => _romanian
            ? '08:30–22:30 · 3 activități și pauze confortabile'
            : '08:30–22:30 · 3 activities and comfortable pauses',
      };

  Widget _transportControl() => _FormField(
        icon: Icons.directions_car_outlined,
        label: _romanian ? 'Transport' : 'Transport',
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _transportMode,
          decoration: const InputDecoration(isDense: true),
          items: [
            DropdownMenuItem(
                value: 'car', child: Text(_romanian ? 'Mașină' : 'Car')),
            DropdownMenuItem(
                value: 'public_transport',
                child:
                    Text(_romanian ? 'Transport public' : 'Public transport')),
            DropdownMenuItem(
                value: 'walking',
                child: Text(_romanian ? 'Pe jos' : 'Walking')),
            DropdownMenuItem(
                value: 'bicycle',
                child: Text(_romanian ? 'Bicicletă' : 'Bicycle')),
          ],
          onChanged: _loading
              ? null
              : (value) => setState(() {
                    _transportMode = value!;
                    _plan = null;
                    _error = null;
                  }),
        ),
      );

  Widget _distanceControl() => _FormField(
        icon: Icons.radar_rounded,
        label: _romanian ? 'Raza de explorare' : 'Exploration radius',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_maxDistanceKm.round()} km',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Slider(
              value: _maxDistanceKm,
              min: 5,
              max: 50,
              divisions: 9,
              label: '${_maxDistanceKm.round()} km',
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                        _maxDistanceKm = value;
                        _plan = null;
                        _error = null;
                      }),
            ),
          ],
        ),
      );

  Widget _errorPanel() => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_error!)),
                    TextButton(
                        onPressed: _createPlan,
                        child: Text(_romanian ? 'Reîncearcă' : 'Retry')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _planHeader(TripPlan plan) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 34, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.name,
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 6),
                          Text(
                            _romanian
                                ? '${plan.days.length} zile · ${plan.partySize} ${plan.partySize == 1 ? 'călător' : 'călători'} · toate opririle în maximum ${plan.maxDistanceKm.round()} km'
                                : '${plan.days.length} days · ${plan.partySize} ${plan.partySize == 1 ? 'traveler' : 'travelers'} · every stop within ${plan.maxDistanceKm.round()} km',
                            style: const TextStyle(color: AtlasColors.mutedInk),
                          ),
                          if (plan.arrivalTime != null ||
                              plan.departureTime != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              _romanian
                                  ? 'Sosire ${plan.arrivalTime ?? '—'} · plecare ${plan.departureTime ?? '—'}'
                                  : 'Arrival ${plan.arrivalTime ?? '—'} · departure ${plan.departureTime ?? '—'}',
                              style: const TextStyle(
                                color: AtlasColors.mutedInk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.auto_awesome_outlined,
                        color: AtlasColors.azure),
                  ],
                ),
                const SizedBox(height: 16),
                _RhythmBand(rhythm: plan.rhythm, romanian: _romanian),
              ],
            ),
          ),
        ),
      );

  Widget _daySection(
    TripPlanDay day,
    int index,
    int count,
    TripPlan plan,
  ) =>
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AtlasColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AtlasColors.line),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${_romanian ? 'Ziua' : 'Day'} ${index + 1}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _longDate(day.date),
                          style: const TextStyle(color: AtlasColors.mutedInk),
                        ),
                        _WeatherChip(day: day),
                      ],
                    ),
                    if (day.summary != null) ...[
                      const SizedBox(height: 12),
                      TripDayStrategy(
                        summary: day.summary!,
                        romanian: _romanian,
                      ),
                    ],
                    if ((day.availableFrom != null &&
                            day.availableFrom != plan.rhythm.dayStart) ||
                        (day.availableUntil != null &&
                            day.availableUntil != plan.rhythm.dayEnd)) ...[
                      const SizedBox(height: 12),
                      TripDayAvailability(
                        from: day.availableFrom ?? plan.rhythm.dayStart,
                        until: day.availableUntil ?? plan.rhythm.dayEnd,
                        romanian: _romanian,
                        afterArrival: day.availableFrom != null &&
                            day.availableFrom != plan.rhythm.dayStart,
                        beforeDeparture: day.availableUntil != null &&
                            day.availableUntil != plan.rhythm.dayEnd,
                      ),
                    ],
                    if (day.logistics.plannedStops > 0) ...[
                      const SizedBox(height: 12),
                      TripDayLogisticsBand(
                        logistics: day.logistics,
                        romanian: _romanian,
                      ),
                    ],
                    const SizedBox(height: 12),
                    ...day.items.map(_timelineItem),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _timelineItem(TripPlanItem item) {
    final unavailable = !item.available;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                item.endsAt == null
                    ? (item.startsAt ?? '')
                    : '${item.startsAt ?? ''}\n${item.endsAt}',
                style: const TextStyle(
                  color: AtlasColors.mutedInk,
                  fontFeatures: [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _slotColor(item).withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Icon(_slotIcon(item), size: 19, color: _slotColor(item)),
              ),
              Container(width: 1, height: 56, color: AtlasColors.line),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: item.url == null
                  ? null
                  : () => launchUrl(Uri.parse(item.url!)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 7, 4, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _slotLabel(item.slot),
                      style: TextStyle(
                        color: unavailable
                            ? AtlasColors.mutedInk
                            : _slotColor(item),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TripPeriodWeather(item: item, romanian: _romanian),
                    TripRouteLeg(item: item, romanian: _romanian),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: unavailable
                                ? AtlasColors.mutedInk
                                : AtlasColors.ink,
                          ),
                    ),
                    if (item.summary != null) ...[
                      const SizedBox(height: 4),
                      Text(item.summary!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    if (item.provider != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${_romanian ? 'Sursă' : 'Source'}: ${_providerLabel(item.provider!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AtlasColors.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                    if (item.rating != null || item.distanceKm != null) ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (item.rating != null)
                            Semantics(
                              label: _romanian
                                  ? 'Evaluare ${item.rating!.toStringAsFixed(1)} din 5, ${item.ratingCount ?? 0} recenzii'
                                  : 'Rating ${item.rating!.toStringAsFixed(1)} out of 5, ${item.ratingCount ?? 0} reviews',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 17,
                                    color: Color(0xFFB97500),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.rating!.toStringAsFixed(1)} (${item.ratingCount ?? 0})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.distanceKm != null)
                            Text(
                              '${item.distanceKm!.toStringAsFixed(1)} km',
                              style:
                                  const TextStyle(color: AtlasColors.mutedInk),
                            ),
                        ],
                      ),
                    ],
                    if (item.metadata['duration_minutes'] != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        _timingDetails(item),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AtlasColors.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timingDetails(TripPlanItem item) {
    final duration = (item.metadata['duration_minutes'] as num?)?.round();
    final details = <String>[
      if (duration != null)
        _romanian ? 'durată estimată $duration min' : 'about $duration min',
    ];
    return details.join(' · ');
  }

  String _providerLabel(String provider) => switch (provider) {
        'google_places' => 'Google Places',
        'ticketmaster' => 'Ticketmaster',
        'wikipedia' => 'Wikipedia',
        'overpass' || 'openstreetmap' => 'OpenStreetMap',
        _ => provider
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' '),
      };

  IconData _slotIcon(TripPlanItem item) => switch (item.slot) {
        'breakfast' => Icons.coffee_outlined,
        'lunch' || 'dinner' => Icons.restaurant_outlined,
        'evening' => Icons.nightlife_outlined,
        _ => item.kind == 'free_time'
            ? Icons.more_time_rounded
            : Icons.explore_outlined,
      };

  Color _slotColor(TripPlanItem item) {
    if (!item.available) return AtlasColors.cloud;
    if (item.kind == 'meal') return AtlasColors.coral;
    if (item.kind == 'event') return AtlasColors.azure;
    return AtlasColors.teal;
  }

  String _slotLabel(String slot) {
    const ro = {
      'breakfast': 'MIC DEJUN',
      'morning': 'DIMINEAȚĂ',
      'lunch': 'PRÂNZ',
      'afternoon': 'DUPĂ-AMIAZĂ',
      'dinner': 'CINĂ',
      'evening': 'SEARĂ',
    };
    const en = {
      'breakfast': 'BREAKFAST',
      'morning': 'MORNING',
      'lunch': 'LUNCH',
      'afternoon': 'AFTERNOON',
      'dinner': 'DINNER',
      'evening': 'EVENING',
    };
    return (_romanian ? ro : en)[slot] ?? slot.toUpperCase();
  }

  String _shortDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  String _longDate(DateTime date) {
    const roMonths = [
      'ianuarie',
      'februarie',
      'martie',
      'aprilie',
      'mai',
      'iunie',
      'iulie',
      'august',
      'septembrie',
      'octombrie',
      'noiembrie',
      'decembrie'
    ];
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final months = _romanian ? roMonths : enMonths;
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _FormField extends StatelessWidget {
  const _FormField(
      {required this.icon, required this.label, required this.child});

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AtlasColors.azure),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      );
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$label $value',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AtlasColors.ivory,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AtlasColors.line),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AtlasColors.mutedInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _LocationStamp extends StatelessWidget {
  const _LocationStamp({required this.location});

  final Location location;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 310),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AtlasColors.paper.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, color: AtlasColors.azure),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                location.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.day});

  final TripPlanDay day;

  @override
  Widget build(BuildContext context) {
    final rain = (day.weather['rain_probability'] as num?)?.round();
    final icon = switch (day.weatherClass) {
      'clear' => Icons.wb_sunny_outlined,
      'rain' || 'storm' => Icons.water_drop_outlined,
      'snow' => Icons.ac_unit_rounded,
      _ => Icons.cloud_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AtlasColors.sky,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AtlasColors.azure),
          if (rain != null) ...[
            const SizedBox(width: 6),
            Text('$rain%', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ],
      ),
    );
  }
}

class _RhythmBand extends StatelessWidget {
  const _RhythmBand({required this.rhythm, required this.romanian});

  final TripRhythm rhythm;
  final bool romanian;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: romanian
            ? 'Program ${rhythm.label}, de la ${rhythm.dayStart} la ${rhythm.dayEnd}'
            : '${rhythm.label} schedule, ${rhythm.dayStart} to ${rhythm.dayEnd}',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AtlasColors.sky,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2;
                final heading = Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AtlasColors.azure),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '${rhythm.label} · ${rhythm.dayStart}–${rhythm.dayEnd}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                );
                final facts = Text(
                  romanian
                      ? '${rhythm.plannedActivityCount} activități · ${rhythm.travelBufferMinutes} min între opriri'
                      : '${rhythm.plannedActivityCount} activities · ${rhythm.travelBufferMinutes} min between stops',
                  style: const TextStyle(
                    color: AtlasColors.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                );
                final description = Text(
                  rhythm.description,
                  style: const TextStyle(color: AtlasColors.mutedInk),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      const SizedBox(height: 8),
                      facts,
                      const SizedBox(height: 5),
                      description,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(flex: 3, child: heading),
                    const SizedBox(width: 18),
                    Expanded(flex: 3, child: facts),
                    const SizedBox(width: 18),
                    Expanded(flex: 4, child: description),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

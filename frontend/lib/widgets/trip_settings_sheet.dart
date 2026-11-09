import 'package:flutter/material.dart';

import '../models/trip_plan.dart';
import '../theme/atlas_theme.dart';
import 'trip_preferences_fields.dart';

class TripEditValues {
  const TripEditValues({
    required this.startsOn,
    required this.endsOn,
    required this.arrivalTime,
    required this.departureTime,
    required this.partySize,
    required this.pace,
    required this.transportMode,
    required this.maxDistanceKm,
    required this.preferences,
  });

  final DateTime startsOn;
  final DateTime endsOn;
  final String arrivalTime;
  final String departureTime;
  final int partySize;
  final String pace;
  final String transportMode;
  final double maxDistanceKm;
  final TripPreferences preferences;
}

class TripSettingsSheet extends StatefulWidget {
  const TripSettingsSheet({
    required this.plan,
    required this.romanian,
    super.key,
  });

  final TripPlan plan;
  final bool romanian;

  @override
  State<TripSettingsSheet> createState() => _TripSettingsSheetState();
}

class _TripSettingsSheetState extends State<TripSettingsSheet> {
  late DateTime _startsOn;
  late DateTime _endsOn;
  late TimeOfDay _arrivalTime = _parseTime(widget.plan.arrivalTime, 12);
  late TimeOfDay _departureTime = _parseTime(widget.plan.departureTime, 18);
  late int _partySize = widget.plan.partySize;
  late String _pace = widget.plan.pace;
  late String _transportMode = widget.plan.transportMode;
  late double _maxDistanceKm =
      widget.plan.maxDistanceKm.clamp(5, 50).toDouble();
  late String _budget = widget.plan.preferences.budget;
  late final Set<String> _dietary = widget.plan.preferences.dietary.toSet();
  late final Set<String> _interests = widget.plan.preferences.interests.toSet();
  String? _windowError;

  bool get _romanian => widget.romanian;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    final lastDate = today.add(const Duration(days: 13));
    final originalDays = widget.plan.endsOn
        .difference(widget.plan.startsOn)
        .inDays
        .clamp(0, 13)
        .toInt();
    _startsOn = widget.plan.startsOn.isBefore(today) ||
            widget.plan.startsOn.isAfter(lastDate)
        ? today
        : DateUtils.dateOnly(widget.plan.startsOn);
    final preferredEnd = _startsOn.add(Duration(days: originalDays));
    _endsOn = preferredEnd.isAfter(lastDate) ? lastDate : preferredEnd;
  }

  Future<void> _chooseDates() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final result = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 13)),
      initialDateRange: DateTimeRange(start: _startsOn, end: _endsOn),
      helpText: _romanian ? 'Alege noua perioadă' : 'Choose new dates',
      saveText: _romanian ? 'Folosește perioada' : 'Use dates',
    );
    if (result == null || !mounted) return;
    setState(() {
      _startsOn = result.start;
      _endsOn = result.end;
    });
  }

  void _submit() {
    if (_startsOn == _endsOn &&
        _minutes(_arrivalTime) >= _minutes(_departureTime)) {
      setState(() {
        _windowError = _romanian
            ? 'Plecarea trebuie să fie după sosire.'
            : 'Departure must be after arrival.';
      });
      return;
    }
    Navigator.of(context).pop(
      TripEditValues(
        startsOn: _startsOn,
        endsOn: _endsOn,
        arrivalTime: _clock(_arrivalTime),
        departureTime: _clock(_departureTime),
        partySize: _partySize,
        pace: _pace,
        transportMode: _transportMode,
        maxDistanceKm: _maxDistanceKm,
        preferences: TripPreferences(
          budget: _budget,
          dietary: _dietary.toList(growable: false),
          interests: _interests.toList(growable: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _romanian ? 'Detaliile călătoriei' : 'Trip details',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  tooltip: _romanian ? 'Închide' : 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _romanian
                  ? 'Salvarea verifică din nou vremea și reconstruiește toate opririle sugerate. Planul actual rămâne neschimbat dacă actualizarea eșuează.'
                  : 'Saving refreshes the weather and rebuilds every suggested stop. Your current plan stays unchanged if the update fails.',
              style: const TextStyle(color: AtlasColors.mutedInk),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final fields = <Widget>[
                  _datesField(),
                  _travelWindowField(),
                  _partyField(),
                  _paceField(),
                  _transportField(),
                ];
                if (constraints.maxWidth < 720) {
                  return Column(
                    children: fields
                        .expand((field) => [field, const SizedBox(height: 18)])
                        .toList(),
                  );
                }
                return Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: fields
                      .map((field) => SizedBox(
                            width: (constraints.maxWidth - 18) / 2,
                            child: field,
                          ))
                      .toList(),
                );
              },
            ),
            _distanceField(),
            const Divider(height: 32),
            TripPreferencesFields(
              romanian: _romanian,
              budget: _budget,
              dietary: _dietary,
              interests: _interests,
              onBudgetChanged: (value) => setState(() => _budget = value),
              onDietaryChanged: (value, selected) => setState(() {
                selected ? _dietary.add(value) : _dietary.remove(value);
              }),
              onInterestChanged: (value, selected) => setState(() {
                selected ? _interests.add(value) : _interests.remove(value);
              }),
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const ValueKey('save-and-replan-trip'),
                onPressed: _submit,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(
                    _romanian ? 'Salvează și replănuiește' : 'Save and replan'),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      );

  Widget _travelWindowField() => _SettingField(
        icon: Icons.flight_land_rounded,
        label: _romanian ? 'Sosire și plecare' : 'Arrival and departure',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _TimeSettingButton(
                    key: const ValueKey('edit-trip-arrival-time'),
                    label: _romanian ? 'Sosire' : 'Arrival',
                    value: MaterialLocalizations.of(context)
                        .formatTimeOfDay(_arrivalTime),
                    onTap: () => _chooseTime(arrival: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeSettingButton(
                    key: const ValueKey('edit-trip-departure-time'),
                    label: _romanian ? 'Plecare' : 'Departure',
                    value: MaterialLocalizations.of(context)
                        .formatTimeOfDay(_departureTime),
                    onTap: () => _chooseTime(arrival: false),
                  ),
                ),
              ],
            ),
            if (_windowError != null) ...[
              const SizedBox(height: 6),
              Text(
                _windowError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      );

  Future<void> _chooseTime({required bool arrival}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: arrival ? _arrivalTime : _departureTime,
      helpText: arrival
          ? (_romanian ? 'Ora sosirii' : 'Arrival time')
          : (_romanian ? 'Ora plecării' : 'Departure time'),
    );
    if (value == null || !mounted) return;
    setState(() {
      if (arrival) {
        _arrivalTime = value;
      } else {
        _departureTime = value;
      }
      _windowError = null;
    });
  }

  Widget _datesField() => _SettingField(
        icon: Icons.calendar_month_outlined,
        label: _romanian ? 'Perioada' : 'Dates',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _chooseDates,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                // Date ranges are deliberately short (the forecast window),
                // so a direct singular/plural label stays clearer than an
                // abbreviated unit.
                '${_date(_startsOn)} — ${_date(_endsOn)} · '
                '$_dayCount ${_dayCountLabel(_dayCount)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      );

  int get _dayCount => _endsOn.difference(_startsOn).inDays + 1;

  String _dayCountLabel(int count) {
    if (_romanian) return count == 1 ? 'zi' : 'zile';
    return count == 1 ? 'day' : 'days';
  }

  Widget _partyField() => _SettingField(
        icon: Icons.group_outlined,
        label: _romanian ? 'Călători' : 'Travelers',
        child: DropdownButtonFormField<int>(
          key: const ValueKey('trip-party-size'),
          initialValue: _partySize,
          decoration: const InputDecoration(isDense: true),
          items: List.generate(
            20,
            (index) => DropdownMenuItem(
              value: index + 1,
              child: Text('${index + 1}'),
            ),
          ),
          onChanged: (value) => setState(() => _partySize = value!),
        ),
      );

  Widget _paceField() => _SettingField(
        icon: Icons.speed_rounded,
        label: _romanian ? 'Ritmul zilelor' : 'Daily pace',
        child: DropdownButtonFormField<String>(
          key: const ValueKey('trip-pace'),
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
                value: 'active', child: Text(_romanian ? 'Activ' : 'Active')),
          ],
          onChanged: (value) => setState(() => _pace = value!),
        ),
      );

  Widget _transportField() => _SettingField(
        icon: Icons.directions_car_outlined,
        label: _romanian ? 'Transport' : 'Transport',
        child: DropdownButtonFormField<String>(
          key: const ValueKey('trip-transport'),
          initialValue: _transportMode,
          decoration: const InputDecoration(isDense: true),
          items: [
            DropdownMenuItem(
                value: 'car', child: Text(_romanian ? 'Mașină' : 'Car')),
            DropdownMenuItem(
              value: 'public_transport',
              child: Text(_romanian ? 'Transport public' : 'Public transport'),
            ),
            DropdownMenuItem(
                value: 'walking',
                child: Text(_romanian ? 'Pe jos' : 'Walking')),
            DropdownMenuItem(
                value: 'bicycle',
                child: Text(_romanian ? 'Bicicletă' : 'Bicycle')),
          ],
          onChanged: (value) => setState(() => _transportMode = value!),
        ),
      );

  Widget _distanceField() => _SettingField(
        icon: Icons.radar_rounded,
        label:
            _romanian ? 'Raza maximă de întoarcere' : 'Maximum return radius',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_maxDistanceKm.round()} km',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Slider(
              key: const ValueKey('trip-distance'),
              value: _maxDistanceKm,
              min: 5,
              max: 50,
              divisions: 9,
              label: '${_maxDistanceKm.round()} km',
              onChanged: (value) => setState(() => _maxDistanceKm = value),
            ),
          ],
        ),
      );

  String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';

  String _clock(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  int _minutes(TimeOfDay value) => (value.hour * 60) + value.minute;

  static TimeOfDay _parseTime(String? value, int fallbackHour) {
    final parts = value?.split(':');
    if (parts?.length == 2) {
      final hour = int.tryParse(parts![0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return TimeOfDay(hour: fallbackHour, minute: 0);
  }
}

class _TimeSettingButton extends StatelessWidget {
  const _TimeSettingButton({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          alignment: Alignment.centerLeft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AtlasColors.mutedInk,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AtlasColors.ink,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}

class _SettingField extends StatelessWidget {
  const _SettingField({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: AtlasColors.azure),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      );
}

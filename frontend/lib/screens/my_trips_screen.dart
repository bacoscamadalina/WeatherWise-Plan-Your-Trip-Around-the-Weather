import 'package:flutter/material.dart';

import '../models/trip_plan.dart';
import '../services/trip_repository.dart';
import '../theme/atlas_theme.dart';
import 'saved_trip_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({required this.repository, super.key});

  final PersonalTripRepository repository;

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  List<TripPlan> _trips = const [];
  bool _loading = true;
  String? _error;

  bool get _romanian => Localizations.localeOf(context).languageCode == 'ro';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await widget.repository.listTrips();
      if (mounted) setState(() => _trips = trips);
    } catch (_) {
      if (mounted) {
        setState(() => _error = _romanian
            ? 'Călătoriile nu au putut fi încărcate. Verifică internetul și încearcă din nou.'
            : 'Your trips could not be loaded. Check your connection and try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(TripPlan summary) async {
    try {
      final trip = await widget.repository.getTrip(summary.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SavedTripScreen(
            plan: trip,
            repository: widget.repository,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_romanian
                ? 'Planul nu a putut fi deschis. Încearcă din nou.'
                : 'The plan could not be opened. Try again.'),
          ),
        );
      }
    }
  }

  Future<void> _delete(TripPlan trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_romanian ? 'Ștergi călătoria?' : 'Delete this trip?'),
        content: Text(trip.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_romanian ? 'Renunță' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_romanian ? 'Șterge' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteTrip(trip.id);
      if (mounted) {
        setState(
            () => _trips = _trips.where((item) => item.id != trip.id).toList());
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_romanian
                ? 'Călătoria nu a fost ștearsă. Verifică internetul și încearcă din nou.'
                : 'The trip was not deleted. Check your connection and try again.'),
            action: SnackBarAction(
              label: _romanian ? 'Reîncearcă' : 'Retry',
              onPressed: () => _delete(trip),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AtlasColors.ivory,
        appBar: AppBar(
          backgroundColor: AtlasColors.paper,
          surfaceTintColor: Colors.transparent,
          title: Text(_romanian ? 'Călătoriile mele' : 'My trips'),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _body(),
        ),
      );

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: AtlasColors.mutedInk),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_romanian ? 'Încearcă din nou' : 'Try again'),
            ),
          ),
        ],
      );
    }
    if (_trips.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
        children: [
          const Icon(Icons.map_outlined, size: 58, color: AtlasColors.azure),
          const SizedBox(height: 18),
          Text(
            _romanian
                ? 'Prima călătorie începe cu vremea.'
                : 'Your first trip starts with the weather.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _romanian
                ? 'Întoarce-te la prognoză și construiește un plan. Va apărea automat aici.'
                : 'Return to the forecast and build a plan. It will appear here automatically.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AtlasColors.mutedInk),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _trips.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return Material(
          color: AtlasColors.paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AtlasColors.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(trip),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AtlasColors.paleGold,
                    foregroundColor: AtlasColors.ink,
                    child: Icon(Icons.route_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trip.name,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${trip.location.displayName} · ${_date(trip.startsOn)}–${_date(trip.endsOn)}',
                          style: const TextStyle(color: AtlasColors.mutedInk),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _romanian ? 'Șterge călătoria' : 'Delete trip',
                    onPressed: () => _delete(trip),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _date(DateTime value) => '${value.day}.${value.month}.${value.year}';
}

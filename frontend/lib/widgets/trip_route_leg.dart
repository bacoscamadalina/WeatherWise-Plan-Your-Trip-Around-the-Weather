import 'package:flutter/material.dart';

import '../models/trip_plan.dart';
import '../theme/atlas_theme.dart';

class TripRouteLeg extends StatelessWidget {
  const TripRouteLeg({
    required this.item,
    required this.romanian,
    super.key,
  });

  final TripPlanItem item;
  final bool romanian;

  @override
  Widget build(BuildContext context) {
    final metadata = item.metadata;
    final origin = metadata['route_origin_name'] as String?;
    if (origin == null) return const SizedBox.shrink();

    final calculated = metadata['route_status'] == 'provider_route';
    final duration = (metadata['route_duration_minutes'] as num?)?.round();
    final distance = (metadata['route_distance_km'] as num?)?.toDouble();
    final mode = metadata['route_transport_mode'] as String? ?? 'car';
    final fits = metadata['route_fits_schedule'] != false;
    final returnDestination = metadata['return_destination_name'] as String?;
    final returnDuration =
        (metadata['return_route_duration_minutes'] as num?)?.round();
    final returnDistance =
        (metadata['return_route_distance_km'] as num?)?.toDouble();
    final returnCalculated =
        metadata['return_route_status'] == 'provider_route';
    final returnArrival = metadata['return_route_arrival_at'] as String?;
    final returnFitsDay = metadata['return_route_fits_day'] != false;
    final returnArrivesNextDay = metadata['return_arrives_next_day'] == true;
    final returnOverrun =
        (metadata['return_after_day_end_minutes'] as num?)?.round();
    final departure = metadata['route_departure_at'] as String?;
    final arrival = metadata['route_arrival_at'] as String?;
    final adjusted = (metadata['route_adjusted_minutes'] as num?)?.round();
    final originalStart = metadata['route_original_start'] as String?;
    final beforeDayStart = metadata['route_before_day_start'] == true;

    return Semantics(
      container: true,
      child: Container(
        key: ValueKey('trip-route-leg-${item.id}'),
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: calculated
              ? AtlasColors.sky.withValues(alpha: .52)
              : AtlasColors.line.withValues(alpha: .34),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: calculated
                ? AtlasColors.azure.withValues(alpha: .24)
                : AtlasColors.line,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                _modeIcon(mode),
                size: 18,
                color: calculated ? AtlasColors.azure : AtlasColors.mutedInk,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _legLabel(
                      origin,
                      duration,
                      distance,
                      mode,
                      calculated,
                      departure,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AtlasColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (!fits) ...[
                    const SizedBox(height: 3),
                    Text(
                      romanian
                          ? 'Sosire estimată la ${arrival ?? '—'}; intervalul rămâne incompatibil și trebuie replănuit.'
                          : 'Estimated arrival ${arrival ?? '—'}; the gap is still incompatible and needs replanning.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  if (calculated && beforeDayStart) ...[
                    const SizedBox(height: 3),
                    Text(
                      romanian
                          ? 'Deplasarea începe înainte de ora oficială a programului zilei.'
                          : 'Travel starts before the day’s advertised schedule.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AtlasColors.mutedInk,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  if (adjusted != null && originalStart != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      romanian
                          ? 'Program ajustat cu $adjusted min față de $originalStart.'
                          : 'Schedule shifted by $adjusted min from $originalStart.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AtlasColors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  if (returnDestination != null && returnDuration != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _returnLabel(
                        returnDestination,
                        returnDuration,
                        returnDistance,
                        returnCalculated,
                        returnArrival,
                        returnArrivesNextDay,
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (!returnFitsDay && returnArrival != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ExcludeSemantics(
                          child: Icon(
                            Icons.schedule_outlined,
                            size: 16,
                            color: Color(0xFF9A432E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _returnOverrunLabel(
                              returnArrival,
                              returnOverrun,
                              returnArrivesNextDay,
                            ),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AtlasColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (calculated &&
                      metadata['route_caution_required'] == true) ...[
                    const SizedBox(height: 3),
                    Text(
                      romanian
                          ? 'Traseul poate să nu includă trotuare, alei sau piste clar amenajate; verifică-l înainte de plecare.'
                          : 'The route may not include clear sidewalks, paths, or cycle lanes; check it before leaving.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _legLabel(
    String origin,
    int? duration,
    double? distance,
    String mode,
    bool calculated,
    String? departure,
  ) {
    final time = duration == null ? '' : '$duration min';
    final distanceLabel =
        distance == null ? '' : ' · ${_distance(distance)} km';
    if (!calculated) {
      return romanian
          ? '~$time rezervate ${_modeLabel(mode)} din $origin · rută calculată indisponibilă'
          : '~$time reserved ${_modeLabel(mode)} from $origin · calculated route unavailable';
    }
    final departureLabel = departure == null
        ? ''
        : romanian
            ? 'Plecare estimată ~$departure · '
            : 'Estimated departure ~$departure · ';
    return romanian
        ? '$departureLabel$time ${_modeLabel(mode)}$distanceLabel din $origin'
        : '$departureLabel$time ${_modeLabel(mode)}$distanceLabel from $origin';
  }

  String _returnLabel(
    String destination,
    int duration,
    double? distance,
    bool calculated,
    String? arrival,
    bool arrivesNextDay,
  ) {
    final distanceLabel =
        distance == null ? '' : ' · ${_distance(distance)} km';
    final arrivalLabel = arrival == null
        ? ''
        : romanian
            ? ' · sosire estimată ~$arrival${arrivesNextDay ? ' a doua zi' : ''}'
            : ' · estimated arrival ~$arrival${arrivesNextDay ? ' next day' : ''}';
    if (!calculated) {
      return romanian
          ? 'Întoarcere la $destination: ~$duration min rezervate$arrivalLabel · rută calculată indisponibilă'
          : 'Return to $destination: ~$duration min reserved$arrivalLabel · calculated route unavailable';
    }
    return romanian
        ? 'Întoarcere la $destination: $duration min$arrivalLabel$distanceLabel'
        : 'Return to $destination: $duration min$arrivalLabel$distanceLabel';
  }

  String _returnOverrunLabel(
    String arrival,
    int? overrun,
    bool arrivesNextDay,
  ) {
    final delay = overrun == null
        ? ''
        : romanian
            ? ' cu $overrun min'
            : ' by $overrun min';
    return romanian
        ? 'Întoarcerea ajunge la ~$arrival${arrivesNextDay ? ' a doua zi' : ''} și depășește programul zilei$delay. Scurtează ultima oprire sau alege una mai aproape.'
        : 'The return arrives around $arrival${arrivesNextDay ? ' next day' : ''} and exceeds the day’s schedule$delay. Shorten the final stop or choose one closer.';
  }

  String _distance(double value) {
    final label = value.toStringAsFixed(1);
    return romanian ? label.replaceAll('.', ',') : label;
  }

  String _modeLabel(String mode) => switch (mode) {
        'walking' => romanian ? 'pe jos' : 'walking',
        'bicycle' => romanian ? 'cu bicicleta' : 'by bicycle',
        'public_transport' =>
          romanian ? 'cu transportul public' : 'by public transport',
        _ => romanian ? 'cu mașina' : 'by car',
      };

  IconData _modeIcon(String mode) => switch (mode) {
        'walking' => Icons.directions_walk_rounded,
        'bicycle' => Icons.directions_bike_rounded,
        'public_transport' => Icons.directions_bus_rounded,
        _ => Icons.directions_car_outlined,
      };
}

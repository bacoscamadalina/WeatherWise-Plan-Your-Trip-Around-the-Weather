import 'package:flutter/material.dart';

import '../models/trip_plan.dart';
import '../theme/atlas_theme.dart';

class TripDayLogisticsBand extends StatelessWidget {
  const TripDayLogisticsBand({
    required this.logistics,
    required this.romanian,
    super.key,
  });

  final TripDayLogistics logistics;
  final bool romanian;

  @override
  Widget build(BuildContext context) {
    if (logistics.plannedStops == 0) return const SizedBox.shrink();

    final facts = _facts();
    final title = logistics.routeAvailable
        ? (romanian ? 'Drumul zilei' : 'Today’s route')
        : (romanian ? 'Planul zilei' : 'Today’s plan');
    final qualifier = logistics.routeAvailable
        ? (logistics.estimated
            ? (romanian ? 'rezervă estimată' : 'estimated allowance')
            : (romanian ? 'calculat pe traseu' : 'route calculated'))
        : (romanian ? 'traseu încă indisponibil' : 'route not available yet');

    return Semantics(
      container: true,
      label: '$title, ${facts.join(', ')}, $qualifier',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AtlasColors.mint.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AtlasColors.teal.withValues(alpha: .2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AtlasColors.paper,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 19,
                  color: AtlasColors.teal,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AtlasColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (var index = 0; index < facts.length; index++)
                          Text(
                            index == 0 ? facts[index] : '• ${facts[index]}',
                            style: const TextStyle(
                              color: AtlasColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      qualifier,
                      style: const TextStyle(
                        color: AtlasColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _facts() {
    final stopLabel = logistics.plannedStops == 1
        ? (romanian ? '1 oprire' : '1 stop')
        : (romanian
            ? '${logistics.plannedStops} opriri'
            : '${logistics.plannedStops} stops');
    final facts = <String>[stopLabel];
    if (logistics.travelMinutes case final minutes?) {
      facts.add(romanian
          ? '${_duration(minutes)} pe drum'
          : '${_duration(minutes)} travelling');
    }
    if (logistics.distanceKm case final distance?) {
      facts.add('${_number(distance)} km');
    }
    if (logistics.returnArrivalAt case final arrival?) {
      facts.add(romanian ? 'înapoi la $arrival' : 'back at $arrival');
    }
    return facts;
  }

  String _duration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    if (remainder == 0) return '$hours h';
    return '$hours h $remainder min';
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
}

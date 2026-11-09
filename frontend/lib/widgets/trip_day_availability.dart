import 'package:flutter/material.dart';

import '../theme/atlas_theme.dart';

class TripDayAvailability extends StatelessWidget {
  const TripDayAvailability({
    required this.from,
    required this.until,
    required this.romanian,
    required this.afterArrival,
    required this.beforeDeparture,
    super.key,
  });

  final String from;
  final String until;
  final bool romanian;
  final bool afterArrival;
  final bool beforeDeparture;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: romanian
            ? 'Interval disponibil $from–$until'
            : 'Available window $from–$until',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AtlasColors.paleGold,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.schedule_send_rounded,
                  size: 20,
                  color: AtlasColors.ink,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _message(),
                    style: const TextStyle(
                      color: AtlasColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  String _message() {
    final reason = switch ((afterArrival, beforeDeparture)) {
      (true, true) => romanian
          ? 'după sosire și înainte de plecare'
          : 'after arrival and before departure',
      (true, false) => romanian ? 'după sosire' : 'after arrival',
      (false, true) => romanian ? 'înainte de plecare' : 'before departure',
      _ =>
        romanian ? 'în intervalul disponibil' : 'inside the available window',
    };
    return romanian
        ? 'Zi parțială · planificăm doar între $from și $until, $reason.'
        : 'Partial day · planning only between $from and $until, $reason.';
  }
}

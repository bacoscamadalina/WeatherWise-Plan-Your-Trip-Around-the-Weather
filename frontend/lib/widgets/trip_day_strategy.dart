import 'package:flutter/material.dart';

import '../theme/atlas_theme.dart';

class TripDayStrategy extends StatelessWidget {
  const TripDayStrategy({
    required this.summary,
    required this.romanian,
    super.key,
  });

  final String summary;
  final bool romanian;

  @override
  Widget build(BuildContext context) {
    final label = romanian ? 'Strategia zilei' : 'Day strategy';

    return Semantics(
      container: true,
      label: '$label. $summary',
      child: ExcludeSemantics(
        child: Container(
          key: const ValueKey('trip-day-strategy'),
          padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
          decoration: BoxDecoration(
            color: AtlasColors.mint.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(10),
            border: const Border(
              left: BorderSide(color: AtlasColors.teal, width: 3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.route_outlined,
                size: 20,
                color: AtlasColors.teal,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AtlasColors.teal,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AtlasColors.ink,
                            height: 1.4,
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
}

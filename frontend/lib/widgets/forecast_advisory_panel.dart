import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/weather_advisory.dart';

class ForecastAdvisoryPanel extends StatelessWidget {
  const ForecastAdvisoryPanel({
    required this.advisories,
    super.key,
  });

  final List<WeatherAdvisory> advisories;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final high = advisories.any((advisory) => advisory.isHigh);
    final background = high ? colors.errorContainer : colors.tertiaryContainer;
    final foreground =
        high ? colors.onErrorContainer : colors.onTertiaryContainer;

    return Semantics(
      container: true,
      label: high
          ? AppStrings.of(context).highPriorityAdvisory
          : AppStrings.of(context).planningAdvisory,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                high ? Icons.warning_amber_rounded : Icons.shield_outlined,
                color: foreground,
                size: 25,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.of(context).planAroundForecast,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppStrings.of(context).advisoryDisclaimer,
                      style: TextStyle(color: foreground.withValues(alpha: .8)),
                    ),
                    const SizedBox(height: 12),
                    for (var index = 0; index < advisories.length; index++) ...[
                      if (index > 0) ...[
                        Divider(color: foreground.withValues(alpha: .22)),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        AppStrings.of(context).advisoryTitle(
                          advisories[index].code,
                          advisories[index].title,
                        ),
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.of(context).advisoryMessage(
                          advisories[index].code,
                          advisories[index].message,
                        ),
                        style: TextStyle(color: foreground),
                      ),
                    ],
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

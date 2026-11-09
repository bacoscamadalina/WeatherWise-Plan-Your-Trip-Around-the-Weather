import '../models/hourly_forecast.dart';

class HourlyWindow {
  const HourlyWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  int get hours => end.difference(start).inHours;
}

class HourlyWindowAdvisor {
  const HourlyWindowAdvisor();

  HourlyWindow? bestOutdoorWindow(List<HourlyForecast> hours) {
    HourlyWindow? best;
    DateTime? runStart;
    DateTime? previous;

    void finishRun() {
      if (runStart == null || previous == null) return;
      final candidate = HourlyWindow(
        start: runStart!,
        end: previous!.add(const Duration(hours: 1)),
      );
      if (candidate.hours >= 2 &&
          (best == null || candidate.hours > best!.hours)) {
        best = candidate;
      }
      runStart = null;
      previous = null;
    }

    for (final hour in [...hours]..sort((a, b) => a.time.compareTo(b.time))) {
      final suitable = hour.daylight &&
          hour.rainProbability <= 35 &&
          hour.windSpeedKph < 35 &&
          const {'outdoor', 'flexible'}.contains(hour.activityContext);
      final continues = previous == null ||
          hour.time.difference(previous!) == const Duration(hours: 1);
      if (!suitable || !continues) finishRun();
      if (suitable) {
        runStart ??= hour.time;
        previous = hour.time;
      }
    }
    finishRun();
    return best;
  }
}

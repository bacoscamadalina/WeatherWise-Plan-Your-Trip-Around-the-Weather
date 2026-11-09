import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/l10n/app_strings.dart';

void main() {
  const strings = AppStrings(Locale('ro'));

  test('localizes every WeatherWise ranking reason variant', () {
    expect(
      strings
          .recommendationReason('Fits your afternoon plan and this forecast'),
      'Se potrivește planului pentru după-amiază și acestei prognoze',
    );
    expect(
      strings.recommendationReason('Matches your Science Fiction movie mood'),
      'Se potrivește preferinței tale pentru filme sf',
    );
    expect(
      strings.recommendationReason('A culture pick suited to this forecast'),
      'O alegere de cultură potrivită acestei prognoze',
    );
    expect(
      strings
          .recommendationReason('Matches your indoor preference for this day'),
      'Se potrivește preferinței tale pentru interior în această zi',
    );
    expect(
      strings.recommendationReason('A weather-friendly option 1.2 km away'),
      'O opțiune potrivită vremii, la 1.2 km',
    );
    expect(
      strings.recommendationReason(
        'Scheduled locally for this forecast day; venue setting is unverified',
      ),
      'Programat local în ziua acestei prognoze; mediul locației nu este verificat',
    );
  });

  test('localizes WeatherWise UV planning notes by stable code', () {
    expect(
      strings.planningNoteMessage(
        'very_high_uv',
        'UV peaks at 8.5; favor shade around midday and use sun protection.',
      ),
      'UV atinge 8.5; caută umbră la prânz și folosește protecție solară.',
    );
  });
}

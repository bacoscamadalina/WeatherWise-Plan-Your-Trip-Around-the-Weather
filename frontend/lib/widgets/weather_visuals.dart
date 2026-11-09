import 'package:flutter/material.dart';

import '../models/daily_forecast.dart';

enum WeatherMood { sunny, cloudy, windy, rainy, stormy, snowy, foggy }

class WeatherVisuals {
  const WeatherVisuals._({
    required this.mood,
    required this.heroColors,
    required this.lightSurface,
    required this.darkSurface,
    required this.lightAccent,
    required this.darkAccent,
  });

  final WeatherMood mood;
  final List<Color> heroColors;
  final Color lightSurface;
  final Color darkSurface;
  final Color lightAccent;
  final Color darkAccent;

  factory WeatherVisuals.forForecast(
    DailyForecast? forecast, {
    String? weatherClass,
    double? windSpeedKph,
  }) {
    final mood = _moodFor(
      forecast,
      weatherClass: weatherClass,
      windSpeedKph: windSpeedKph,
    );
    return switch (mood) {
      WeatherMood.sunny => const WeatherVisuals._(
          mood: WeatherMood.sunny,
          heroColors: [Color(0xFF0A3156), Color(0xFF157FB6)],
          lightSurface: Color(0xFFFFF0B8),
          darkSurface: Color(0xFF263345),
          lightAccent: Color(0xFF9C6500),
          darkAccent: Color(0xFFFFD66B),
        ),
      WeatherMood.cloudy => const WeatherVisuals._(
          mood: WeatherMood.cloudy,
          heroColors: [Color(0xFF253D4D), Color(0xFF657A86)],
          lightSurface: Color(0xFFE8EDF0),
          darkSurface: Color(0xFF293034),
          lightAccent: Color(0xFF52616A),
          darkAccent: Color(0xFFC8D2D7),
        ),
      WeatherMood.windy => const WeatherVisuals._(
          mood: WeatherMood.windy,
          heroColors: [Color(0xFF263C4B), Color(0xFF71828B)],
          lightSurface: Color(0xFFE4E9EC),
          darkSurface: Color(0xFF283136),
          lightAccent: Color(0xFF485A65),
          darkAccent: Color(0xFFBDD0DA),
        ),
      WeatherMood.rainy => const WeatherVisuals._(
          mood: WeatherMood.rainy,
          heroColors: [Color(0xFF102E49), Color(0xFF326C83)],
          lightSurface: Color(0xFFDDEDF2),
          darkSurface: Color(0xFF1E333A),
          lightAccent: Color(0xFF216477),
          darkAccent: Color(0xFF7DC7D8),
        ),
      WeatherMood.stormy => const WeatherVisuals._(
          mood: WeatherMood.stormy,
          heroColors: [Color(0xFF272A43), Color(0xFF585879)],
          lightSurface: Color(0xFFE8E6F2),
          darkSurface: Color(0xFF302F43),
          lightAccent: Color(0xFF5A577C),
          darkAccent: Color(0xFFC7C2F3),
        ),
      WeatherMood.snowy => const WeatherVisuals._(
          mood: WeatherMood.snowy,
          heroColors: [Color(0xFF3E5A6B), Color(0xFF7896A1)],
          lightSurface: Color(0xFFE8F2F5),
          darkSurface: Color(0xFF27373D),
          lightAccent: Color(0xFF527889),
          darkAccent: Color(0xFFAED8E5),
        ),
      WeatherMood.foggy => const WeatherVisuals._(
          mood: WeatherMood.foggy,
          heroColors: [Color(0xFF4A5655), Color(0xFF7A8883)],
          lightSurface: Color(0xFFE9ECE9),
          darkSurface: Color(0xFF303735),
          lightAccent: Color(0xFF596B65),
          darkAccent: Color(0xFFC1D0CA),
        ),
    };
  }

  Color surface(Brightness brightness, {required bool selected}) {
    if (!selected) {
      return brightness == Brightness.dark
          ? Color.alphaBlend(darkAccent.withValues(alpha: .05), darkSurface)
          : Color.alphaBlend(lightAccent.withValues(alpha: .035), Colors.white);
    }
    return brightness == Brightness.dark ? darkSurface : lightSurface;
  }

  Color accent(Brightness brightness) =>
      brightness == Brightness.dark ? darkAccent : lightAccent;

  static WeatherMood _moodFor(
    DailyForecast? forecast, {
    String? weatherClass,
    double? windSpeedKph,
  }) {
    if (forecast == null) return WeatherMood.cloudy;
    final resolvedClass = weatherClass ?? forecast.weatherClass;
    final resolvedWind = windSpeedKph ?? forecast.windSpeedKph;
    return switch (resolvedClass) {
      'clear' when resolvedWind >= 28 => WeatherMood.windy,
      'clear' => WeatherMood.sunny,
      'rain' => WeatherMood.rainy,
      'storm' => WeatherMood.stormy,
      'snow' => WeatherMood.snowy,
      'fog' => WeatherMood.foggy,
      _ when resolvedWind >= 22 => WeatherMood.windy,
      _ => WeatherMood.cloudy,
    };
  }
}

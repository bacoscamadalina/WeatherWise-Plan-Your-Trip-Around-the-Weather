import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weatherwise/models/daily_forecast.dart';
import 'package:weatherwise/widgets/weather_visuals.dart';

void main() {
  test('maps clear weather to a warm sunny palette', () {
    final visuals = WeatherVisuals.forForecast(
      _forecast(weatherClass: 'clear', windSpeedKph: 8),
    );

    expect(visuals.mood, WeatherMood.sunny);
    expect(visuals.heroColors.last, const Color(0xFF157FB6));
  });

  test('promotes strong wind to the mineral gray palette', () {
    final visuals = WeatherVisuals.forForecast(
      _forecast(weatherClass: 'cloud', windSpeedKph: 26),
    );

    expect(visuals.mood, WeatherMood.windy);
    expect(visuals.heroColors.last, const Color(0xFF71828B));
  });

  test('keeps rain visually distinct from clouds', () {
    final rainy = WeatherVisuals.forForecast(
      _forecast(weatherClass: 'rain', windSpeedKph: 30),
    );
    final cloudy = WeatherVisuals.forForecast(
      _forecast(weatherClass: 'cloud', windSpeedKph: 8),
    );

    expect(rainy.mood, WeatherMood.rainy);
    expect(cloudy.mood, WeatherMood.cloudy);
    expect(rainy.heroColors, isNot(cloudy.heroColors));
  });
}

DailyForecast _forecast({
  required String weatherClass,
  required double windSpeedKph,
}) {
  return DailyForecast(
    id: 1,
    date: DateTime(2026, 10, 1),
    label: weatherClass,
    weatherClass: weatherClass,
    activityContext: 'flexible',
    minC: 10,
    maxC: 20,
    rainProbability: 10,
    windSpeedKph: windSpeedKph,
  );
}

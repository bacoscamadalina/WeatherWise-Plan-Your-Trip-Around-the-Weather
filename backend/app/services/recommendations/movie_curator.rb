require "digest"

module Recommendations
  class MovieCurator
    PERSONAS = [
      { key: "storyteller", genres: %w[drama history romance], en: "story-rich", ro: "bogată în povești" },
      { key: "explorer", genres: %w[adventure action documentary], en: "adventurous", ro: "aventuroasă" },
      { key: "dreamer", genres: %w[fantasy animation family], en: "imaginative", ro: "imaginativă" },
      { key: "detective", genres: %w[mystery crime thriller], en: "mysterious", ro: "misterioasă" },
      { key: "optimist", genres: %w[comedy music romance], en: "bright-hearted", ro: "luminoasă" },
      { key: "futurist", genres: %w[science-fiction documentary adventure], en: "curious", ro: "curioasă" }
    ].freeze

    WEATHER_GENRES = {
      "clear" => %w[adventure comedy romance family music],
      "cloudy" => %w[drama mystery science-fiction fantasy documentary],
      "rain" => %w[mystery thriller crime drama fantasy],
      "storm" => %w[thriller horror mystery action crime],
      "snow" => %w[fantasy family animation romance drama],
      "fog" => %w[mystery thriller drama science-fiction horror],
      "wind" => %w[adventure action thriller documentary]
    }.freeze

    def adjustment(item:, forecast:)
      return 0 unless item.recommendation_type == "movie"

      genres = item.genres.map(&:downcase)
      weather_matches = genres.intersection(weather_genres(forecast)).size
      persona_matches = genres.intersection(persona_for(forecast.location)[:genres]).size
      weather_matches * 14 + persona_matches * 9 + rotation_bonus(item, forecast)
    end

    def reason(forecast:, language:)
      persona = persona_for(forecast.location)
      place = forecast.location.name
      if language == "ro"
        "O selecție #{persona[:ro]} pentru #{place}, acordată cu #{romanian_weather(forecast.weather_class)}."
      else
        "A #{persona[:en]} pick for #{place}, tuned to #{english_weather(forecast.weather_class)}."
      end
    end

    def persona_key(location)
      persona_for(location)[:key]
    end

    private

    def persona_for(location)
      PERSONAS[stable_number(location_key(location)) % PERSONAS.length]
    end

    def weather_genres(forecast)
      base = WEATHER_GENRES.fetch(forecast.weather_class, WEATHER_GENRES["cloudy"])
      return base + %w[fantasy family drama] if forecast.temperature_max_c.to_f <= 5
      return base + %w[comedy adventure romance] if forecast.temperature_max_c.to_f >= 26

      base
    end

    def rotation_bonus(item, forecast)
      stable_number(
        [ location_key(forecast.location), forecast.forecast_date.iso8601, item.provider, item.external_id ].join(":"),
      ) % 17
    end

    def location_key(location)
      [ location.provider, location.external_id, location.country_code, location.name, location.latitude, location.longitude ].join(":")
    end

    def stable_number(value)
      Digest::SHA256.hexdigest(value.to_s).first(12).to_i(16)
    end

    def romanian_weather(weather_class)
      {
        "clear" => "o zi senină", "cloudy" => "lumina unei zile înnorate",
        "rain" => "ritmul ploii", "storm" => "atmosfera furtunii",
        "snow" => "o zi cu zăpadă", "fog" => "atmosfera de ceață",
        "wind" => "energia unei zile cu vânt"
      }.fetch(weather_class, "vremea prognozată")
    end

    def english_weather(weather_class)
      {
        "clear" => "a clear day", "cloudy" => "soft cloudy light",
        "rain" => "the rhythm of the rain", "storm" => "a stormy atmosphere",
        "snow" => "a snowy day", "fog" => "the foggy mood",
        "wind" => "a windy day's energy"
      }.fetch(weather_class, "the forecast")
    end
  end
end

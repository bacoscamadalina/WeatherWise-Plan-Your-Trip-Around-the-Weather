module Weather
  Classification = Data.define(:weather_class, :condition_label, :activity_context)

  class Classifier
    LABELS = {
      clear: "Clear", cloudy: "Cloudy", rain: "Rain",
      snow: "Snow", storm: "Thunderstorm", fog: "Fog", extreme: "Extreme weather"
    }.freeze
    CODE_LABELS = {
      0 => "Clear",
      1 => "Mainly clear",
      2 => "Partly cloudy",
      3 => "Overcast"
    }.freeze

    def call(code:, temperature_max_c:, precipitation_probability:)
      weather_class = classify_code(code.to_i)
      context = activity_context(weather_class, temperature_max_c.to_f, precipitation_probability.to_i)
      Classification.new(
        weather_class: weather_class.to_s,
        condition_label: CODE_LABELS.fetch(code.to_i, LABELS.fetch(weather_class)),
        activity_context: context.to_s
      )
    end

    private

    def classify_code(code)
      case code
      when 0, 1 then :clear
      when 2, 3 then :cloudy
      when 45, 48 then :fog
      when 51..67, 80..82 then :rain
      when 71..77, 85, 86 then :snow
      when 95..99 then :storm
      else :extreme
      end
    end

    def activity_context(weather_class, max_temperature, rain_probability)
      return :caution if %i[storm extreme].include?(weather_class)
      return :indoor if %i[rain snow].include?(weather_class) || rain_probability >= 60
      return :outdoor if weather_class == :clear && max_temperature.between?(5, 32) && rain_probability < 30

      :flexible
    end
  end
end

module Api
  module V1
    class TripsController < BaseController
      before_action :authenticate_user!, only: %i[index show replan replace_item update destroy]

      def index
        trips = current_user.trips.includes(:location).order(created_at: :desc).limit(50)
        render json: { data: trips.map { |trip| trip_json(trip, include_days: false) } }
      end

      def show
        trip = visible_trip(Trip.includes(trip_days: :itinerary_items))
        render json: { data: trip_json(trip, include_days: true) }
      end

      def create
        location = Location.find(trip_params.fetch(:location_id))
        trip = Trip.create!(trip_params.merge(location:, user: current_user))
        trip = Trips::Planner.new.call(trip:, language: requested_language)

        render json: { data: trip_json(trip, include_days: true) }, status: :created
      end

      def replan
        trip = visible_trip
        trip.assign_attributes(replan_trip_params)
        trip.validate!
        trip = Trips::Planner.new.call(
          trip:,
          language: requested_language,
          refresh_weather: true
        )
        render json: { data: trip_json(trip, include_days: true) }
      end

      def replace_item
        trip = visible_trip
        item_id = params[:item_id].presence ||
          raise(ActionController::BadRequest, "item_id is required")
        item = ItineraryItem.joins(:trip_day).find_by!(
          id: item_id,
          trip_days: { trip_id: trip.id }
        )
        trip = Trips::ItemReplacer.new.call(item:, language: requested_language)
        render json: { data: trip_json(trip, include_days: true) }
      rescue Trips::NoAlternativeError => error
        render json: {
          error: { code: "no_alternative", message: error.message }
        }, status: :unprocessable_content
      end

      def update
        trip = current_user.trips.find(params[:id])
        trip.update!(editable_trip_params)
        render json: { data: trip_json(trip, include_days: false) }
      end

      def destroy
        current_user.trips.find(params[:id]).destroy!
        head :no_content
      end

      private

      def trip_params
        permitted = params.require(:trip).permit(
          :location_id, :name, :starts_on, :ends_on, :party_size,
          :arrival_time, :departure_time,
          :pace, :transport_mode, :max_distance_km,
          preferences: [ :budget, { dietary: [], interests: [] } ]
        ).to_h.symbolize_keys
        permitted[:starts_on] = parse_date(permitted[:starts_on], "starts_on")
        permitted[:ends_on] = parse_date(permitted[:ends_on], "ends_on")
        parse_clock_params!(permitted)
        permitted
      end

      def parse_date(value, field)
        Date.iso8601(value.to_s)
      rescue Date::Error
        raise ActionController::BadRequest, "#{field} must use YYYY-MM-DD"
      end

      def editable_trip_params
        params.require(:trip).permit(:name, :status)
      end

      def replan_trip_params
        return {} unless params[:trip].present?

        permitted = params.require(:trip).permit(
          :starts_on, :ends_on, :party_size, :pace,
          :arrival_time, :departure_time,
          :transport_mode, :max_distance_km,
          preferences: [ :budget, { dietary: [], interests: [] } ]
        ).to_h.symbolize_keys
        permitted[:starts_on] = parse_date(permitted[:starts_on], "starts_on") if permitted.key?(:starts_on)
        permitted[:ends_on] = parse_date(permitted[:ends_on], "ends_on") if permitted.key?(:ends_on)
        parse_clock_params!(permitted)
        permitted
      end

      def parse_clock_params!(permitted)
        %i[arrival_time departure_time].each do |field|
          next unless permitted.key?(field)

          value = permitted[field].to_s
          raise ActionController::BadRequest, "#{field} must use HH:MM" unless value.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/)
        end
      end

      def visible_trip(scope = Trip.all)
        scope.where(user_id: current_user.id).find(params[:id])
      end

      def trip_json(trip, include_days:)
        payload = {
          id: trip.id,
          name: trip.name,
          starts_on: trip.starts_on.iso8601,
          ends_on: trip.ends_on.iso8601,
          arrival_time: trip.arrival_time&.strftime("%H:%M"),
          departure_time: trip.departure_time&.strftime("%H:%M"),
          day_count: trip.day_count,
          party_size: trip.party_size,
          pace: trip.pace,
          transport_mode: trip.transport_mode,
          max_distance_km: trip.max_distance_km.to_f,
          rhythm: Trips::DailyRhythm.payload(
            pace: trip.pace,
            transport_mode: trip.transport_mode,
            language: requested_language
          ),
          preferences: trip.preferences,
          status: trip.status,
          location: location_json(trip.location)
        }
        payload[:days] = trip.trip_days.map { |day| trip_day_json(day, trip) } if include_days
        payload
      end

      def trip_day_json(day, trip)
        window = Trips::DailyRhythm.available_window(trip, day.date)
        {
          id: day.id,
          date: day.date.iso8601,
          weather_class: day.weather_class,
          activity_context: day.activity_context,
          summary: day.summary,
          weather: day.weather_snapshot,
          available_from: window.fetch(:starts_at),
          available_until: window.fetch(:ends_at),
          logistics: Trips::DayLogistics.new(trip_day: day).payload,
          items: day.itinerary_items.map { |item| itinerary_item_json(item) }
        }
      end

      def itinerary_item_json(item)
        {
          id: item.id,
          slot: item.slot,
          kind: item.kind,
          title: item.title,
          summary: item.summary,
          venue_name: item.venue_name,
          starts_at: item.starts_at&.strftime("%H:%M"),
          ends_at: item.ends_at&.strftime("%H:%M"),
          distance_km: item.distance_km&.to_f,
          coordinates: item.latitude && item.longitude ?
            { latitude: item.latitude.to_f, longitude: item.longitude.to_f } : nil,
          provider: item.provider,
          url: item.url,
          image_url: item.image_url,
          rating: item.rating&.to_f,
          rating_count: item.rating_count,
          status: item.status,
          metadata: item.metadata
        }
      end
    end
  end
end

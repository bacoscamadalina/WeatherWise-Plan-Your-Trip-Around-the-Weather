# ☀️ WeatherWise

> **Plan your trip around the weather.**

WeatherWise turns a weather forecast into a practical travel plan. The user chooses a destination and travel dates, and the app creates a daily itinerary with suitable places, activities, events, movies, and restaurants.

On a sunny day, it may suggest a walk, a hike, or an outdoor attraction. When it rains, the plan adapts with museums, cinemas, and other indoor activities.

## ✨ Features

- 🌍 Search for cities and smaller locations worldwide
- 🌦️ View a real 14-day weather forecast
- 🗓️ Build itineraries for one or multiple days
- ☕ Find highly rated places for breakfast, lunch, and dinner
- 🏛️ Combine activities, attractions, events, and movies
- 🥾 Discover activities within 50 km of the destination
- 🚗 Arrange stops into a more coherent daily route
- ⏱️ Estimate travel time, distance, and return time
- 🔄 Adapt the itinerary when the weather or travel dates change
- 👤 Save and edit trips with a personal account
- 🇬🇧 🇷🇴 Use the app in English or Romanian

## 🧭 How it works

```text
Destination + dates + preferences
                  ↓
          real weather forecast
                  ↓
 activities + meals + events + movies
                  ↓
       a weather-aware daily itinerary
```

The planner considers:

- Weather conditions during each part of the day
- Arrival and departure times
- A relaxed, balanced, or active travel pace
- Transport type and travel time between stops
- Maximum distance from the base location
- Nature, culture, entertainment, and dietary preferences

## 🛠️ Tech stack

| Component | Technology |
|---|---|
| Backend API | Ruby on Rails 8.1 |
| Database | PostgreSQL 16 |
| Client application | Flutter / Dart |
| Weather and geocoding | Open-Meteo |
| Activities and images | OpenStreetMap, Wikipedia, Wikimedia Commons |
| Optional integrations | Google Places, Google Routes, TMDB, Ticketmaster |

## 📁 Project structure

```text
WeatherWise/
├── backend/       # Rails API, models, services, and tests
├── frontend/      # Flutter application and UI tests
└── compose.yaml   # PostgreSQL for local development
```

## 🚀 Local setup

### 1. Backend

Requires Ruby 3.4+, Bundler, and Docker.

```bash
docker compose up -d postgres

cd backend
cp .env.example .env
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

The API will be available at `http://localhost:3000`.

### 2. Flutter application

Requires Flutter 3.47+.

```bash
cd frontend
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

For the web version:

```bash
flutter run -d chrome --web-port=8080 \
  --dart-define=API_BASE_URL=http://localhost:3000
```

> Android Emulator uses `http://10.0.2.2:3000` to reach the local backend.

## 🔑 API configuration

Open-Meteo, Wikipedia, and Wikimedia work without API keys. The following integrations are optional and can be configured in `backend/.env`:

```env
GOOGLE_PLACES_API_KEY=
GOOGLE_ROUTES_API_KEY=
TMDB_BEARER_TOKEN=
TICKETMASTER_API_KEY=
```

Without these keys, the application remains usable and clearly labels unavailable or estimated information.

## 🧪 Tests

```bash
# Backend
cd backend
bin/rails test

# Flutter
cd frontend
flutter test
flutter analyze
```

## 🎯 Project goal

WeatherWise is more than a weather application. Its main idea is simple:

> **It does not only show the weather—it helps you decide what is worth doing on every day of your trip.**

---

<p align="center">Built for better trips, whatever the weather. 🌤️</p>

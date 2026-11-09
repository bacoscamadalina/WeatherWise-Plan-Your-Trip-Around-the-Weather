# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
iasi = Location.find_or_initialize_by(provider: "mock", external_id: "iasi-ro")
iasi.update!(
  name: "Iași",
  country_code: "RO",
  admin_area: "Iași County",
  latitude: 47.1585,
  longitude: 27.6014,
  timezone: "Europe/Bucharest"
)

Forecasts::Fetch.new.call(location: iasi, days: 14, refresh: true)

catalog = [
  {
    location: iasi, recommendation_type: "activity", provider: "seed", external_id: "palace-of-culture-iasi",
    title: "Explore the Palace of Culture", venue_name: "Palace of Culture",
    summary: "Spend a few hours among Iași's history, art, and science collections.", indoor: true,
    tags: %w[museum culture history], weather_classes: %w[rain snow storm fog],
    url: "https://www.openstreetmap.org/relation/399268",
    metadata: { latitude: 47.1573073, longitude: 27.5862609 }
  },
  {
    location: iasi, recommendation_type: "activity", provider: "seed", external_id: "cinema-city-palace-iasi",
    title: "Catch a cinema screening", venue_name: "Cinema City Iași",
    summary: "Turn a wet afternoon into an easy cinema plan at the mall.", indoor: true,
    tags: %w[cinema entertainment], weather_classes: %w[rain snow storm],
    url: "https://www.openstreetmap.org/node/12778454974",
    metadata: { latitude: 47.1670743, longitude: 27.5166968 }
  },
  {
    location: iasi, recommendation_type: "activity", provider: "seed", external_id: "copou-park-iasi",
    title: "Walk through Copou Park", venue_name: "Copou Park",
    summary: "Follow the shaded paths and visit the historic linden tree.", indoor: false,
    tags: %w[park walk history], weather_classes: %w[clear cloudy],
    url: "https://www.openstreetmap.org/way/61750051",
    metadata: { latitude: 47.1788875, longitude: 27.5668015 }
  },
  {
    location: iasi, recommendation_type: "activity", provider: "seed", external_id: "botanical-garden-iasi",
    title: "Visit the Botanical Garden", venue_name: "Anastasie Fătu Botanical Garden",
    summary: "Explore seasonal gardens and long walking routes across the grounds.", indoor: false,
    tags: %w[nature garden photography], weather_classes: %w[clear cloudy],
    url: "https://www.openstreetmap.org/relation/1251249",
    metadata: { latitude: 47.1851254, longitude: 27.5533916 }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-knives-out",
    title: "Knives Out", summary: "A playful modern mystery for a rainy evening.", indoor: true,
    genres: %w[mystery comedy], tags: %w[cozy ensemble], weather_classes: %w[rain fog],
    url: "https://www.themoviedb.org/movie/546554",
    metadata: { translations: { ro: { summary: "Un mister modern și jucăuș, potrivit pentru o seară ploioasă." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-arrival",
    title: "Arrival", summary: "Thoughtful science fiction with a reflective atmosphere.", indoor: true,
    genres: %w[science-fiction drama], tags: %w[thoughtful atmospheric], weather_classes: %w[rain cloudy],
    url: "https://www.themoviedb.org/movie/329865",
    metadata: { translations: { ro: { summary: "Science-fiction meditativ, cu o atmosferă profundă." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-paddington-2",
    title: "Paddington 2", summary: "A warm family comedy for an easy indoor plan.", indoor: true,
    genres: %w[family comedy], tags: %w[uplifting], weather_classes: %w[rain snow],
    url: "https://www.themoviedb.org/movie/346648",
    metadata: { translations: { ro: { summary: "O comedie caldă pentru familie, potrivită unui plan relaxat în interior." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-the-conjuring",
    title: "The Conjuring", summary: "A haunted-house horror pick for a stormy night.", indoor: true,
    genres: %w[horror mystery], tags: %w[scary atmospheric], weather_classes: %w[storm rain],
    url: "https://www.themoviedb.org/movie/138843",
    metadata: { translations: { ro: { summary: "Horror într-o casă bântuită, pentru o seară furtunoasă." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-amelie",
    title: "Amélie", summary: "A playful Paris story full of small joys and gentle romance.", indoor: true,
    genres: %w[comedy romance], tags: %w[uplifting whimsical], weather_classes: %w[clear cloudy],
    url: "https://www.themoviedb.org/movie/194",
    metadata: { translations: { ro: { summary: "O poveste pariziană jucăușă, plină de bucurii mărunte și romantism." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-walter-mitty",
    title: "The Secret Life of Walter Mitty", summary: "An optimistic adventure about leaving routine behind.", indoor: true,
    genres: %w[adventure comedy drama], tags: %w[travel uplifting], weather_classes: %w[clear wind],
    url: "https://www.themoviedb.org/movie/116745",
    metadata: { translations: { ro: { summary: "O aventură optimistă despre curajul de a ieși din rutină." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-spirited-away",
    title: "Spirited Away", summary: "A richly imagined animated journey through a mysterious spirit world.", indoor: true,
    genres: %w[animation fantasy family], tags: %w[imaginative atmospheric], weather_classes: %w[rain snow cloudy],
    url: "https://www.themoviedb.org/movie/129",
    metadata: { translations: { ro: { summary: "O călătorie animată, bogat imaginată, printr-o lume misterioasă a spiritelor." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-little-women",
    title: "Little Women", summary: "A warm period drama about ambition, family, and growing up.", indoor: true,
    genres: %w[drama romance], tags: %w[warm literary], weather_classes: %w[snow rain cloudy],
    url: "https://www.themoviedb.org/movie/331482",
    metadata: { translations: { ro: { summary: "O dramă de epocă despre ambiție, familie și maturizare." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-grand-budapest",
    title: "The Grand Budapest Hotel", summary: "A precise, colorful caper with comedy, intrigue, and old-world charm.", indoor: true,
    genres: %w[comedy drama crime], tags: %w[stylish ensemble], weather_classes: %w[cloudy snow],
    url: "https://www.themoviedb.org/movie/120467",
    metadata: { translations: { ro: { summary: "O aventură colorată, cu umor, intrigă și farmec de altădată." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-interstellar",
    title: "Interstellar", summary: "An expansive science-fiction journey grounded in family and time.", indoor: true,
    genres: %w[science-fiction adventure drama], tags: %w[epic thoughtful], weather_classes: %w[cloudy clear],
    url: "https://www.themoviedb.org/movie/157336",
    metadata: { translations: { ro: { summary: "O călătorie science-fiction amplă, legată de familie și trecerea timpului." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-coco",
    title: "Coco", summary: "A vibrant family adventure shaped by music, memory, and belonging.", indoor: true,
    genres: %w[animation family music], tags: %w[colorful uplifting], weather_classes: %w[clear rain],
    url: "https://www.themoviedb.org/movie/354912",
    metadata: { translations: { ro: { summary: "O aventură de familie vibrantă despre muzică, memorie și apartenență." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-the-martian",
    title: "The Martian", summary: "Resourceful science fiction with dry humor and a spirit of exploration.", indoor: true,
    genres: %w[science-fiction adventure comedy], tags: %w[smart optimistic], weather_classes: %w[clear wind],
    url: "https://www.themoviedb.org/movie/286217",
    metadata: { translations: { ro: { summary: "Science-fiction inventiv, cu umor sec și spirit de explorare." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-prisoners",
    title: "Prisoners", summary: "A tense mystery thriller for a dark, rain-soaked evening.", indoor: true,
    genres: %w[thriller mystery crime], tags: %w[intense atmospheric], weather_classes: %w[rain fog],
    url: "https://www.themoviedb.org/movie/146233",
    metadata: { translations: { ro: { summary: "Un thriller misterios și tensionat pentru o seară întunecată și ploioasă." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-the-shining",
    title: "The Shining", summary: "An isolated winter hotel becomes the setting for psychological horror.", indoor: true,
    genres: %w[horror mystery], tags: %w[scary winter], weather_classes: %w[snow storm],
    url: "https://www.themoviedb.org/movie/694",
    metadata: { translations: { ro: { summary: "Un hotel izolat iarna devine scena unui horror psihologic." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-sing-street",
    title: "Sing Street", summary: "A joyful coming-of-age story powered by music and youthful invention.", indoor: true,
    genres: %w[music comedy drama], tags: %w[uplifting youthful], weather_classes: %w[clear cloudy],
    url: "https://www.themoviedb.org/movie/369557",
    metadata: { translations: { ro: { summary: "O poveste veselă despre maturizare, alimentată de muzică și inventivitate." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-before-sunrise",
    title: "Before Sunrise", summary: "Two travelers turn one evening of conversation into a lasting memory.", indoor: true,
    genres: %w[romance drama], tags: %w[travel intimate], weather_classes: %w[clear cloudy],
    url: "https://www.themoviedb.org/movie/76",
    metadata: { translations: { ro: { summary: "Doi călători transformă o seară de conversație într-o amintire durabilă." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-princess-bride",
    title: "The Princess Bride", summary: "A witty fairy-tale adventure with romance, duels, and generous humor.", indoor: true,
    genres: %w[fantasy adventure comedy romance], tags: %w[playful family], weather_classes: %w[rain snow clear],
    url: "https://www.themoviedb.org/movie/2493",
    metadata: { translations: { ro: { summary: "O aventură de basm spirituală, cu romantism, dueluri și mult umor." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-wilderpeople",
    title: "Hunt for the Wilderpeople", summary: "A funny, warm wilderness adventure about an unlikely pair.", indoor: true,
    genres: %w[adventure comedy drama], tags: %w[nature uplifting], weather_classes: %w[clear wind cloudy],
    url: "https://www.themoviedb.org/movie/371645",
    metadata: { translations: { ro: { summary: "O aventură amuzantă și caldă în sălbăticie, despre un duo neașteptat." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-blade-runner",
    title: "Blade Runner", summary: "Noir science fiction with rain, neon, and questions about being human.", indoor: true,
    genres: %w[science-fiction thriller drama], tags: %w[noir atmospheric], weather_classes: %w[rain fog cloudy],
    url: "https://www.themoviedb.org/movie/78",
    metadata: { translations: { ro: { summary: "Science-fiction noir, cu ploaie, neon și întrebări despre natura umană." } } }
  },
  {
    recommendation_type: "movie", provider: "seed", external_id: "movie-the-thing",
    title: "The Thing", summary: "A frozen research station faces a relentless shape-shifting threat.", indoor: true,
    genres: %w[horror science-fiction mystery], tags: %w[scary winter], weather_classes: %w[snow storm],
    url: "https://www.themoviedb.org/movie/1091",
    metadata: { translations: { ro: { summary: "O stație de cercetare înghețată înfruntă o amenințare care își schimbă forma." } } }
  }
]

catalog.each do |attributes|
  item = Recommendation.find_or_initialize_by(provider: attributes[:provider], external_id: attributes[:external_id])
  item.update!(attributes)
end

puts "Seeded #{iasi.display_name} with 14 forecast days and #{catalog.size} recommendations."

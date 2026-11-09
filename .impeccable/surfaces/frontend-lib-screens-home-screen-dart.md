---
version: 1
slug: "frontend-lib-screens-home-screen-dart"
primary_target: "frontend/lib/screens/home_screen.dart"
related_targets: ["frontend/lib/widgets/weather_hero.dart","frontend/lib/widgets/forecast_rail.dart","frontend/lib/widgets/forecast_trend_chart.dart","frontend/lib/widgets/recommendation_panel.dart"]
---

# Home surface brief

Mode: Operate. WeatherWise is rebuilt as **Atlas de lumină**, a bright travel-atlas interface that turns a real forecast into a practical day plan without losing weather scanability.

The approved reference is `.impeccable/mocks/decision/atlas-de-lumina.png`. Its composition is authoritative: quiet paper navigation, a location-symbolic photographic daylight field, editorial temperature, one white image-bearing planning strip, chromatic forecast tabs, then chart and large photographic recommendation media. Photography is binding whenever a location is loaded: use the location payload's attributed hero image, the curated Iași illustration for the seed experience, or a neutral honest loading/fallback surface while imagery is unavailable. Never substitute another locality's landmark or return to decorative skyline geometry as the finished state.

Palette: warm ivory, atlas-blue ink, azure, sunlight gold, coral, mint, and restrained mineral gray. Display weather and section titles use a bookish serif; interaction and dense facts remain a legible platform sans. Cards are reserved for real forecast days, recommendations, or saved plans. Controls remain Material 3 / native, with 48dp Android and 44pt iOS targets, safe areas, system navigation, and reduced-motion behavior.

Signature interaction: selecting a day moves the active chromatic tab and renews the daylight field in one finite fade/slide; the plan strip remains the single primary bridge from weather to recommendations.

Responsive rule: desktop reads as a broad editorial spread; compact screens stack the same sequence—navigation, daylight story, plan strip, horizontal day tabs, chart, ideas—without shrinking type into a miniature desktop.

Global destination photography remains provider-dependent. The client contract supports `hero_image_url` plus `image_attribution`, and recommendation `image_url` is used in both the plan strip and gallery. Missing or failed media must remain honest and must not be presented as a photo of the searched place.

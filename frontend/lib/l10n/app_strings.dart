import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ro')];

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      AppStrings(Localizations.localeOf(context));

  bool get isRomanian => locale.languageCode == 'ro';

  String get searchHint =>
      isRomanian ? 'Caută orice oraș sau sat' : 'Search any city or village';
  String get search => isRomanian ? 'Caută' : 'Search';
  String get suggestedPlaces =>
      isRomanian ? 'Locuri sugerate' : 'Suggested places';
  String get searchingPlaces =>
      isRomanian ? 'Căutăm locuri…' : 'Searching places…';
  String get noSuggestedPlaces => isRomanian
      ? 'Nu am găsit încă un loc potrivit. Adaugă țara sau regiunea.'
      : 'No matching place yet. Add a country or region.';
  String get suggestionsUnavailable => isRomanian
      ? 'Sugestiile nu sunt disponibile momentan.'
      : 'Suggestions are unavailable right now.';
  String get savedPlaces =>
      isRomanian ? 'Locuri salvate și recente' : 'Saved and recent places';
  String get reminders =>
      isRomanian ? 'Mementouri pentru prognoză' : 'Forecast reminders';
  String get remindersOn => isRomanian
      ? 'Mementourile pentru prognoză sunt active'
      : 'Forecast reminders on';
  String get remindersNativeOnly => isRomanian
      ? 'Mementourile sunt disponibile în aplicațiile Android, iOS și macOS'
      : 'Forecast reminders are available in the Android, iOS, and macOS apps';
  String get language => isRomanian ? 'Limbă' : 'Language';
  String get english => 'English';
  String get romanian => 'Română';
  String get emptyTitle => isRomanian
      ? 'Vreme care se transformă într-o zi de ținut minte.'
      : 'Weather that turns into a day worth remembering.';
  String get emptySubtitle => isRomanian
      ? 'Caută un loc pentru a vedea prognoza și a-ți face planul.'
      : 'Search a place to begin your local forecast and plan.';
  String get demoData => isRomanian ? 'Date demonstrative' : 'Demo data';
  String get illustrativeImage =>
      isRomanian ? 'Imagine ilustrativă' : 'Illustrative image';
  String get tryLiveWeather =>
      isRomanian ? 'Încearcă vremea live' : 'Try live weather';
  String get refreshForecast =>
      isRomanian ? 'Actualizează prognoza' : 'Refresh forecast';
  String get refreshingForecast =>
      isRomanian ? 'Se actualizează prognoza' : 'Refreshing forecast';
  String savePlace(String name) => isRomanian ? 'Salvează $name' : 'Save $name';
  String removeSavedPlace(String name) => isRomanian
      ? 'Elimină $name din locurile salvate'
      : 'Remove $name from saved places';
  String get seeIdeas =>
      isRomanian ? 'Vezi idei pentru această zi' : 'See ideas for this day';
  String get hideIdeas => isRomanian ? 'Ascunde ideile' : 'Hide ideas';
  String get chooseDay => isRomanian
      ? 'Alege o zi pentru a-ți contura planul'
      : 'Choose a day to shape your plan';
  String get trendUnavailable => isRomanian
      ? 'Prognoza meteo pentru 14 zile nu este disponibilă încă.'
      : 'The 14-day weather story is not available yet.';
  String get trendTitle =>
      isRomanian ? 'Prognoza pe 14 zile' : '14-day weather story';
  String get trendSubtitle => isRomanian
      ? 'Maxime, minime și șanse de ploaie — apasă o zi pentru planificare.'
      : 'Highs, lows and rain chance — tap a day to plan it.';
  String get trendSemantics => isRomanian
      ? 'Evoluția temperaturii și ploii pentru paisprezece zile'
      : 'Fourteen-day temperature and rain outlook';
  String get high => isRomanian ? 'Max.' : 'High';
  String get lowLabel => isRomanian ? 'Min.' : 'Low';
  String get rainChance => isRomanian ? 'Șanse de ploaie' : 'Rain chance';
  String get planThisDay => isRomanian ? 'Planifică ziua' : 'Plan this day';
  String get lowRainReason => isRomanian
      ? 'Risc redus de ploaie și vânt moderat.'
      : 'Low rain risk and manageable wind.';
  String get drierReason => isRomanian
      ? 'Una dintre variantele mai uscate din această perioadă.'
      : 'One of the drier options in this outlook.';
  String get calmerWindReason => isRomanian
      ? 'Vântul mai calm face planurile flexibile mai ușoare.'
      : 'Calmer wind makes flexible plans easier.';
  String uvReason(String value) => isRomanian
      ? 'UV atinge $value; caută umbră în jurul prânzului.'
      : 'UV peaks at $value; favor shade around midday.';
  String bestBalanceReason(int rainValue, int windValue) => isRomanian
      ? 'Cel mai bun echilibru disponibil: $rainValue% ploaie și vânt de $windValue km/h.'
      : 'Best available balance: $rainValue% rain and $windValue km/h wind.';
  String get highPriorityAdvisory => isRomanian
      ? 'Recomandare de planificare cu prioritate ridicată'
      : 'High-priority planning advisory';
  String get planningAdvisory =>
      isRomanian ? 'Recomandare de planificare' : 'Planning advisory';
  String get locationLoadFailed => isRomanian
      ? 'Locația nu a putut fi încărcată. Verifică serviciul și încearcă din nou.'
      : 'Could not load that location. Check the API and try again.';
  String noPlacesMatched(String query) => isRomanian
      ? 'Nu am găsit locuri pentru „$query”. Adaugă țara sau regiunea.'
      : 'No places matched “$query”. Try adding a country or region.';
  String get placeSearchUnavailable => isRomanian
      ? 'Căutarea locațiilor nu este disponibilă acum. Verifică conexiunea și încearcă din nou.'
      : 'Place search is unavailable right now. Check the connection and try again.';
  String get savedPlaceRefreshFailed => isRomanian
      ? 'Locul salvat nu a putut fi actualizat. Verifică conexiunea și încearcă din nou.'
      : 'Could not refresh that saved place. Check the connection and try again.';
  String get forecastUpdated =>
      isRomanian ? 'Prognoza a fost actualizată.' : 'Forecast updated.';
  String get forecastRefreshFailed => isRomanian
      ? 'Prognoza nu a putut fi actualizată. Este afișată versiunea anterioară.'
      : 'Could not refresh the forecast. Showing the previous update.';
  String get remindersNoMatches => isRomanian
      ? 'Mementourile sunt active. Nicio recomandare viitoare nu corespunde momentan.'
      : 'Reminders are on. No upcoming advisories currently match.';
  String remindersScheduled(int count) => isRomanian
      ? '$count ${count == 1 ? 'memento meteo programat' : 'mementouri meteo programate'}.'
      : '$count forecast ${count == 1 ? 'reminder' : 'reminders'} scheduled.';
  String get remindersOff => isRomanian
      ? 'Mementourile pentru prognoză au fost oprite.'
      : 'Forecast reminders turned off.';
  String get remindersUpdateFailed => isRomanian
      ? 'Mementourile nu au putut fi actualizate pe acest dispozitiv.'
      : 'Forecast reminders could not be updated on this device.';
  String placeSaved(String name) => isRomanian
      ? '$name a fost salvat pe acest dispozitiv.'
      : '$name saved on this device.';
  String placeRemoved(String name) => isRomanian
      ? '$name a fost eliminat din locurile salvate.'
      : '$name removed from saved places.';
  String get savedPlacesLimit => isRomanian
      ? 'Poți salva cel mult 12 locuri.'
      : 'You can save up to 12 places.';
  String get placesStorageFailed => isRomanian
      ? 'Locurile nu au putut fi salvate pe acest dispozitiv.'
      : 'Places could not be saved on this device.';
  String get matchingIdeas =>
      isRomanian ? 'Căutăm idei locale…' : 'Matching local ideas…';
  String bestPlan(String title) =>
      isRomanian ? 'Plan recomandat · $title' : 'Best plan · $title';
  String get indoorFallback => isRomanian
      ? 'Păstrează aproape un plan la interior'
      : 'Keep an indoor plan nearby';
  String get outdoorFallback => isRomanian
      ? 'Un interval bun pentru activități afară'
      : 'A strong window for being outside';
  String get flexibleFallback => isRomanian
      ? 'Vreme flexibilă pentru planul tău'
      : 'Flexible weather for your day';
  String fallbackDetail(int rain, {required bool wet}) => isRomanian
      ? wet
          ? '$rain% șanse de ploaie · ideile se adaptează prognozei'
          : '$rain% șanse de ploaie · deschide ideile locale potrivite'
      : wet
          ? '$rain% rain chance · ideas adapt to the forecast'
          : '$rain% rain chance · open your matched local ideas';
  String bestPlanSemantics(String title, String detail) => isRomanian
      ? 'Plan recomandat pentru această vreme: $title. $detail. Deschide detaliile.'
      : 'Best plan for this weather: $title. $detail. Open details.';
  String get indoorContext =>
      isRomanian ? 'Potrivit pentru interior' : 'Best for indoor plans';
  String get outdoorContext => isRomanian
      ? 'Excelent pentru activități afară'
      : 'Great for outdoor plans';
  String get cautionContext =>
      isRomanian ? 'Planifică prudent' : 'Plan with caution';
  String get flexibleContext =>
      isRomanian ? 'Păstrează planurile flexibile' : 'Keep plans flexible';
  String highLow(num high, num low) => isRomanian
      ? 'Max ${high.round()}° · Min ${low.round()}°'
      : 'High ${high.round()}° · Low ${low.round()}°';
  String low(num value) =>
      isRomanian ? 'Min ${value.round()}°' : 'Low ${value.round()}°';
  String rain(int value) => isRomanian ? 'Ploaie $value%' : 'Rain $value%';
  String rainPercent(int value) =>
      isRomanian ? '$value% ploaie' : '$value% rain';
  String wind(num value) =>
      isRomanian ? 'Vânt ${value.round()} km/h' : 'Wind ${value.round()} km/h';
  String uv(String value) => isRomanian ? 'UV max. $value' : 'UV max $value';
  String sun(String value) => isRomanian ? 'Soare $value' : 'Sun $value';
  String feelsLike(num value, String estimate) => isRomanian
      ? 'Se simte ca ${value.round()}° · $estimate'
      : 'Feels like ${value.round()}° · $estimate';
  String currentEstimate(String? clock, {required bool stale}) {
    final prefix = isRomanian
        ? stale
            ? 'Ultima estimare'
            : 'Estimare curentă'
        : stale
            ? 'Last estimate'
            : 'Current estimate';
    if (clock == null) return prefix;
    return isRomanian ? '$prefix · la $clock' : '$prefix · as of $clock';
  }

  String updated(Duration age) {
    if (age.isNegative || age.inMinutes < 1) {
      return isRomanian ? 'Actualizat acum' : 'Updated just now';
    }
    if (age.inMinutes < 60) {
      return isRomanian
          ? 'Actualizat acum ${age.inMinutes} min.'
          : 'Updated ${age.inMinutes}m ago';
    }
    if (age.inHours < 24) {
      return isRomanian
          ? 'Actualizat acum ${age.inHours} h'
          : 'Updated ${age.inHours}h ago';
    }
    return isRomanian
        ? 'Actualizat acum ${age.inDays} zile'
        : 'Updated ${age.inDays}d ago';
  }

  String dayLabel(DateTime date) {
    final weekdays = isRomanian
        ? const [
            'Luni',
            'Marți',
            'Miercuri',
            'Joi',
            'Vineri',
            'Sâmbătă',
            'Duminică'
          ]
        : const [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday'
          ];
    final months = isRomanian
        ? const [
            'ianuarie',
            'februarie',
            'martie',
            'aprilie',
            'mai',
            'iunie',
            'iulie',
            'august',
            'septembrie',
            'octombrie',
            'noiembrie',
            'decembrie'
          ]
        : const [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December'
          ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  String shortWeekday(DateTime date) {
    final weekdays = isRomanian
        ? const ['Lun', 'Mar', 'Mie', 'Joi', 'Vin', 'Sâm', 'Dum']
        : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String shortMonth(DateTime date) {
    final months = isRomanian
        ? const [
            'ian',
            'feb',
            'mar',
            'apr',
            'mai',
            'iun',
            'iul',
            'aug',
            'sep',
            'oct',
            'nov',
            'dec'
          ]
        : const [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec'
          ];
    return months[date.month - 1];
  }

  String selectedForecastSummary(
    DateTime date,
    num highValue,
    num lowValue,
    int rainValue,
  ) =>
      '${shortWeekday(date)} ${date.day} · ${highValue.round()}° / ${lowValue.round()}° · ${rainPercent(rainValue)}';

  String forecastSemantics(
      String label, DateTime date, num highValue, num lowValue, int rainValue) {
    if (isRomanian) {
      return '${shortWeekday(date)} ${date.day}, ${weatherLabel(label)}, '
          'maximă ${highValue.round()} grade, minimă ${lowValue.round()} grade, '
          '$rainValue la sută șanse de ploaie';
    }
    return '${shortWeekday(date)} ${date.day}, $label, '
        'high ${highValue.round()} degrees, low ${lowValue.round()} degrees, '
        '$rainValue percent chance of rain';
  }

  String bestOutdoorTitle(DateTime date) => isRomanian
      ? 'Cea mai bună zi pentru exterior · ${shortWeekday(date)} ${date.day}'
      : 'Best forecast match for outdoors · ${shortWeekday(date)} ${date.day}';

  String bestOutdoorSemantics(DateTime date, String reason) => isRomanian
      ? 'Cea mai bună zi pentru exterior, ${shortWeekday(date)} ${date.day}. $reason'
      : 'Best forecast match for outdoors, ${shortWeekday(date)} ${date.day}. $reason';

  String get legendSemantics => isRomanian
      ? 'Linia aurie arată maxima zilnică, linia gri arată minima, iar barele albastre arată șansele de ploaie'
      : 'Gold line is the daily high, gray line is the daily low, blue bars show rain chance';

  String weatherLabel(String label) {
    if (!isRomanian) return label;
    return switch (label.toLowerCase()) {
      'clear' => 'Senin',
      'mainly clear' => 'Mai mult senin',
      'partly cloudy' => 'Parțial noros',
      'overcast' => 'Înnorat',
      'fog' => 'Ceață',
      'drizzle' => 'Burniță',
      'rain' => 'Ploaie',
      'heavy rain' => 'Ploaie abundentă',
      'snow' => 'Ninsoare',
      'snow showers' => 'Averse de ninsoare',
      'rain showers' => 'Averse de ploaie',
      'storm' => 'Furtună',
      'thunderstorm' => 'Furtună cu descărcări electrice',
      _ => label,
    };
  }

  String get dayUnfolds =>
      isRomanian ? 'Cum evoluează ziua' : 'How the day unfolds';
  String get findingWeatherWindows => isRomanian
      ? 'Căutăm intervalele potrivite…'
      : 'Finding useful weather windows…';
  String get retryHourly => isRomanian
      ? 'Încearcă din nou prognoza orară'
      : 'Try hourly forecast again';
  String get hourlyUnavailable => isRomanian
      ? 'Detaliile orare nu sunt disponibile încă pentru această zi.'
      : 'Hourly detail is not available for this day yet.';
  String get noOutdoorWindow => isRomanian
      ? 'Nu există încă un interval sigur pentru exterior'
      : 'No dependable outdoor window yet';
  String bestOutdoorWindow(String start, String end) => isRomanian
      ? 'Cel mai bun interval afară · $start–$end'
      : 'Best outdoor window · $start–$end';
  String get indoorAlternative => isRomanian
      ? 'Păstrează o alternativă la interior și verifică din nou mai aproape de ziua respectivă.'
      : 'Keep an indoor alternative ready and check again closer to the day.';
  String calmerHours(int count) => isRomanian
      ? '$count ${count == 1 ? 'oră mai liniștită' : 'ore mai liniștite'} pentru plimbări sau planuri în aer liber.'
      : '$count calmer ${count == 1 ? 'hour' : 'hours'} for walking or outdoor plans.';
  String hourlySemantics(
          String time, String label, num temperature, int rain) =>
      isRomanian
          ? '$time, ${weatherLabel(label)}, ${temperature.round()} grade, $rain la sută șanse de ploaie'
          : '$time, $label, ${temperature.round()} degrees, $rain percent rain';

  String get ideasTitle =>
      isRomanian ? 'Idei potrivite prognozei' : 'Ideas matched to the forecast';
  String get ideasSubtitle => isRomanian
      ? 'Începe cu vremea, apoi alege starea potrivită.'
      : 'Start with the weather, then choose your mood.';
  String get all => isRomanian ? 'Toate' : 'All';
  String get activities => isRomanian ? 'Activități' : 'Activities';
  String get events => isRomanian ? 'Evenimente' : 'Events';
  String get movies => isRomanian ? 'Filme' : 'Movies';
  String get recommendationActivityLabel =>
      isRomanian ? 'Activitate' : 'Activity';
  String get recommendationEventLabel => isRomanian ? 'Eveniment' : 'Event';
  String get recommendationMovieLabel => isRomanian ? 'Film' : 'Movie';
  String tuneIdeas(int count) => count == 0
      ? (isRomanian ? 'Ajustează ideile' : 'Tune ideas')
      : (isRomanian ? 'Ajustează ideile ($count)' : 'Tune ideas ($count)');
  String get clear => isRomanian ? 'Șterge' : 'Clear';
  String get tryAgain => isRomanian ? 'Încearcă din nou' : 'Try again';
  String get clearFilters => isRomanian ? 'Șterge filtrele' : 'Clear filters';
  String get noFilteredIdeas => isRomanian
      ? 'Nicio idee nu corespunde acestor filtre și prognozei.'
      : 'No ideas match these filters for this forecast.';
  String get noCategoryIdeas => isRomanian
      ? 'Nu există încă rezultate în această categorie. Încearcă „Toate”.'
      : 'No matches in this category yet. Try All.';
  String get noEventIdeas => isRomanian
      ? 'Nu sunt evenimente publicate în apropiere pentru această dată.'
      : 'No nearby events are published for this date.';
  String get searchingEventDays => isRomanian
      ? 'Căutăm zile apropiate cu evenimente…'
      : 'Looking for nearby dates with events…';
  String get upcomingEventDays => isRomanian
      ? 'Evenimente în alte zile din prognoză'
      : 'Events on other forecast days';
  String eventCount(int count) => isRomanian
      ? '$count ${count == 1 ? 'eveniment' : 'evenimente'}'
      : '$count ${count == 1 ? 'event' : 'events'}';
  String get eventDaysUnavailable => isRomanian
      ? 'Calendarul extins nu este disponibil momentan. Poți alege manual altă zi.'
      : 'The wider event calendar is unavailable right now. You can still choose another day.';
  String get dataCredits => isRomanian ? 'Surse de date' : 'Data credits';
  String get eventDataByTicketmaster => isRomanian
      ? 'Date despre evenimente oferite de Ticketmaster'
      : 'Event data by Ticketmaster';
  String get eventDataByPredictHq => isRomanian
      ? 'Date despre evenimente oferite de PredictHQ'
      : 'Event data by PredictHQ';
  String distanceAway(num distance) => isRomanian
      ? 'la ${distance.toStringAsFixed(1)} km'
      : '${distance.toStringAsFixed(1)} km away';
  String get elevation => isRomanian ? 'Altitudine' : 'Elevation';
  String elevationValue(int meters) => '$meters m';
  String get routeLength => isRomanian ? 'Lungimea traseului' : 'Route length';
  String routeLengthValue(num distance) => '${distance.toStringAsFixed(1)} km';
  String get mappedDuration =>
      isRomanian ? 'Durată cartografiată' : 'Mapped duration';
  String durationValue(int minutes) {
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (hours == 0) return isRomanian ? '$remaining min' : '$remaining min';
    if (remaining == 0) return isRomanian ? '$hours h' : '$hours hr';
    return isRomanian ? '$hours h $remaining min' : '$hours hr $remaining min';
  }

  String get routeStart => isRomanian ? 'Pornire' : 'Starts at';
  String get routeEnd => isRomanian ? 'Destinație' : 'Ends at';
  String get ascent => isRomanian ? 'Urcare cumulată' : 'Total ascent';
  String get descent => isRomanian ? 'Coborâre cumulată' : 'Total descent';
  String get routeShape => isRomanian ? 'Tipul traseului' : 'Route shape';
  String roundtripValue(bool roundtrip) => roundtrip
      ? (isRomanian ? 'Circuit' : 'Round trip')
      : (isRomanian ? 'Traseu liniar' : 'Point to point');
  String get trailPlanTitle =>
      isRomanian ? 'Pregătirea traseului' : 'Trail preparation';
  String get trailPlanSubtitle => isRomanian
      ? 'Date cartografiate pentru orientare — nu înlocuiesc un ghid montan.'
      : 'Mapped facts for orientation — not a substitute for mountain guidance.';
  String get verifyMountainConditions => isRomanian
      ? 'Verifică în ziua plecării starea traseului, marcajele, echipamentul și avertizările Salvamont.'
      : 'On departure day, verify trail status, waymarks, equipment, and mountain-rescue advisories.';
  String get trailDifficulty =>
      isRomanian ? 'Dificultate OSM' : 'OSM difficulty';
  String get trailVisibility =>
      isRomanian ? 'Vizibilitatea potecii' : 'Trail visibility';
  String get surface => isRomanian ? 'Suprafață' : 'Surface';
  String get routeNetwork => isRomanian ? 'Rețeaua traseului' : 'Trail network';
  String get routeReference =>
      isRomanian ? 'Marcaj / indicativ' : 'Trail reference';
  String get trailMarker => isRomanian ? 'Marcaj OSM' : 'OSM waymark';
  String get routeOperator =>
      isRomanian ? 'Administrator traseu' : 'Trail operator';
  String get officialTrailPage =>
      isRomanian ? 'Pagina oficială a traseului' : 'Official trail page';
  String routeNetworkValue(String value) => _controlledTerm(value, {
        'lwn': 'rețea locală',
        'rwn': 'rețea regională',
        'nwn': 'rețea națională',
        'iwn': 'rețea internațională',
      });
  String trailMarkerValue(String value) {
    final marker = value.toLowerCase().split(':').last;
    final parts = marker.split('_');
    if (parts.length < 2) return _controlledTerm(marker, const {});
    final colorsRo = {
      'red': 'roșie',
      'blue': 'albastră',
      'yellow': 'galbenă',
      'green': 'verde',
      'black': 'neagră',
      'white': 'albă',
    };
    final shapesRo = {
      'bar': 'bandă',
      'stripe': 'bandă',
      'dot': 'bulină',
      'cross': 'cruce',
      'triangle': 'triunghi',
      'diamond': 'romb',
    };
    final colorsEn = {
      'red': 'red',
      'blue': 'blue',
      'yellow': 'yellow',
      'green': 'green',
      'black': 'black',
      'white': 'white',
    };
    final shapesEn = {
      'bar': 'stripe',
      'stripe': 'stripe',
      'dot': 'dot',
      'cross': 'cross',
      'triangle': 'triangle',
      'diamond': 'diamond',
    };
    final color = parts.first;
    final shape = parts.sublist(1).join('_');
    if (isRomanian && colorsRo[color] != null && shapesRo[shape] != null) {
      return '${shapesRo[shape]} ${colorsRo[color]}';
    }
    if (!isRomanian && colorsEn[color] != null && shapesEn[shape] != null) {
      return '${colorsEn[color]} ${shapesEn[shape]}';
    }
    return _controlledTerm(marker, const {});
  }

  String trailDifficultyValue(String value) => _controlledTerm(value, {
        'hiking': 'drumeție',
        'mountain_hiking': 'drumeție montană',
        'demanding_mountain_hiking': 'drumeție montană dificilă',
        'alpine_hiking': 'traseu alpin',
        'demanding_alpine_hiking': 'traseu alpin dificil',
        'difficult_alpine_hiking': 'traseu alpin foarte dificil',
      });
  String trailVisibilityValue(String value) => _controlledTerm(value, {
        'excellent': 'potecă foarte clară',
        'good': 'potecă bine vizibilă',
        'intermediate': 'potecă parțial vizibilă',
        'bad': 'potecă greu vizibilă',
        'horrible': 'potecă aproape invizibilă',
        'no': 'fără potecă vizibilă',
      });
  String surfaceValue(String value) => _controlledTerm(value, {
        'asphalt': 'asfalt',
        'paved': 'pavat',
        'concrete': 'beton',
        'gravel': 'pietriș',
        'fine_gravel': 'pietriș fin',
        'compacted': 'teren compactat',
        'ground': 'pământ',
        'dirt': 'pământ',
        'earth': 'pământ',
        'grass': 'iarbă',
        'rock': 'stâncă',
        'stone': 'piatră',
        'sand': 'nisip',
        'wood': 'lemn',
      });
  String _controlledTerm(String value, Map<String, String> romanian) {
    final normalized = value.toLowerCase().trim();
    if (isRomanian && romanian.containsKey(normalized)) {
      return romanian[normalized]!;
    }
    final readable = normalized.replaceAll('_', ' ');
    return readable.isEmpty
        ? readable
        : '${readable[0].toUpperCase()}${readable.substring(1)}';
  }

  String planningNote(String message) =>
      isRomanian ? 'Notă de planificare: $message' : 'Planning note: $message';
  String listedHours(String hours) => isRomanian
      ? 'Program afișat: $hours · verifică înainte de vizită'
      : 'Listed hours: $hours · verify before visiting';
  String tmdbRating(num rating) =>
      'TMDB ${isRomanian ? 'evaluare' : 'rating'} ${rating.toStringAsFixed(1)}/10';
  String get addToDayPlan =>
      isRomanian ? 'Adaugă în planul zilei' : 'Add to day plan';
  String filterValue(String value) {
    final normalized = value.toLowerCase();
    if (!isRomanian) {
      return value.isEmpty
          ? value
          : '${value[0].toUpperCase()}${value.substring(1)}';
    }
    return switch (normalized) {
      'activity' => 'Activități',
      'event' => 'Evenimente',
      'movie' => 'Filme',
      'morning' => 'Dimineață',
      'afternoon' => 'După-amiază',
      'evening' => 'Seară',
      'indoor' => 'Interior',
      'outdoor' => 'Exterior',
      'culture' => 'Cultură',
      'nature' => 'Natură',
      'entertainment' => 'Divertisment',
      'comedy' => 'Comedie',
      'drama' => 'Dramă',
      'horror' => 'Horror',
      'mystery' => 'Mister',
      'family' => 'Familie',
      'science fiction' => 'SF',
      _ => value,
    };
  }

  String itineraryWeatherSummary(
    String time,
    String label,
    num temperature,
    int rain,
  ) =>
      '$time · ${weatherLabel(label)} · ${temperature.round()}° · ${rainPercent(rain)}';

  String planWeatherRisk(int count) => isRomanian
      ? 'Vremea poate afecta ${count == 1 ? 'o oprire' : '$count opriri'} în aer liber.'
      : 'Weather may affect $count outdoor ${count == 1 ? 'stop' : 'stops'}.';
  String get adaptDayPlan => isRomanian ? 'Adaptează planul' : 'Adapt plan';
  String get adaptingDayPlan =>
      isRomanian ? 'Caut alternative…' : 'Finding alternatives…';
  String adaptedDayPlan(int count) => isRomanian
      ? '${count == 1 ? 'O oprire a fost înlocuită' : '$count opriri au fost înlocuite'} cu variante la interior.'
      : '$count outdoor ${count == 1 ? 'stop was' : 'stops were'} replaced with indoor options.';
  String adaptedDayPlanResult(int moved, int replaced) {
    if (moved == 0) return adaptedDayPlan(replaced);
    if (replaced == 0) {
      return isRomanian
          ? '${moved == 1 ? 'O oprire a fost mutată' : '$moved opriri au fost mutate'} într-un interval cu vreme mai bună.'
          : '$moved outdoor ${moved == 1 ? 'stop was' : 'stops were'} moved to a safer period.';
    }
    return isRomanian
        ? '$moved ${moved == 1 ? 'oprire a fost mutată' : 'opriri au fost mutate'}, iar $replaced ${replaced == 1 ? 'a fost înlocuită' : 'au fost înlocuite'} cu variante la interior.'
        : '$moved outdoor ${moved == 1 ? 'stop was' : 'stops were'} moved and $replaced ${replaced == 1 ? 'was' : 'were'} replaced with indoor options.';
  }

  String partiallyAdaptedDayPlan(int moved, int replaced, int unresolved) {
    final changed = adaptedDayPlanResult(moved, replaced);
    final remaining = isRomanian
        ? unresolved == 1
            ? 'O oprire rămâne expusă vremii.'
            : '$unresolved opriri rămân expuse vremii.'
        : '$unresolved ${unresolved == 1 ? 'stop remains' : 'stops remain'} exposed to the weather.';
    return '$changed $remaining';
  }

  String get noIndoorAlternatives => isRomanian
      ? 'Nu am găsit încă alternative la interior pentru aceste intervale.'
      : 'No indoor alternatives are available for those periods yet.';
  String get indoorAlternativesLoadFailed => isRomanian
      ? 'Nu am putut încărca alternativele la interior. Încearcă din nou.'
      : 'Indoor alternatives could not be loaded. Try again.';

  String movieFilter(String genre) => isRomanian
      ? 'Filme · ${filterValue(genre)}'
      : '${filterValue(genre)} movies';
  String withinDistance(num distance) => isRomanian
      ? 'În limita a ${distance.toStringAsFixed(0)} km'
      : 'Within ${distance.toStringAsFixed(0)} km';

  String get yourDayPlan => isRomanian ? 'Planul zilei' : 'Your day plan';
  String get dayPlanSubtitle => isRomanian
      ? 'O idee principală pentru fiecare parte a zilei · salvată pe acest dispozitiv'
      : 'One anchor idea per period · saved on this device';
  String get copyDayPlan =>
      isRomanian ? 'Copiază planul zilei' : 'Copy day plan';
  String get clearDayPlan =>
      isRomanian ? 'Șterge planul zilei' : 'Clear day plan';
  String get suggestDayPlan =>
      isRomanian ? 'Propune-mi un plan' : 'Suggest a day plan';
  String get completeDayPlan =>
      isRomanian ? 'Completează planul' : 'Complete my plan';
  String suggestedPlan(int count) => isRomanian
      ? count == 1
          ? 'A fost adăugată o idee potrivită vremii.'
          : 'Au fost adăugate $count idei potrivite vremii.'
      : count == 1
          ? 'Added one weather-matched idea.'
          : 'Added $count weather-matched ideas.';
  String get noIdeasForPlan => isRomanian
      ? 'Nu există suficiente idei potrivite pentru a completa planul.'
      : 'There are not enough suitable ideas to complete the plan.';
  String emptyPeriod(String period) => isRomanian
      ? '${filterValue(period)} · Adaugă o idee de mai jos'
      : '${filterValue(period)} · Add an idea below';
  String removeFromPeriod(String period) => isRomanian
      ? 'Elimină din planul pentru ${filterValue(period).toLowerCase()}'
      : 'Remove from ${filterValue(period).toLowerCase()} plan';

  String get cinemaShowtimes =>
      isRomanian ? 'Program cinema' : 'Cinema showtimes';
  String get cinemaShowtimesSubtitle => isRomanian
      ? 'Ore live pentru această dată. Programul cinematografelor se poate schimba.'
      : 'Live times for this date. Cinema schedules can change.';
  String get noShowtimesForPeriod => isRomanian
      ? 'Niciun spectacol returnat nu corespunde acestei perioade.'
      : 'No returned showtimes match this period.';
  String get noLiveCinemaTimes => isRomanian
      ? 'Nu există încă un program cinema live conectat pentru această locație.'
      : 'No live cinema times are connected for this location yet.';
  String get addShowtimeToPlan => isRomanian
      ? 'Adaugă ora filmului în planul zilei'
      : 'Add showtime to day plan';

  String get tuneYourIdeas =>
      isRomanian ? 'Ajustează ideile' : 'Tune your ideas';
  String get tuneYourIdeasSubtitle => isRomanian
      ? 'Personalizează această zi sau refolosește preferințele salvate pe dispozitiv.'
      : 'Fine-tune this day or reuse choices saved on this device.';
  String get savedProfiles =>
      isRomanian ? 'Profiluri salvate' : 'Saved profiles';
  String get noProfiles => isRomanian
      ? 'Nu ai încă profiluri. Alege filtrele, apoi salvează-le mai jos.'
      : 'No profiles yet. Choose filters, then save them below.';
  String deleteProfileTooltip(String name) =>
      isRomanian ? 'Șterge profilul $name' : 'Delete $name profile';
  String get when => isRomanian ? 'Când' : 'When';
  String get anyTime => isRomanian ? 'Oricând' : 'Any time';
  String get any => isRomanian ? 'Oricare' : 'Any';
  String get setting => isRomanian ? 'Mediu' : 'Setting';
  String get activityStyle =>
      isRomanian ? 'Tipul activității' : 'Activity style';
  String get activityDistance =>
      isRomanian ? 'Distanța până la activitate' : 'Activity distance';
  String get movieMood => isRomanian ? 'Genul filmului' : 'Movie mood';
  String get sciFi => 'SF';
  String get profileLimitReached =>
      isRomanian ? 'Ai atins limita de profiluri' : 'Profile limit reached';
  String get saveChoices =>
      isRomanian ? 'Salvează aceste preferințe' : 'Save these choices';
  String get choosePreference => isRomanian
      ? 'Alege cel puțin o preferință înainte de a salva profilul.'
      : 'Choose at least one preference before saving a profile.';
  String get reset => isRomanian ? 'Resetează' : 'Reset';
  String get applyFilters => isRomanian ? 'Aplică filtrele' : 'Apply filters';
  String get profilesLoadFailed => isRomanian
      ? 'Profilurile salvate nu au putut fi încărcate de pe acest dispozitiv.'
      : 'Saved profiles could not be loaded from this device.';
  String get profileNameUsed => isRomanian
      ? 'Acest nume de profil este deja folosit. Alege alt nume.'
      : 'That profile name is already used. Choose another name.';
  String get profileSaveFailed => isRomanian
      ? 'Profilul nu a putut fi salvat. Verifică spațiul dispozitivului și încearcă din nou.'
      : 'This profile could not be saved. Check device storage and try again.';
  String deleteProfileTitle(String name) =>
      isRomanian ? 'Ștergi „$name”?' : 'Delete “$name”?';
  String get deleteProfileBody => isRomanian
      ? 'Preferințele salvate vor fi eliminate de pe acest dispozitiv.'
      : 'The saved choices will be removed from this device.';
  String get keepProfile => isRomanian ? 'Păstrează profilul' : 'Keep profile';
  String get delete => isRomanian ? 'Șterge' : 'Delete';
  String get profileDeleteFailed => isRomanian
      ? 'Profilul nu a putut fi șters. Verifică spațiul dispozitivului și încearcă din nou.'
      : 'This profile could not be deleted. Check device storage and try again.';
  String get loadingProfiles => isRomanian
      ? 'Se încarcă profilurile salvate…'
      : 'Loading saved profiles…';
  String get nameProfile =>
      isRomanian ? 'Numește acest profil' : 'Name this profile';
  String get profileName => isRomanian ? 'Numele profilului' : 'Profile name';
  String get profileNameHint =>
      isRomanian ? 'Seară ploioasă de film' : 'Rainy movie night';
  String get enterProfileName =>
      isRomanian ? 'Introdu un nume pentru profil.' : 'Enter a profile name.';
  String get cancel => isRomanian ? 'Anulează' : 'Cancel';
  String get saveProfile => isRomanian ? 'Salvează profilul' : 'Save profile';

  String ideaType(String type) => switch (type) {
        'movie' => isRomanian ? 'Idee de film' : 'Movie idea',
        'event' => isRomanian ? 'Idee de eveniment' : 'Event idea',
        _ => isRomanian ? 'Idee de activitate' : 'Activity idea',
      };
  String get whyItFits =>
      isRomanian ? 'De ce se potrivește acestei zile' : 'Why it fits this day';
  String get whereYouGo => isRomanian ? 'Unde vei merge' : 'Where you’ll go';
  String get mapUnavailable => isRomanian
      ? 'Coordonatele hărții nu sunt încă disponibile pentru acest element.'
      : 'Map coordinates are not available for this catalog item yet.';
  String get checkBeforeYouGo =>
      isRomanian ? 'Verifică înainte să pleci' : 'Check before you go';
  String liveHoursDescription(String period) => isRomanian
      ? 'Verifică programul publicat pentru ${filterValue(period).toLowerCase()}. Informația nu include cozile sau închiderile neprevăzute.'
      : 'Ask a live place provider about the ${period.toLowerCase()} hours. This checks published hours, not queues or unexpected closures.';
  String get liveHoursFailed => isRomanian
      ? 'Programul live nu a putut fi verificat. Verifică conexiunea și încearcă din nou.'
      : 'Live hours could not be checked. Check your connection and try again.';
  String matchedPlace(String name) =>
      isRomanian ? 'Loc identificat: $name' : 'Matched place: $name';
  String checkedAt(String value) =>
      isRomanian ? 'Verificat $value' : 'Checked $value';
  String get openVenueSource =>
      isRomanian ? 'Deschide sursa locației' : 'Open venue source';
  String get openProviderPlace =>
      isRomanian ? 'Deschide locația furnizorului' : 'Open provider place';
  String get checkingLiveHours =>
      isRomanian ? 'Se verifică programul live' : 'Checking live hours';
  String get checkLiveHours =>
      isRomanian ? 'Verifică programul live' : 'Check live hours';
  String get checkAgain => isRomanian ? 'Verifică din nou' : 'Check again';
  String liveHoursBy(String label) => isRomanian
      ? 'Date despre program oferite de $label'
      : 'Live hours data by $label';
  String get dayRhythm => isRomanian
      ? 'Un ritm simplu pentru această zi'
      : 'A simple rhythm for the day';
  String get dayRhythmSubtitle => isRomanian
      ? 'Este o sugestie, nu o rezervare — adapteaz-o la programul real și timpul de deplasare.'
      : 'A suggestion, not a reservation—adjust it around actual opening hours and travel time.';
  String get flexibleStart => isRomanian
      ? 'Păstrează începutul zilei flexibil și verifică ultimul interval de ploaie.'
      : 'Keep the start flexible and check the latest rain window.';
  String get coolStart => isRomanian
      ? 'Folosește răcoarea dimineții pentru o plimbare, micul dejun sau deplasare.'
      : 'Use the cooler start for a relaxed walk, breakfast, or travel time.';
  String get beforeMovie => isRomanian
      ? 'Lasă loc pentru o activitate locală înainte de film.'
      : 'Leave room for a local activity before settling in later.';
  String get indoorBackup => isRomanian
      ? 'Păstrează aproape o variantă la interior dacă vremea se schimbă.'
      : 'Keep an indoor backup nearby if conditions change.';
  String get usefulDetails => isRomanian ? 'Detalii utile' : 'Useful details';
  String get distance => isRomanian ? 'Distanță' : 'Distance';
  String get listedHoursLabel => isRomanian ? 'Program afișat' : 'Listed hours';
  String get hoursGuidance =>
      isRomanian ? 'Informații despre program' : 'Hours guidance';
  String get bestTime => isRomanian ? 'Moment recomandat' : 'Best time';
  String get eventTime => isRomanian ? 'Ora evenimentului' : 'Event time';
  String get eventStatus =>
      isRomanian ? 'Starea evenimentului' : 'Event status';
  String get listedPrice => isRomanian ? 'Preț afișat' : 'Listed price';
  String get released => isRomanian ? 'Lansat' : 'Released';
  String get genres => isRomanian ? 'Genuri' : 'Genres';
  String get openDirections =>
      isRomanian ? 'Deschide traseul' : 'Open directions';
  String sourceAction(String type) => switch (type) {
        'movie' => isRomanian ? 'Vezi sursa filmului' : 'View movie source',
        'event' =>
          isRomanian ? 'Vezi sursa evenimentului' : 'View event source',
        _ => isRomanian ? 'Vezi sursa locației' : 'View place source',
      };
  String get linkOpenFailed => isRomanian
      ? 'Linkul nu a putut fi deschis. Încearcă din nou.'
      : 'Could not open that link. Please try again.';

  String get hourlyLoadFailed => isRomanian
      ? 'Prognoza orară nu a putut fi încărcată. Planul zilnic este în continuare disponibil.'
      : 'Hourly weather could not be loaded. The daily plan is still available.';
  String get ideasLoadFailed => isRomanian
      ? 'Ideile nu au putut fi încărcate. Verifică API-ul și încearcă din nou.'
      : 'Ideas could not be loaded. Check the API and try again.';
  String get showtimesLoadFailed => isRomanian
      ? 'Programul cinematografelor nu a putut fi încărcat. Încearcă din nou.'
      : 'Cinema times could not be loaded. Try again.';
  String get bookingUnavailable => isRomanian
      ? 'Pagina de rezervare nu este disponibilă pentru această oră.'
      : 'A booking page is not available for this showtime.';
  String get bookingOpenFailed => isRomanian
      ? 'Pagina de rezervare a cinematografului nu a putut fi deschisă. Încearcă din nou.'
      : 'Could not open the cinema booking page. Try again.';
  String periodAlreadyHasIdea(String period) => isRomanian
      ? '${filterValue(period)} are deja această idee.'
      : '${filterValue(period)} already has this idea.';
  String addedToPeriod(String period) => isRomanian
      ? 'Adăugat în planul pentru ${filterValue(period).toLowerCase()}.'
      : 'Added to your $period plan.';
  String periodPlanUpdated(String period) => isRomanian
      ? 'Planul pentru ${filterValue(period).toLowerCase()} a fost actualizat.'
      : '${filterValue(period)} plan updated.';
  String get undo => isRomanian ? 'Anulează' : 'Undo';
  String get dayPlanCleared =>
      isRomanian ? 'Planul zilei a fost șters.' : 'Day plan cleared.';
  String get profilesCouldNotLoad => isRomanian
      ? 'Profilurile de preferințe nu au putut fi încărcate.'
      : 'Preference profiles could not be loaded.';
  String get plansSaveFailed => isRomanian
      ? 'Planurile nu au putut fi salvate pe acest dispozitiv.'
      : 'Plans could not be saved on this device.';
  String get dayPlanCopied =>
      isRomanian ? 'Planul zilei a fost copiat.' : 'Day plan copied.';
  String get dayPlanCopyFailed => isRomanian
      ? 'Planul zilei nu a putut fi copiat.'
      : 'Could not copy the day plan.';
  String get openPlanInCalendar =>
      isRomanian ? 'Google Calendar' : 'Google Calendar';
  String get openDayRoute => isRomanian ? 'Deschide traseul' : 'Open route';
  String get calendarPlanOpened => isRomanian
      ? 'Planul este pregătit în Google Calendar.'
      : 'Your plan is ready in Google Calendar.';
  String get calendarPlanOpenFailed => isRomanian
      ? 'Google Calendar nu a putut fi deschis. Încearcă din nou.'
      : 'Could not open Google Calendar. Please try again.';
  String get dayRouteOpenFailed => isRomanian
      ? 'Traseul nu a putut fi deschis în Google Maps.'
      : 'Could not open the route in Google Maps.';
  String get localMovieIdea => isRomanian ? 'Idee de film' : 'Movie idea';
  String get localEvent => isRomanian ? 'Eveniment local' : 'Local event';
  String get localActivity =>
      isRomanian ? 'Activitate locală' : 'Local activity';
  String dayPlanTitle(String location) => isRomanian
      ? 'Planul WeatherWise — $location'
      : 'WeatherWise day plan — $location';

  String get placesSheetTitle =>
      isRomanian ? 'Locuri salvate și recente' : 'Saved & recent places';
  String get placesSheetSubtitle => isRomanian
      ? 'Revino la o prognoză fără să cauți din nou.'
      : 'Return to a forecast without searching again.';
  String get savedPlacesSection =>
      isRomanian ? 'Locuri salvate' : 'Saved places';
  String get recentPlaces => isRomanian ? 'Locuri recente' : 'Recent places';
  String get storedOnDevice => isRomanian
      ? 'Stocate doar pe acest dispozitiv'
      : 'Stored only on this device';
  String get placesEmptyTitle => isRomanian
      ? 'Locurile tale vor apărea aici'
      : 'Your places will appear here';
  String get placesEmptyBody => isRomanian
      ? 'Caută un oraș sau un sat, apoi salvează locurile la care vrei să revii.'
      : 'Search for a city or village, then save the places you want to revisit.';
  String get savedPlacesUpdateFailed => isRomanian
      ? 'Locurile salvate nu au putut fi actualizate.'
      : 'Saved places could not be updated.';

  String chooseLocationTitle(String query) =>
      isRomanian ? 'Care „$query”?' : 'Which $query?';
  String get chooseLocationSubtitle => isRomanian
      ? 'Alege un oraș sau un sat pentru a vedea prognoza pe 14 zile.'
      : 'Choose a city or village to see its 14-day outlook.';
  String get morePlacesFailed => isRomanian
      ? 'Alte locuri nu au putut fi încărcate. Încearcă din nou.'
      : 'More places could not be loaded. Try again.';
  String get findingPlaces =>
      isRomanian ? 'Căutăm alte locuri…' : 'Finding places…';
  String get showMore => isRomanian ? 'Arată mai multe' : 'Show more';
  String get locationDataAttribution => isRomanian
      ? 'Date despre locații oferite de GeoNames prin Open-Meteo'
      : 'Location data by GeoNames via Open-Meteo';
  String residents(int count) {
    final value = _groupInteger(count);
    if (!isRomanian) return '$value residents';
    return '$value ${count == 1 ? 'locuitor' : 'locuitori'}';
  }

  String get chooseReminderTime =>
      isRomanian ? 'Alege ora mementoului' : 'Choose reminder time';
  String get notificationPermissionDenied => isRomanian
      ? 'Permisiunea pentru notificări nu a fost acordată. Activează notificările WeatherWise în setările dispozitivului, apoi încearcă din nou.'
      : 'Notification permission was not granted. Enable WeatherWise notifications in this device’s system settings, then try again.';
  String get remindersSaveFailed => isRomanian
      ? 'Mementourile nu au putut fi actualizate. Verifică setările de notificare ale dispozitivului și încearcă din nou.'
      : 'Reminders could not be updated. Check this device’s notification settings and try again.';
  String get forecastReminders =>
      isRomanian ? 'Mementouri pentru prognoză' : 'Forecast reminders';
  String reminderIntro(String location) => isRomanian
      ? 'Primește un memento discret când prognoza pentru $location conține recomandări de planificare.'
      : 'Get a quiet reminder when $location has planning advisories.';
  String remindersOnFor(String location) => isRomanian
      ? 'Mementouri active pentru $location'
      : 'Reminders on for $location';
  String get remindThisPlace => isRomanian
      ? 'Amintește-mi despre acest loc'
      : 'Remind me about this place';
  String get permissionAfterSave => isRomanian
      ? 'Permisiunea este cerută doar după ce salvezi.'
      : 'Permission is requested only after you save.';
  String remindersFollowOther(String location) => isRomanian
      ? 'Mementourile urmăresc acum $location. Activarea aici va înlocui acel loc.'
      : 'Reminders currently follow $location. Turning this on will replace that place.';
  String get reminderTime => isRomanian ? 'Ora mementoului' : 'Reminder time';
  String get conditions => isRomanian ? 'Condiții' : 'Conditions';
  String get allPlanningAdvisories => isRomanian
      ? 'Toate recomandările de planificare'
      : 'All planning advisories';
  String get highPriorityOnly =>
      isRomanian ? 'Doar prioritate ridicată' : 'High priority only';
  String get reminderTimezoneNote => isRomanian
      ? 'Orele folosesc fusul acestui dispozitiv. Acestea sunt mementouri pentru prognoză, nu alerte oficiale de urgență.'
      : 'Times use this device’s timezone. These are forecast reminders, not official emergency alerts.';
  String get close => isRomanian ? 'Închide' : 'Close';
  String get saveReminders =>
      isRomanian ? 'Salvează mementourile' : 'Save reminders';
  String get remindersUnsupported => isRomanian
      ? 'Mementourile programate sunt disponibile momentan în aplicațiile Android, iOS și macOS.'
      : 'Scheduled reminders are currently available in the Android, iOS, and macOS apps.';

  String get planAroundForecast => isRomanian
      ? 'Planifică în funcție de această prognoză'
      : 'Plan around this forecast';
  String get advisoryDisclaimer => isRomanian
      ? 'Recomandare bazată pe prognoză, nu avertizare meteo oficială.'
      : 'Forecast guidance, not an official weather warning.';
  String moreConditions(int count) => isRomanian
      ? ' Încă $count ${count == 1 ? 'condiție de verificat' : 'condiții de verificat'}.'
      : ' $count more ${count == 1 ? 'condition' : 'conditions'} to review.';
  String get notificationAdvisoryDisclaimer => isRomanian
      ? ' Doar recomandare bazată pe prognoză — nu este o avertizare meteo oficială.'
      : ' Forecast guidance only—not an official weather warning.';
  String advisoryTitle(String code, String fallback) {
    if (!isRomanian) return fallback;
    return switch (code) {
      'extreme_weather' => 'Sunt posibile condiții severe',
      'storm' => 'Risc de furtună',
      'snow' => 'Ninsoarea poate afecta deplasarea',
      'low_visibility' => 'Vizibilitate redusă posibilă',
      'heavy_rain' => 'Ploaie abundentă probabilă',
      'rain' => 'O parte ploioasă a zilei',
      'very_strong_wind' => 'Vânt foarte puternic',
      'strong_wind' => 'Vânt puternic',
      'high_heat' => 'Temperaturi foarte ridicate',
      'severe_cold' => 'Ger puternic',
      'extreme_uv' => 'Expunere UV extremă',
      'very_high_uv' => 'Expunere UV foarte ridicată',
      _ => fallback,
    };
  }

  String advisoryMessage(String code, String fallback) {
    if (!isRomanian) return fallback;
    return switch (code) {
      'extreme_weather' =>
        'Păstrează planurile flexibile și verifică avertizările oficiale locale înainte să pleci.',
      'storm' =>
        'Preferă planurile la adăpost și verifică avertizările oficiale locale înainte de deplasare.',
      'snow' =>
        'Alocă timp suplimentar deplasării și confirmă traseele înainte să pleci.',
      'low_visibility' =>
        'Alocă timp suplimentar deplasării, mai ales dimineața devreme sau seara.',
      'heavy_rain' =>
        'Alege planuri potrivite pentru ploaie și alocă timp suplimentar deplasărilor locale.',
      'rain' =>
        'Păstrează o variantă la interior și verifică prognoza orară înainte să pleci.',
      'very_strong_wind' =>
        'Evită traseele exterioare expuse și verifică avertizările oficiale locale.',
      'strong_wind' =>
        'Preferă traseele adăpostite și reconsideră activitățile în aer liber expuse.',
      'high_heat' =>
        'Mută activitățile solicitante în aer liber în afara celei mai fierbinți perioade a zilei.',
      'severe_cold' =>
        'Limitează activitățile lungi în aer liber și verifică condițiile locale de deplasare.',
      'extreme_uv' =>
        'Evită expunerea prelungită în jurul prânzului și verifică recomandările locale de protecție solară.',
      'very_high_uv' =>
        'Caută umbră în jurul prânzului și include protecție solară în planurile în aer liber.',
      _ => fallback,
    };
  }

  String _groupInteger(int value) {
    final digits = value.toString();
    final separator = isRomanian ? '.' : ',';
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  String recommendationReason(String reason) {
    if (!isRomanian) return reason;
    final timed =
        RegExp(r'^Fits your (.+) plan and this forecast$').firstMatch(reason);
    if (timed != null) {
      return 'Se potrivește planului pentru ${filterValue(timed.group(1)!).toLowerCase()} și acestei prognoze';
    }
    final movieMood =
        RegExp(r'^Matches your (.+) movie mood$').firstMatch(reason);
    if (movieMood != null) {
      return 'Se potrivește preferinței tale pentru filme ${filterValue(movieMood.group(1)!).toLowerCase()}';
    }
    final activityKind =
        RegExp(r'^A (.+) pick suited to this forecast$').firstMatch(reason);
    if (activityKind != null) {
      return 'O alegere de ${filterValue(activityKind.group(1)!).toLowerCase()} potrivită acestei prognoze';
    }
    final setting = RegExp(r'^Matches your (.+) preference for this day$')
        .firstMatch(reason);
    if (setting != null) {
      return 'Se potrivește preferinței tale pentru ${filterValue(setting.group(1)!).toLowerCase()} în această zi';
    }
    final distance = RegExp(r'^A weather-friendly option ([0-9.]+) km away$')
        .firstMatch(reason);
    if (distance != null) {
      return 'O opțiune potrivită vremii, la ${distance.group(1)} km';
    }
    const suitedPrefix = 'Especially suited to ';
    const suitedSuffix = ' weather';
    if (reason.startsWith(suitedPrefix) && reason.endsWith(suitedSuffix)) {
      final condition = reason.substring(
        suitedPrefix.length,
        reason.length - suitedSuffix.length,
      );
      return 'Potrivit în mod special pentru vreme ${weatherLabel(condition).toLowerCase()}';
    }
    const shelteredPrefix = 'A sheltered choice for ';
    const shelteredSuffix = ' conditions';
    if (reason.startsWith(shelteredPrefix) &&
        reason.endsWith(shelteredSuffix)) {
      final condition = reason.substring(
        shelteredPrefix.length,
        reason.length - shelteredSuffix.length,
      );
      return 'O alegere la adăpost pentru condiții de ${weatherLabel(condition).toLowerCase()}';
    }
    return switch (reason) {
      'Makes the most of the clear outdoor window' =>
        'Profită de intervalul senin pentru activități afară',
      'A flexible match for this forecast' =>
        'O alegere flexibilă pentru această prognoză',
      'Scheduled locally for this forecast day; venue setting is unverified' =>
        'Programat local în ziua acestei prognoze; mediul locației nu este verificat',
      _ => reason,
    };
  }

  String planningNoteMessage(String code, String message) {
    if (!isRomanian) return message;
    if (code == 'very_high_uv' || code == 'extreme_uv') {
      final value =
          RegExp(r'UV peaks at ([0-9.]+)').firstMatch(message)?.group(1);
      return value == null
          ? 'Radiația UV este ridicată; caută umbră la prânz și folosește protecție solară.'
          : 'UV atinge $value; caută umbră la prânz și folosește protecție solară.';
    }
    return message;
  }
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppStrings.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale));

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

---
name: "Atlas de lumină"
description: "A sunlit travel atlas that turns forecast evidence into one practical day plan."
colors:
  warm-ivory: "#FFF9ED"
  atlas-paper: "#FFFEFB"
  atlas-ink: "#153A59"
  muted-ink: "#587083"
  atlas-azure: "#168AAD"
  sky-wash: "#D9F1FA"
  sunlight-gold: "#FFC94A"
  pale-gold: "#FFF1BB"
  atlas-coral: "#F26B4A"
  plan-mint: "#DDF3E9"
  atlas-teal: "#197B73"
  mineral-line: "#DCE4E2"
  rain-blue: "#5BA9D1"
  cloud-gray: "#91A6B4"
typography:
  display:
    fontFamily: "Georgia, ui-serif, serif"
    fontSize: "118px"
    fontWeight: 500
    lineHeight: 0.82
    letterSpacing: "-3px"
  headline:
    fontFamily: "Georgia, ui-serif, serif"
    fontSize: "28px"
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: "-0.7px"
  title:
    fontFamily: "Georgia, ui-serif, serif"
    fontSize: "22px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.4px"
  body:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.42
    letterSpacing: "normal"
  label:
    fontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    fontSize: "14px"
    fontWeight: 700
    lineHeight: 1.42
    letterSpacing: "normal"
rounded:
  chip: "10px"
  tab: "12px"
  surface: "14px"
  overlay: "16px"
  hero: "24px"
  pill: "999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  control: "14px"
  lg: "20px"
  xl: "24px"
  section: "32px"
  major: "40px"
components:
  plan-action:
    backgroundColor: "{colors.sunlight-gold}"
    textColor: "{colors.atlas-ink}"
    typography: "{typography.label}"
    rounded: "{rounded.surface}"
    padding: "15px 24px"
    height: "48px"
  location-search:
    backgroundColor: "rgba(255, 255, 255, 0.94)"
    textColor: "{colors.atlas-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.surface}"
    height: "54px"
  plan-strip:
    backgroundColor: "rgba(255, 254, 251, 0.97)"
    textColor: "{colors.atlas-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.surface}"
    padding: "18px 16px 18px 20px"
  forecast-tab:
    backgroundColor: "{colors.atlas-paper}"
    textColor: "{colors.atlas-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.tab}"
    padding: "13px 13px 10px"
    width: "142px"
    height: "148px"
  trend-surface:
    backgroundColor: "{colors.atlas-paper}"
    textColor: "{colors.atlas-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.surface}"
    padding: "4px 20px"
  recommendation-card:
    backgroundColor: "{colors.atlas-paper}"
    textColor: "{colors.atlas-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.surface}"
    padding: "12px 8px 12px 14px"
  account-panel:
    backgroundColor: "{colors.atlas-paper}"
    textColor: "{colors.atlas-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.surface}"
    padding: "24px"
  trip-library-row:
    backgroundColor: "{colors.atlas-paper}"
    textColor: "{colors.atlas-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.surface}"
    padding: "18px"
---

# Design System: Atlas de lumină

## Overview

**Creative North Star: "Atlas de lumină"**

WeatherWise is a bright European travel atlas, not a dark weather dashboard. A quiet paper navigation row opens into an asymmetric daylight field: editorial temperature, precise weather narrative, a broad cartographic arc, a condition-aware sky, and one white planning strip. The sequence is deliberate—search a place, read its daylight story, scan chromatic forecast tabs, then open one practical plan.

Warm ivory paper and atlas-blue ink establish calm authority. Azure rules, golden daylight, coral and mint accents add optimism without turning the interface into a generic dashboard grid. Display weather and section titles use bookish Georgia with the platform serif fallback; controls, dense facts, and explanatory copy use the platform system sans. Material 3 and native navigation behavior remain the interaction foundation.

The approved direction is `.impeccable/mocks/decision/atlas-de-lumina.png`, selected on 2026-10-06 from built-in ImageGen exploration and recorded by its adjacent prompt and JSON sidecar. Direction seed `97c9e211` is the reproducibility key. The implemented visual truth is `frontend/lib/theme/atlas_theme.dart` plus the home and trip-planner surfaces; `.impeccable/review/desktop.png` (1280×720), `.impeccable/review/mobile.png` (390×844), and the `trip-planner-result-{desktop,mobile}.png` captures are the shipped review evidence. Disposition: **SHIP**. Preserve this system rather than merging it with the retired Forecast Focus identity.

**Key Characteristics:**

- Bright paper navigation and an authored, condition-aware daylight field.
- Editorial serif temperature and headings paired with highly legible system sans UI.
- One white plan strip as the bridge between forecast facts and recommendations.
- Chromatic forecast tabs that behave like an atlas index, not a stack of cards.
- Fine map-like rules, tabular numerals, restrained depth, and generous whitespace.
- Location-symbolic hero photography and real recommendation media, with attributed provider imagery and clearly labeled illustrative seed assets.
- Finite fade-and-slide state changes that become instant when reduced motion is requested.
- Complete English/Romanian copy may wrap without changing hierarchy or discarding state.
- A responsive trip-planner form resolves into a quiet, provider-attributed day timeline without inventing certainty, availability, or quality.
- Account access and the personal trip library extend the same daylight-and-paper system with explicit restoring, busy, empty, error, and destructive states.

## Colors

The palette is luminous, warm, and cartographic. Ivory and paper carry most of the screen; ink supplies authority; azure carries interaction and forecast structure; gold is the unmistakable primary planning action. Coral, mint, rain blue, and cloud gray are accents, never competing full-page themes.

### Primary

- **Atlas Ink** (`atlas-ink`): Wordmark, primary text, editorial temperature, and high-confidence icons.
- **Atlas Azure** (`atlas-azure`): Interactive emphasis, chart structure, fact icons, and selected forecast cues.
- **Sunlight Gold** (`sunlight-gold`): The single primary planning action and sunlight emphasis.

### Secondary

- **Sky Wash** (`sky-wash`): Azure's quiet container and selected-state support.
- **Atlas Teal and Plan Mint** (`atlas-teal`, `plan-mint`): Recommendation signal and positive planning context.
- **Atlas Coral** (`atlas-coral`): Sparing warm editorial accent; never a second primary CTA.
- **Rain Blue and Cloud Gray** (`rain-blue`, `cloud-gray`): Weather-specific accents and fallback artwork.

### Neutral

- **Warm Ivory** (`warm-ivory`): The continuous scaffold and opening stop of every daylight field.
- **Atlas Paper** (`atlas-paper`): Navigation, plan strip, forecast tabs, chart and recommendation surfaces.
- **Muted Ink** (`muted-ink`): Dates, provenance, provider caveats, and secondary explanations.
- **Mineral Line** (`mineral-line`): Fine borders, dividers, chart datums, and inactive tab outlines.

### Named Rules

**The Daylight Owns the Canvas Rule.** Ivory and paper remain dominant; weather color changes the atmosphere and tab accent, not the entire planning stream.

**The One Golden Action Rule.** Gold identifies the primary next step for the selected day. Do not spend it on generic decoration or several equal actions.

**The Semantic Weather Rule.** Forecast states always pair color with icon, label, border, or selection semantics; color alone never carries meaning.

## Typography

**Display Font:** Georgia with the platform serif fallback.
**Body Font:** Platform system sans (Roboto on Android, San Francisco on Apple platforms, Segoe UI on Windows/web fallback).

**Character:** Georgia makes weather feel like an editorial travel guide rather than telemetry. The system sans keeps search, facts, controls, attribution, and multilingual copy immediate and trustworthy. Numeric weather values use tabular figures wherever alignment matters.

### Hierarchy

- **Display** (500, 118sp wide / 78sp compact, 0.82): Selected temperature; no other element competes with it.
- **Headline** (600, 28sp, 1.15): Weather condition and the strongest editorial section title.
- **Title** (600, 22sp, 1.25): Forecast, chart, recommendation, and planning section framing.
- **Body** (400, 14sp, 1.42): Supporting explanations, metadata, reasons, and state copy.
- **Label** (700, 14sp, 1.42): Actions, weather facts, forecast-day anchors, and compact status text.

### Named Rules

**The Editorial-Utility Split Rule.** Georgia is for the weather story and object titles; system sans is for interaction, dense facts, and operational copy.

**The Forecast First Rule.** Temperature owns display scale. Preserve its visual priority even when Romanian copy or large text increases surrounding height.

**The Action Labels Stay Sans Rule.** Every actionable label—including trip creation, retry, date picking, dropdowns, and linked itinerary rows—uses the platform system sans at a decisive weight. Never inherit Georgia merely because the action sits beside an editorial heading.

## Layout

The home surface is one continuous atlas spread: brand/search navigation, daylight story, plan strip, horizontal 14-day tab rail, trend chart, advisories/hourly context, and recommendations. The broad composition and downstream content share an 1180dp maximum width. Default horizontal gutters are 20dp; the recommendation stream may tighten to 16dp. Search is capped at 500dp on wide layouts and its suggestion overlay matches the field width with an 8dp gap and 340dp maximum height.

At 720dp and wider, brand and search share a row, and temperature and weather narrative share a baseline. Below 720dp, brand and search stack. Below 520dp—or above 1.15× text scaling—temperature and narrative also stack. The plan strip becomes a row at 760dp and stacks primary action, recommendation signal, then facts below that threshold. The forecast rail never compresses into a grid: it remains horizontally scrollable, with 142dp tabs and a 152dp selected tab, and scales its 148dp baseline height up to 1.35× for larger text.

The trend header stacks below 600dp or above 1.3× text scaling, and the chart may scroll horizontally rather than crush labels. Recommendations use three columns from 920dp, two from 620dp, and one below 620dp. Compact screens preserve the same sequence as desktop; they do not become miniature versions of the wide composition.

The trip planner uses the same 1180dp measure and 20dp gutters. Its intro text and location stamp share a row from 760dp and stack below it. The planning form presents dates, party size, pace, transport, and exploration radius as equal columns from 1040dp; below that they become one ordered vertical flow with 18dp separation. A fine divider introduces one optional inline personalization section with three wrapped chip groups—interests, dietary intent, and meal budget—rather than nested cards. Keep the gold build action after every control and reachable without horizontal scrolling, including at 1.6× text scaling. Day results remain a single chronological timeline at every width: time rail, circular category marker, and flexible content. The pale-sky rhythm band stays horizontal when space permits and stacks its heading, facts, and description below 620dp or above 1.2× text scaling. On compact screens, preserve the rail rather than replacing it with disconnected cards; titles, descriptions, source lines, ratings, review counts, distance, and timing facts wrap inside the content column.

Trip-planner and saved-trip app bars remain pinned and fully opaque Atlas Paper while long plans scroll beneath them. They may condense the title, but never become transparent, float over itinerary text, or obscure the continuous time rail.

Account access uses a full-width pale-gold-to-sky introduction band with the signature 24dp lower curve, followed by one centered paper form capped at 520dp. The signed-in summary and actions widen only to 760dp. Personal-trip lists keep 20dp gutters and one full-width row per trip; metadata flexes and wraps before the trailing delete and disclosure controls are compressed. Saved-trip details remain a single reading column of outlined day surfaces rather than switching to a dashboard grid.

Spacing follows a tight 4/8/12/14/20/24/32/40dp rhythm. Safe-area insets protect native chrome. Controls meet at least 48dp on Android and 44pt on iOS, copy wraps naturally, and provider attribution remains visible.

**The Same Story, New Measure Rule.** Responsive adaptation changes stacking and column count, never the information order or the plan-strip handoff.

**The Reachable Overlay Rule.** Predictive place results stay anchored over the daylight field without reflowing it; long sheets scroll their variable content while completion actions remain reachable.

**The Chronology Survives Compression Rule.** The trip timeline keeps one top-to-bottom time rail on compact and wide layouts; responsive changes may wrap metadata, but never reorder the day's slots or hide an unfilled period.

## Elevation & Depth

Atlas de lumină is paper-flat by default. Hierarchy comes from atmospheric color, white space, fine rules, clipping, and tonal surfaces. The plan strip and focused account form share one soft ambient shadow (`0 10px 24px rgba(94, 109, 101, 0.11)`) to mark a single handoff or task surface. The trend surface uses a quieter paper lift (`0 8px 22px rgba(94, 109, 101, 0.06)`). Predictive search alone uses transient Material elevation 8 with a 24% black shadow. Forecast tabs, recommendation cards, account summaries, and personal-trip rows remain border- or tone-led.

### Named Rules

**The Paper Before Shadow Rule.** Use separation, line, and tonal contrast first; shadow is reserved for the plan handoff and transient overlays.

**The No Glass Rule.** Surfaces are opaque or near-opaque paper. Do not introduce blur-heavy glassmorphism.

## Shapes

The form language is crisp with gentle editorial rounding. Search, primary buttons, plan strip, chart, recommendation cards, and standard inputs use 14dp corners. Forecast tabs and interactive signal rows use 12dp; chips use 10dp; overlays may use 16dp. The daylight field alone receives the broad 24dp lower curve. Full pills are reserved for tiny source/status tags, not every button.

**The One Broad Curve Rule.** The daylight field's 24dp lower edge is the signature large curve; downstream content stays within the disciplined 10–16dp family.

## Components

### Brand and Location Search

- The paper navigation uses a pale-gold sun medallion, Georgia wordmark, compact language control, and one 54dp search field.
- On wide screens, brand and search occupy one row; on compact screens, search moves below the brand with 20dp separation.
- Debounced suggestions appear in an anchored 16dp overlay. Submit opens deliberate ambiguity handling; a direct suggestion selection loads that place.

### Daylight Story

- Build the hero with code: warm-to-condition gradients, a fine cartographic route arc, restrained sun/cloud/rain geometry, and a low atlas skyline.
- The weather class and current wind select the atmosphere. Current conditions lead when present; high/low, rain, wind, UV, daylight and freshness remain factual supporting context.
- Day selection swaps story content with a 320ms fade and 6% rise while the atmosphere changes over 420ms, both ease-out cubic.

### Plan Strip

- Use one near-white 14dp surface containing the best-plan signal, wrapped facts, and the gold 48dp primary action.
- At compact widths, order is primary action, plan signal, then facts. Only a real recommendation receives arrow affordance and “Open details” semantics; loading and weather fallback signals are static.

### Forecast Tabs and Trend Chart

- Tabs are chromatic index cards with a 4dp weather accent along the top. Selection strengthens the accent border, adds an 8% tint, and grows from 142dp to 152dp over 260ms.
- The trend chart is one editorial paper surface with exact datums, horizontal scrolling when necessary, tabular labels, and a 220ms selected-summary swap.

### Recommendation Cards

- Provider-backed recommendations use a 184dp editorial image crop. Their image also appears in the day-plan strip; if loading fails, use a locality-safe curated asset or deterministic type-specific artwork.
- Recommendation titles use Georgia; reasons, availability, caveats, and actions use system sans. Use three/two/one responsive columns at the established thresholds.
- Provider-authored titles, venue names, descriptions, images, URLs, availability and attribution remain provider-authored. WeatherWise-owned chrome is localized.
- The day itinerary offers one outlined suggest/complete action before its morning, afternoon, and evening rows. It fills only empty periods from weather-ranked ideas, preserves manual choices, avoids duplicates, and disappears when the plan is complete; gold remains reserved for the hero's primary action.
- Copy and clear remain compact utility icons in the itinerary heading. Calendar and route handoffs use labeled outlined buttons in a wrapping utility row, so their destination is explicit at both compact and wide widths; neither competes with the gold primary action.
- Every itinerary period carries one quiet, tabular hourly-weather line beneath its activity or empty-state label. It uses the destination's normalized condition, temperature, and rain chance without introducing another card, badge, or competing accent.
- A material weather conflict appears as one calm tertiary callout above the period rows, with a single “Adapt plan” text action. It never uses alarm red, replaces only exposed outdoor stops, and disappears when the plan no longer conflicts with hourly conditions.

### Trip Planner Form and Timeline

- The trip-planner hero extends the daylight field with the same ivory-to-gold-to-sky atmosphere, 24dp lower curve, Georgia heading, and paper location stamp. It is an Atlas de lumină surface, not a new visual identity; keep direction seed `97c9e211` unchanged.
- Dates, pace, transport, and exploration radius live in one paper form with 14dp corners and the plan-handoff shadow. The radius is a labeled 5–50 km control in 5 km steps; show its current numeric value beside the control and repeat the chosen maximum in the resulting plan summary. “50 km” means the farthest permitted stop from the trip's return location, not a promised route length.
- Explain the selected pace directly below its control before generation: Relaxed is 09:00–22:00 with two activities and a free evening; Balanced is 08:30–22:30 with three activities and comfortable pauses; Active is 07:30–22:30 with three activities, shorter pauses, and longer exploration windows. A pace change is plan-defining and invalidates any rendered result.
- Reuse the same optional preferences section in trip creation and the saved-trip editor, prefilled from the saved plan when editing. Keep interests, dietary intent, and meal budget inline in the paper form, introduced by a fine divider and a concise icon-led explanation. Use three labeled wrapping groups: icon-plus-text FilterChips for interests and dietary intent, then single-select ChoiceChips for meal budget. Unselected chips stay paper-white; selected chips use the quiet sky surface with ink text. Changing any chip clears a rendered plan because it changes the recommendation request. Show the compact provider-honesty warning only when dietary intent is selected: search matches do not certify menus, ingredients, allergen safety, or cross-contamination.
- Changing any plan-defining input—date range, pace, transport, or radius—invalidates the rendered plan immediately. Clear the old result and its error state before presenting the new selection; do not visually imply that an earlier itinerary matches unsent inputs. While a replacement is being built, disable the inputs and primary action and name the in-progress state.
- Introduce generated results with one pale-sky rhythm band containing the selected pace, full day span, planned activity count, transport-aware travel buffer, and one plain-language description. Keep this hierarchy intact when it stacks; do not split the facts into separate badges or cards.
- Each day is one outlined paper surface. Its header wraps the day number, localized date, and weather chip; the body uses an 88dp tabular time column, a 34dp semantic marker with a fine mineral connector, and a flexible content column. The connector creates one continuous daily rail. Show both start and end time when the contract provides them, and show duration only when it is known; never derive false precision from a slot window. A compact pale-sky route inset appears only inside a coordinate-backed stop: icon, estimated departure, duration, distance, mode, and origin for a provider-calculated route. When routing is unavailable, switch to muted language that clearly names approximate reserved buffer time, travel mode, and origin; never present the fallback as a calculated route. Add a return-to-base leg only to the final located stop. If a flexible stop moves to absorb travel, state the shift from its original start; if a fixed conflict remains, state its estimated arrival and need to replan. Flag a first calculated departure that begins before the advertised day span, and add a sidewalk/path/cycle-lane caution for calculated walking or bicycle routes. Coordinate-less and unavailable stops receive no route inset rather than guessed metadata. Category color is always paired with a slot label and icon.
- Directly below each day header, place one quiet mint strategy inset with a teal route icon and explicit “Day strategy” label. It summarizes the day's weather and explains which wet intervals stay indoors and which dry windows are used outdoors. Keep it inside the existing day surface, without a second shadow or competing card elevation.
- Before the time rail, use one compact mint logistics band when the day has planned stops. Wrap stops, total travel time, fully known distance, and return time as a single readable sentence of facts rather than separate metric cards. Its final line must say whether the route is calculated or only an estimated allowance; omit unknown distance and say when no coordinate-backed route is available. The band must wrap safely at 320dp and 1.6× text without horizontal scrolling.
- Keep provider attribution directly beneath each provider-authored item. Normalize provider names for display, but do not translate provider-authored titles, descriptions, URLs, availability, or attribution. An item without a provider must not receive a fabricated source line.
- A visible star rating is provider-supplied quality evidence on a five-point scale, never WeatherWise's recommendation score. Pair the one-decimal rating with its review count in text and accessibility semantics; omit the entire rating when the provider supplies none. Live dining candidates require at least 4.0 from at least 10 reviews, and unverified or unavailable meal slots remain visibly unfilled rather than inheriting a plausible-looking rating.
- Use the system sans for form labels, field values, button labels, timeline times, uppercase slot labels, metadata, attribution, rating, review count, and distance. Georgia remains reserved for the trip hero and day-level editorial headings.

**The Preferences Stay in Context Rule.** Personalization belongs inside the existing trip form, after the core controls and before the one gold action. Use wrapped native chips and conditional provider-honesty copy; never promote optional preferences into a competing card, wizard step, or promise of verified dietary safety.

**The Schedule Tells the Truth Rule.** Pace defines the day's actual operating window and activity count. Display contract-provided start/end times, known duration, and routing state consistently from generated result through saved trip. A live route may name duration and distance; a rhythm fallback must say that it is only reserved time. Never invent precision or compress away the free evening promised by Relaxed pace.

**The Route Is Evidence Rule.** Show route metadata only for coordinate-backed stops. Distinguish provider-calculated duration and distance from an explicitly approximate, mode-named buffer; omit an unknown leg instead of guessing it, and close every routed day with one return leg from its final located stop.

**The Return Fits the Day Rule.** Every final return names its estimated arrival when the itinerary supplies enough timing evidence. If that arrival exceeds the pace-defined day end, keep the warning inside the existing route inset with a schedule icon, bold ink copy, and a concrete recovery: shorten the final stop or choose one closer. Do not use a second card, alarm-red fill, or color as the only signal.

**The Partial Travel Day Rule.** Ask for arrival and departure as one compact travel-window control beside the date range; each time remains a native, keyboard-accessible picker with a concrete label. Keep the overall pace band unchanged because it describes a normal full day. On the affected first or last day, add one pale-gold schedule band that states the exact shortened window and why it is shorter. Omit meal and activity periods that fall before arrival or after departure instead of rendering misleading unavailable placeholders. For a one-day trip, validate that departure follows arrival in both Flutter and Rails and keep recovery copy adjacent to the controls.

### Account Access and Session States

- Extend the daylight field into a compact pale-gold-to-sky hero with a Georgia welcome line and calm sans explanation. Account copy explains the benefit without implying that an account is required for weather or anonymous planning.
- Sign-in and registration share one centered 14dp paper panel. A native segmented control changes mode; only registration reveals name and confirmation fields. Inputs use the standard outlined paper treatment, autofill hints, native password visibility control, inline validation, and a single gold submit action.
- Restoring, submitting, authenticated, and failed states are explicit. Disable mode and submit controls while a request is busy; clear password fields after success; announce inline failures as a live region and keep friendly recovery guidance adjacent to the form.
- The signed-in state uses one outlined identity row, then a gold route into the personal library and an outlined sign-out action. Keep account actions system-sans and preserve native Back and autofill behavior.

### Personal Trip Library

- Each saved trip is one full-row paper action with a pale-gold route medallion, strong trip name, muted place/date metadata, a separately labeled delete control, and a disclosure cue. The row opens details; deletion always requires a native confirmation dialog naming the trip.
- Empty, loading, fetch-failure, open-failure, and delete-failure states remain distinct. Use a centered map-led empty state, pull-to-refresh for the library, an outlined retry action for a blocking load failure, and a floating snackbar with retry for a failed deletion.
- Saved-trip details reuse the trip planner's semantic hierarchy at lower density: the summary preserves pace, day span, activities per day, and travel buffer; each day is one outlined paper card; and start/end time, known duration, slot icon, title, optional summary, real provider attribution, and the same route inset form a compact chronological row. Keep route, adjustment, conflict, caution, and final-return states consistent after save and replan; never fabricate source text or timing detail.
- Edit saved-trip settings in a dismissible ivory-paper bottom sheet with a clearly labeled close control, platform-native date and settings controls, and an explicit explanation that saving replaces the suggested itinerary while validation or provider failure preserves the current settings and complete plan. Arrange fields in two columns at expanded widths and one ordered stack on compact screens; keep variable content scrollable, follow safe-area and IME insets, and finish with one gold 48dp “Save and replan” action.
- Place saved-trip weather replanning in one pale-sky explanatory panel before the chronological day list. It carries one 48dp gold action that explicitly refreshes weather and rebuilds the suggested activities and venues; at compact widths or above 1.15× text scaling, stack the action below the copy.
- Confirm before replacement, naming both consequences: suggested stops will be replaced and the current plan will remain if the refresh fails. While the request runs, disable the action and name the work in progress. On success, swap in the returned plan as one complete result; on failure, keep the previous plan visible and offer Retry in transient feedback.
- Give every saved-itinerary row one labeled, ink-on-paper tertiary action with a 48dp target: “Replace stop.” While it runs, pair a spinner with a progress label and disable competing mutations. Distinguish “no alternative found” from provider failure in the row-level copy; both states keep the current stop visible and offer Retry.

**The State Before Transition Rule.** Account and personal-library surfaces always show whether the session or collection is restoring, busy, empty, failed, or ready before offering the next action; never leave stale content looking current during an unresolved request.

**The Complete Replacement Rule.** A saved itinerary remains the trusted visible plan until weather replanning returns a complete replacement. Never clear or partially mutate it during the request; success swaps the whole plan, while failure preserves the prior version and offers a retry.

**The One-Stop Swap Rule.** Replacing one saved stop preserves its time, position, and every other stop. Keep the current stop visible until a complete alternative returns; during the request, name the work, show a spinner, and lock competing mutations. After success, restore baseline rhythm times and recalculate route metadata, schedule fit, and the final return leg for the whole day. No-alternative and provider-failure outcomes use distinct copy, preserve the stop, and offer Retry.

### Motion, Accessibility, and Media Provenance

- Motion is finite: 220–420ms for selection and content changes, plus one 900ms first-entrance atmosphere drawing. When `MediaQuery.disableAnimationsOf` is true, state changes resolve instantly.
- Preserve safe areas, native Back behavior, platform semantics, scalable type, visible focus/pressed states, non-color cues, and minimum platform touch targets.
- The approved ImageGen comp is design evidence, not a shipping city photograph. Its provenance lives in `.impeccable/mocks/decision/atlas-de-lumina.png.json` and `.prompt.txt`; seed `97c9e211` connects the selected world to implementation.
- The hero is photographic and location-specific. Use attributed provider imagery for global locations and the labeled generated Iași panorama for the offline seed experience. Recommendation rasters retain provider attribution; failure falls back to a locality-safe curated asset or authored artwork. Every bundled raster records its source or generation prompt, date, intended use, and credit beside the asset.

## Do's and Don'ts

### Do:

- **Do** preserve the daylight-story → plan-strip → forecast-tabs → chart → ideas sequence at every width.
- **Do** use Georgia for editorial display moments and the system sans for UI and dense facts.
- **Do** keep ivory and paper dominant, with gold reserved for the primary day-planning action.
- **Do** keep every available fact in a responsive wrap and use tabular numerals for weather data.
- **Do** keep search suggestions anchored, reject stale responses, and preserve the full picker for deliberate ambiguity handling.
- **Do** localize WeatherWise-owned copy in English and Romanian without resetting the active location, selected day, expanded context, filters, plans, profiles, or reminders.
- **Do** retain provider attribution and clearly distinguish live, demo, cached, and unverified availability states.
- **Do** clear a rendered trip plan as soon as any plan-defining input or preference changes, then show results only for the submitted dates, pace, transport, radius, interests, dietary intent, and meal budget.
- **Do** keep trip preferences inline, optional, and wrapped at compact widths; use paper for unselected chips, sky for selected chips, and conditional provider-honesty copy for dietary intent.
- **Do** explain pace before generation, then preserve its day span, activity count, travel buffer, start/end times, and known durations in both generated and saved plans.
- **Do** distinguish calculated routes from approximate mode-named buffers, surface schedule adjustments and unresolved conflicts, and preserve the final return leg after a stop replacement.
- **Do** keep the trip timeline chronological and legible at compact widths, with rating, review count, source, and distance allowed to wrap.
- **Do** keep account status and personal-trip loading, empty, error, retry, and deletion outcomes explicit, localized, and compatible with native autofill and navigation.
- **Do** honor reduced motion, safe areas, large text, keyboard reachability, and 48dp Android / 44pt iOS targets.

### Don't:

- **Don't** revive the dark Forecast Focus palette, teal atmospheric slab, or sans-only identity.
- **Don't** turn the page into a generic dashboard grid or elevate every object into a card.
- **Don't** show a landmark from another place, imply that illustrative imagery is documentary, or ship an unattributed raster.
- **Don't** use the approved comp itself as live geographic evidence; it is directional artwork.
- **Don't** introduce glassmorphism, gradient text, looping atmosphere motion, or decorative shadows.
- **Don't** use color alone for weather, selection, availability, warning, or error meaning.
- **Don't** make loading or fallback plan signals look tappable, or let a stale plan survive a place/day change.
- **Don't** imply that an account is required for the core forecast flow, expose a private trip before authentication resolves, or delete a trip without confirmation that names it.
- **Don't** present a provider rating as a WeatherWise score, show a star without its review count, invent a dining rating, or imply that a 50 km radius is the itinerary's total distance.
- **Don't** place optional trip preferences in nested cards or a separate wizard step, and don't imply that a dietary search match is a verified menu or allergen-safety guarantee.
- **Don't** invent an exact activity duration, hide a contract-provided end time, or schedule a third activity into the Relaxed pace's free evening.
- **Don't** guess a route for a coordinate-less stop, present reserved buffer time as provider-calculated travel, or omit an early-departure or walking/bicycle caution when the route requires it.
- **Don't** translate provider-authored names, descriptions, availability data, URLs, images, or attribution.

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/daily_forecast.dart';
import '../models/forecast_result.dart';
import '../models/location.dart';
import '../models/plan_recommendation.dart';
import '../services/location_imagery.dart';
import '../theme/atlas_theme.dart';
import 'weather_visuals.dart';

class WeatherHero extends StatefulWidget {
  const WeatherHero({
    required this.controller,
    required this.loading,
    required this.onSearch,
    required this.onSearchQueryChanged,
    required this.locationSuggestions,
    required this.locationSuggestionsLoading,
    required this.locationSuggestionsActive,
    required this.locationSuggestionsError,
    required this.onLocationSuggestionSelected,
    required this.onLocationSuggestionsRetry,
    required this.onLocationSuggestionsDismissed,
    required this.result,
    required this.forecast,
    required this.recommendationPreview,
    required this.recommendationPreviewLoading,
    required this.onRecommendationPreviewPressed,
    required this.ideasExpanded,
    required this.onIdeasPressed,
    required this.onPlacesPressed,
    required this.onNotificationsPressed,
    required this.notificationsEnabled,
    required this.notificationsSupported,
    required this.currentLocationSaved,
    required this.onToggleSaved,
    required this.refreshing,
    required this.onRefresh,
    required this.onLocaleChanged,
    required this.onPlanTripPressed,
    this.onAccountPressed,
    this.accountLabel,
    super.key,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSearch;
  final ValueChanged<String> onSearchQueryChanged;
  final List<Location> locationSuggestions;
  final bool locationSuggestionsLoading;
  final bool locationSuggestionsActive;
  final bool locationSuggestionsError;
  final ValueChanged<Location> onLocationSuggestionSelected;
  final VoidCallback onLocationSuggestionsRetry;
  final VoidCallback onLocationSuggestionsDismissed;
  final ForecastResult? result;
  final DailyForecast? forecast;
  final PlanRecommendation? recommendationPreview;
  final bool recommendationPreviewLoading;
  final VoidCallback? onRecommendationPreviewPressed;
  final bool ideasExpanded;
  final VoidCallback? onIdeasPressed;
  final VoidCallback onPlacesPressed;
  final VoidCallback? onNotificationsPressed;
  final bool notificationsEnabled;
  final bool notificationsSupported;
  final bool currentLocationSaved;
  final VoidCallback? onToggleSaved;
  final bool refreshing;
  final VoidCallback? onRefresh;
  final ValueChanged<Locale>? onLocaleChanged;
  final VoidCallback? onPlanTripPressed;
  final VoidCallback? onAccountPressed;
  final String? accountLabel;

  @override
  State<WeatherHero> createState() => _WeatherHeroState();
}

class _WeatherHeroState extends State<WeatherHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Timer _freshnessTicker;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _freshnessTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted &&
          widget.result?.updatedAt != null &&
          !(widget.result?.isDemo ?? true)) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else if (!_entrance.isCompleted) {
      _entrance.forward();
    }
  }

  @override
  void didUpdateWidget(covariant WeatherHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.forecast?.id != widget.forecast?.id &&
        !MediaQuery.disableAnimationsOf(context)) {
      _entrance
        ..value = .35
        ..forward();
    }
  }

  @override
  void dispose() {
    _freshnessTicker.cancel();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final forecast = widget.forecast;
    final visuals = WeatherVisuals.forForecast(
      forecast,
      weatherClass: forecast?.current?.weatherClass,
      windSpeedKph: forecast?.current?.windSpeedKph,
    );
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 420);
    final location = widget.result?.location;
    final heroAsset = LocationImagery.heroAsset(location);
    final heroUrl = location?.heroImageUrl;
    final hasLocationPhoto = heroAsset != null || heroUrl != null;
    final photoTop = MediaQuery.sizeOf(context).width < 720 ? 126.0 : 78.0;
    final ImageProvider<Object>? heroImage = heroUrl != null
        ? NetworkImage(heroUrl)
        : heroAsset == null
            ? null
            : AssetImage(heroAsset);
    final content = SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandSearch(
                  controller: widget.controller,
                  loading: widget.loading,
                  interactionLocked: widget.loading || widget.refreshing,
                  onSearch: widget.onSearch,
                  onSearchQueryChanged: widget.onSearchQueryChanged,
                  locationSuggestions: widget.locationSuggestions,
                  locationSuggestionsLoading: widget.locationSuggestionsLoading,
                  locationSuggestionsActive: widget.locationSuggestionsActive,
                  locationSuggestionsError: widget.locationSuggestionsError,
                  onLocationSuggestionSelected:
                      widget.onLocationSuggestionSelected,
                  onLocationSuggestionsRetry: widget.onLocationSuggestionsRetry,
                  onLocationSuggestionsDismissed:
                      widget.onLocationSuggestionsDismissed,
                  onPlacesPressed: widget.onPlacesPressed,
                  onNotificationsPressed: widget.onNotificationsPressed,
                  notificationsEnabled: widget.notificationsEnabled,
                  notificationsSupported: widget.notificationsSupported,
                  onLocaleChanged: widget.onLocaleChanged,
                  onPlanTripPressed: widget.onPlanTripPressed,
                  onAccountPressed: widget.onAccountPressed,
                  accountLabel: widget.accountLabel,
                ),
                if (forecast != null && widget.result != null) ...[
                  SizedBox(
                    height: MediaQuery.sizeOf(context).width < 600 ? 24 : 38,
                  ),
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, .06),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _ForecastStory(
                      key: ValueKey(forecast.id),
                      result: widget.result!,
                      forecast: forecast,
                      recommendationPreview: widget.recommendationPreview,
                      recommendationPreviewLoading:
                          widget.recommendationPreviewLoading,
                      onRecommendationPreviewPressed:
                          widget.onRecommendationPreviewPressed,
                      ideasExpanded: widget.ideasExpanded,
                      onIdeasPressed: widget.onIdeasPressed!,
                      currentLocationSaved: widget.currentLocationSaved,
                      onToggleSaved: widget.onToggleSaved!,
                      refreshing: widget.refreshing,
                      onRefresh: widget.onRefresh,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 52),
                  Text(
                    strings.emptyTitle,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AtlasColors.ink,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.1,
                          height: 1.08,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.emptySubtitle,
                    style: const TextStyle(color: AtlasColors.mutedInk),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return AnimatedContainer(
      duration: motion,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        image: heroImage == null
            ? null
            : DecorationImage(
                image: heroImage,
                fit: BoxFit.cover,
                alignment: const Alignment(.35, -1),
              ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _atlasHeroColors(visuals.mood),
          stops: const [0, .46, 1],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (hasLocationPhoto)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFFFF9ED),
                      Color(0xF2FFF9ED),
                      Color(0x9EFFF9ED),
                      Color(0x1AFFF9ED),
                    ],
                    stops: [0, .28, .56, 1],
                  ),
                ),
              ),
            ),
          if (hasLocationPhoto)
            Positioned(
              top: photoTop + 16,
              right: 20,
              child: _LocationImageCredit(
                locationName: location!.name,
                credit: heroUrl == null
                    ? strings.illustrativeImage
                    : location.imageAttribution,
              ),
            ),
          if (hasLocationPhoto)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xB8FFF9ED), Color(0x00FFF9ED)],
                    stops: [0, .38],
                  ),
                ),
              ),
            ),
          if (!hasLocationPhoto)
            AnimatedBuilder(
              animation: _entrance,
              builder: (context, child) => Positioned.fill(
                child: CustomPaint(
                  painter: _AtmospherePainter(
                    progress: Curves.easeOutCubic.transform(_entrance.value),
                    mood: visuals.mood,
                  ),
                ),
              ),
            ),
          content,
        ],
      ),
    );
  }
}

class _LocationImageCredit extends StatelessWidget {
  const _LocationImageCredit({
    required this.locationName,
    required this.credit,
  });

  final String locationName;
  final String? credit;

  @override
  Widget build(BuildContext context) {
    if (credit == null || credit!.isEmpty) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AtlasColors.paper.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F153A59),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 16, color: AtlasColors.ink),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$locationName · $credit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AtlasColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSearch extends StatelessWidget {
  const _BrandSearch({
    required this.controller,
    required this.loading,
    required this.interactionLocked,
    required this.onSearch,
    required this.onSearchQueryChanged,
    required this.locationSuggestions,
    required this.locationSuggestionsLoading,
    required this.locationSuggestionsActive,
    required this.locationSuggestionsError,
    required this.onLocationSuggestionSelected,
    required this.onLocationSuggestionsRetry,
    required this.onLocationSuggestionsDismissed,
    required this.onPlacesPressed,
    required this.onNotificationsPressed,
    required this.notificationsEnabled,
    required this.notificationsSupported,
    required this.onLocaleChanged,
    required this.onPlanTripPressed,
    this.onAccountPressed,
    this.accountLabel,
  });

  final TextEditingController controller;
  final bool loading;
  final bool interactionLocked;
  final VoidCallback onSearch;
  final ValueChanged<String> onSearchQueryChanged;
  final List<Location> locationSuggestions;
  final bool locationSuggestionsLoading;
  final bool locationSuggestionsActive;
  final bool locationSuggestionsError;
  final ValueChanged<Location> onLocationSuggestionSelected;
  final VoidCallback onLocationSuggestionsRetry;
  final VoidCallback onLocationSuggestionsDismissed;
  final VoidCallback onPlacesPressed;
  final VoidCallback? onNotificationsPressed;
  final bool notificationsEnabled;
  final bool notificationsSupported;
  final ValueChanged<Locale>? onLocaleChanged;
  final VoidCallback? onPlanTripPressed;
  final VoidCallback? onAccountPressed;
  final String? accountLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final strings = AppStrings.of(context);
        final wide = constraints.maxWidth >= 1000;
        final medium = constraints.maxWidth >= 520;
        final brand = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AtlasColors.paleGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wb_sunny_outlined,
                color: Color(0xFFD99200),
              ),
            ),
            const SizedBox(width: 11),
            const Text(
              'WeatherWise',
              style: TextStyle(
                color: AtlasColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                fontFamily: 'Georgia',
                letterSpacing: -.5,
              ),
            ),
            if (onLocaleChanged != null) ...[
              const SizedBox(width: 8),
              PopupMenuButton<Locale>(
                tooltip: strings.language,
                enabled: !interactionLocked,
                icon: const Icon(
                  Icons.language_rounded,
                  color: AtlasColors.ink,
                ),
                onSelected: onLocaleChanged,
                itemBuilder: (context) => [
                  _languageItem(
                    context,
                    const Locale('ro'),
                    strings.romanian,
                  ),
                  _languageItem(
                    context,
                    const Locale('en'),
                    strings.english,
                  ),
                ],
              ),
            ],
            if (onAccountPressed != null)
              IconButton(
                tooltip: accountLabel ??
                    (strings.isRomanian ? 'Contul meu' : 'My account'),
                onPressed: interactionLocked ? null : onAccountPressed,
                icon: Icon(
                  accountLabel == null
                      ? Icons.person_outline_rounded
                      : Icons.account_circle_rounded,
                  color: AtlasColors.ink,
                ),
              ),
          ],
        );
        final search = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 500 : double.infinity),
          child: _LocationSearchBox(
            controller: controller,
            loading: loading,
            interactionLocked: interactionLocked,
            onSearch: onSearch,
            onChanged: onSearchQueryChanged,
            suggestions: locationSuggestions,
            suggestionsLoading: locationSuggestionsLoading,
            suggestionsActive: locationSuggestionsActive,
            suggestionsError: locationSuggestionsError,
            onSuggestionSelected: onLocationSuggestionSelected,
            onRetry: onLocationSuggestionsRetry,
            onDismissed: onLocationSuggestionsDismissed,
            onPlacesPressed: onPlacesPressed,
            onNotificationsPressed: onNotificationsPressed,
            notificationsEnabled: notificationsEnabled,
            notificationsSupported: notificationsSupported,
            onPlanTripPressed: onPlanTripPressed,
            showPlanAction: !medium,
          ),
        );
        final tripButton = OutlinedButton.icon(
          key: const ValueKey('open-trip-planner'),
          onPressed: interactionLocked ? null : onPlanTripPressed,
          icon: const Icon(Icons.route_outlined, size: 19),
          label: Text(
            strings.isRomanian ? 'Planifică o călătorie' : 'Plan a trip',
          ),
        );
        if (wide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              brand,
              const SizedBox(width: 18),
              tripButton,
              const SizedBox(width: 18),
              Expanded(child: search)
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (medium)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [brand, const SizedBox(width: 16), tripButton],
              )
            else ...[
              brand,
            ],
            SizedBox(height: medium ? 14 : 20),
            search,
          ],
        );
      },
    );
  }

  PopupMenuItem<Locale> _languageItem(
    BuildContext context,
    Locale locale,
    String label,
  ) {
    final selected =
        Localizations.localeOf(context).languageCode == locale.languageCode;
    return PopupMenuItem(
      value: locale,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: selected ? const Icon(Icons.check_rounded, size: 20) : null,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _LocationSearchBox extends StatefulWidget {
  const _LocationSearchBox({
    required this.controller,
    required this.loading,
    required this.interactionLocked,
    required this.onSearch,
    required this.onChanged,
    required this.suggestions,
    required this.suggestionsLoading,
    required this.suggestionsActive,
    required this.suggestionsError,
    required this.onSuggestionSelected,
    required this.onRetry,
    required this.onDismissed,
    required this.onPlacesPressed,
    required this.onNotificationsPressed,
    required this.notificationsEnabled,
    required this.notificationsSupported,
    required this.onPlanTripPressed,
    required this.showPlanAction,
  });

  final TextEditingController controller;
  final bool loading;
  final bool interactionLocked;
  final VoidCallback onSearch;
  final ValueChanged<String> onChanged;
  final List<Location> suggestions;
  final bool suggestionsLoading;
  final bool suggestionsActive;
  final bool suggestionsError;
  final ValueChanged<Location> onSuggestionSelected;
  final VoidCallback onRetry;
  final VoidCallback onDismissed;
  final VoidCallback onPlacesPressed;
  final VoidCallback? onNotificationsPressed;
  final bool notificationsEnabled;
  final bool notificationsSupported;
  final VoidCallback? onPlanTripPressed;
  final bool showPlanAction;

  @override
  State<_LocationSearchBox> createState() => _LocationSearchBoxState();
}

class _LocationSearchBoxState extends State<_LocationSearchBox> {
  final _overlay = OverlayPortalController();
  final _link = LayerLink();
  final _focusNode = FocusNode();
  final _tapGroup = Object();

  @override
  void didUpdateWidget(covariant _LocationSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.suggestionsActive && _focusNode.hasFocus) {
        _overlay.show();
      } else if (!widget.suggestionsActive) {
        _overlay.hide();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    _overlay.hide();
    widget.onDismissed();
    _focusNode.unfocus();
    widget.onSearch();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: (context) => CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8),
          showWhenUnlinked: false,
          child: Align(
            alignment: Alignment.topLeft,
            child: TapRegion(
              groupId: _tapGroup,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: .24),
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 340),
                    child: _LocationSuggestions(
                      suggestions: widget.suggestions,
                      loading: widget.suggestionsLoading,
                      error: widget.suggestionsError,
                      onSelected: (location) {
                        _overlay.hide();
                        _focusNode.unfocus();
                        widget.onSuggestionSelected(location);
                      },
                      onRetry: widget.onRetry,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: TapRegion(
          groupId: _tapGroup,
          onTapOutside: (_) {
            _overlay.hide();
            _focusNode.unfocus();
            widget.onDismissed();
          },
          child: CompositedTransformTarget(
            link: _link,
            child: IconTheme(
              data: const IconThemeData(color: Color(0xFF244549)),
              child: SearchBar(
                controller: widget.controller,
                focusNode: _focusNode,
                hintText: strings.searchHint,
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(
                    color: Color(0xFF18373B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                hintStyle: const WidgetStatePropertyAll(
                  TextStyle(color: Color(0xFF5F7375)),
                ),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  Colors.white.withValues(alpha: .94),
                ),
                leading: const Icon(Icons.search_rounded),
                trailing: [
                  if (widget.showPlanAction)
                    IconButton(
                      key: const ValueKey('open-trip-planner-compact'),
                      tooltip: strings.isRomanian
                          ? 'Planifică o călătorie'
                          : 'Plan a trip',
                      onPressed: widget.interactionLocked
                          ? null
                          : widget.onPlanTripPressed,
                      icon: const Icon(Icons.route_outlined),
                    ),
                  IconButton(
                    tooltip: widget.notificationsSupported
                        ? widget.notificationsEnabled
                            ? strings.remindersOn
                            : strings.reminders
                        : strings.remindersNativeOnly,
                    onPressed: widget.interactionLocked
                        ? null
                        : widget.onNotificationsPressed,
                    icon: Icon(
                      widget.notificationsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.savedPlaces,
                    onPressed: widget.interactionLocked
                        ? null
                        : widget.onPlacesPressed,
                    icon: const Icon(Icons.bookmarks_outlined),
                  ),
                  IconButton.filled(
                    tooltip: strings.search,
                    onPressed: widget.interactionLocked ? null : _submit,
                    icon: widget.loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
                onTap: () {
                  if (widget.suggestionsActive) _overlay.show();
                },
                onChanged: (value) {
                  widget.onChanged(value);
                  if (value.trim().length >= 2) _overlay.show();
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationSuggestions extends StatelessWidget {
  const _LocationSuggestions({
    required this.suggestions,
    required this.loading,
    required this.error,
    required this.onSelected,
    required this.onRetry,
  });

  final List<Location> suggestions;
  final bool loading;
  final bool error;
  final ValueChanged<Location> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 5),
            child: Text(
              strings.suggestedPlaces,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (loading)
            _SuggestionStatus(
              icon: const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              message: strings.searchingPlaces,
            )
          else if (error)
            _SuggestionStatus(
              icon: const Icon(Icons.sync_problem_outlined, size: 20),
              message: strings.suggestionsUnavailable,
              action: TextButton(
                onPressed: onRetry,
                child: Text(strings.tryAgain),
              ),
            )
          else if (suggestions.isEmpty)
            _SuggestionStatus(
              icon: const Icon(Icons.location_searching_rounded, size: 20),
              message: strings.noSuggestedPlaces,
            )
          else
            for (final location in suggestions)
              _LocationSuggestionRow(
                location: location,
                onPressed: () => onSelected(location),
              ),
        ],
      ),
    );
  }
}

class _SuggestionStatus extends StatelessWidget {
  const _SuggestionStatus({
    required this.icon,
    required this.message,
    this.action,
  });

  final Widget icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
            if (action != null) action!,
          ],
        ),
      );
}

class _LocationSuggestionRow extends StatelessWidget {
  const _LocationSuggestionRow({
    required this.location,
    required this.onPressed,
  });

  final Location location;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final details = [
      location.adminArea,
      location.countryName ?? location.countryCode,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return Semantics(
      button: true,
      label: location.displayName,
      child: InkWell(
        key: ValueKey('location-suggestion-${location.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        location.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (details.isNotEmpty)
                        Text(
                          details.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.north_west_rounded, size: 19),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForecastStory extends StatelessWidget {
  const _ForecastStory({
    required this.result,
    required this.forecast,
    required this.recommendationPreview,
    required this.recommendationPreviewLoading,
    required this.onRecommendationPreviewPressed,
    required this.ideasExpanded,
    required this.onIdeasPressed,
    required this.currentLocationSaved,
    required this.onToggleSaved,
    required this.refreshing,
    required this.onRefresh,
    super.key,
  });

  final ForecastResult result;
  final DailyForecast forecast;
  final PlanRecommendation? recommendationPreview;
  final bool recommendationPreviewLoading;
  final VoidCallback? onRecommendationPreviewPressed;
  final bool ideasExpanded;
  final VoidCallback onIdeasPressed;
  final bool currentLocationSaved;
  final VoidCallback onToggleSaved;
  final bool refreshing;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final strings = AppStrings.of(context);
        final wide = constraints.maxWidth >= 720;
        final current = forecast.current;
        final temperature = Text(
          '${(current?.temperatureC ?? forecast.maxC).round()}°',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AtlasColors.ink,
                height: .82,
                fontWeight: FontWeight.w500,
                fontSize: wide ? 118 : 78,
                letterSpacing: -3,
              ),
        );
        final narrative = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        result.location.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AtlasColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '· ${result.location.countryCode}',
                        style: const TextStyle(color: AtlasColors.mutedInk),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (onRefresh != null)
                  IconButton(
                    tooltip: result.isDemo
                        ? strings.tryLiveWeather
                        : refreshing
                            ? strings.refreshingForecast
                            : strings.refreshForecast,
                    style: IconButton.styleFrom(
                      foregroundColor: AtlasColors.ink,
                      backgroundColor: AtlasColors.paper.withValues(alpha: .86),
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: refreshing ? null : onRefresh,
                    icon: refreshing
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AtlasColors.azure,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                if (onRefresh != null) const SizedBox(width: 6),
                IconButton(
                  tooltip: currentLocationSaved
                      ? strings.removeSavedPlace(result.location.name)
                      : strings.savePlace(result.location.name),
                  style: IconButton.styleFrom(
                    foregroundColor: AtlasColors.ink,
                    backgroundColor: AtlasColors.paper.withValues(alpha: .86),
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: onToggleSaved,
                  icon: Icon(
                    currentLocationSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
              ],
            ),
            if (result.isDemo) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _SourcePill(
                  label: strings.demoData,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              strings.dayLabel(forecast.date),
              style: const TextStyle(
                color: AtlasColors.mutedInk,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              strings.weatherLabel(current?.label ?? forecast.label),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AtlasColors.ink,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.7,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              current == null
                  ? switch (forecast.activityContext) {
                      'indoor' => strings.indoorContext,
                      'outdoor' => strings.outdoorContext,
                      'caution' => strings.cautionContext,
                      _ => strings.flexibleContext,
                    }
                  : strings.feelsLike(
                      current.apparentTemperatureC,
                      _currentEstimateLabel(
                        strings,
                        current.observedAt,
                        result.updatedAt,
                      ),
                    ),
              style: const TextStyle(
                color: AtlasColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
        final facts = Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _Fact(
              icon: Icons.thermostat_rounded,
              label: current == null
                  ? strings.low(forecast.minC)
                  : strings.highLow(forecast.maxC, forecast.minC),
            ),
            _Fact(
              icon: Icons.water_drop_outlined,
              label: strings.rain(forecast.rainProbability),
            ),
            _Fact(
              icon: Icons.air_rounded,
              label: strings.wind(
                current?.windSpeedKph ?? forecast.windSpeedKph,
              ),
            ),
            if (forecast.uvIndexMax != null)
              _Fact(
                icon: Icons.wb_sunny_outlined,
                label: strings.uv(forecast.uvIndexMax!.toStringAsFixed(1)),
              ),
            if (forecast.daylightRange != null)
              _Fact(
                icon: Icons.wb_twilight_outlined,
                label: strings.sun(forecast.daylightRange!),
              ),
            if (result.isDemo)
              _Fact(
                icon: Icons.science_outlined,
                label: strings.tryLiveWeather,
              )
            else if (result.updatedAt != null)
              _Fact(
                icon: Icons.update_rounded,
                label: strings.updated(
                  DateTime.now().toUtc().difference(
                        result.updatedAt!.toUtc(),
                      ),
                ),
              ),
          ],
        );
        final action = FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AtlasColors.gold,
            foregroundColor: AtlasColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          ),
          onPressed: onIdeasPressed,
          icon: Icon(
            ideasExpanded ? Icons.expand_less_rounded : Icons.auto_awesome,
          ),
          label: Text(
            ideasExpanded ? strings.hideIdeas : strings.seeIdeas,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
        final planArtwork = recommendationPreview == null
            ? LocationImagery.heroAsset(result.location)
            : LocationImagery.recommendationAsset(recommendationPreview!);
        final planImageUrl = recommendationPreview?.imageUrl;
        final planSubtitle = recommendationPreview == null
            ? switch (forecast.activityContext) {
                'indoor' => strings.indoorContext,
                'outdoor' => strings.outdoorContext,
                'caution' => strings.cautionContext,
                _ => strings.flexibleContext,
              }
            : strings.recommendationReason(recommendationPreview!.reason);
        final focusPanel = Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
          decoration: BoxDecoration(
            color: AtlasColors.paper.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1C5E6D65),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, panelConstraints) {
              final signal = _ForecastSignal(
                forecast: forecast,
                recommendation: recommendationPreview,
                loading: recommendationPreviewLoading,
                onPressed: onRecommendationPreviewPressed,
              );
              if (panelConstraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.yourDayPlan,
                      style: const TextStyle(
                        color: AtlasColors.ink,
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AtlasColors.mutedInk),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: action),
                    const SizedBox(height: 12),
                    if (planArtwork == null && planImageUrl == null)
                      signal
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _PlanArtwork(
                            imageUrl: planImageUrl,
                            fallbackAsset: planArtwork,
                            width: 106,
                            height: 88,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: signal),
                        ],
                      ),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.yourDayPlan,
                          style: const TextStyle(
                            color: AtlasColors.ink,
                            fontFamily: 'Georgia',
                            fontWeight: FontWeight.w700,
                            fontSize: 25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          planSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AtlasColors.mutedInk,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 82,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: AtlasColors.line,
                  ),
                  if (planArtwork != null || planImageUrl != null) ...[
                    _PlanArtwork(
                      imageUrl: planImageUrl,
                      fallbackAsset: planArtwork,
                      width: 164,
                      height: 82,
                    ),
                    const SizedBox(width: 20),
                  ],
                  Expanded(child: signal),
                  const SizedBox(width: 18),
                  action,
                ],
              );
            },
          ),
        );
        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  temperature,
                  const SizedBox(width: 36),
                  Expanded(child: narrative),
                ],
              ),
              const SizedBox(height: 20),
              facts,
              const SizedBox(height: 26),
              focusPanel,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (constraints.maxWidth < 520 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.15) ...[
              temperature,
              const SizedBox(height: 18),
              narrative,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  temperature,
                  const SizedBox(width: 18),
                  Expanded(child: narrative),
                ],
              ),
            const SizedBox(height: 18),
            facts,
            const SizedBox(height: 22),
            focusPanel,
          ],
        );
      },
    );
  }

  String _currentEstimateLabel(
    AppStrings strings,
    String observedAt,
    DateTime? updatedAt,
  ) {
    final separator = observedAt.indexOf('T');
    final clock = separator >= 0 && observedAt.length >= separator + 6
        ? observedAt.substring(separator + 1, separator + 6)
        : null;
    final age = updatedAt == null
        ? const Duration(days: 1)
        : DateTime.now().toUtc().difference(updatedAt.toUtc());
    return strings.currentEstimate(
      clock,
      stale: age > const Duration(minutes: 90),
    );
  }
}

class _PlanArtwork extends StatelessWidget {
  const _PlanArtwork({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.width,
    required this.height,
  });

  final String? imageUrl;
  final String? fallbackAsset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => fallbackAsset == null
        ? const ColoredBox(color: AtlasColors.sky)
        : Image.asset(fallbackAsset!, fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl == null
            ? fallback()
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}

class _ForecastSignal extends StatelessWidget {
  const _ForecastSignal({
    required this.forecast,
    required this.recommendation,
    required this.loading,
    required this.onPressed,
  });

  final DailyForecast forecast;
  final PlanRecommendation? recommendation;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wet = forecast.weatherClass == 'rain' ||
        forecast.weatherClass == 'storm' ||
        forecast.rainProbability >= 50;
    final fallbackTitle = wet
        ? strings.indoorFallback
        : forecast.activityContext == 'outdoor'
            ? strings.outdoorFallback
            : strings.flexibleFallback;
    final fallbackDetail = strings.fallbackDetail(
      forecast.rainProbability,
      wet: wet,
    );
    final title = loading
        ? strings.matchingIdeas
        : recommendation == null
            ? fallbackTitle
            : strings.bestPlan(recommendation!.title);
    final detail = recommendation == null
        ? fallbackDetail
        : strings.recommendationReason(recommendation!.reason);
    final icon = recommendation == null
        ? wet
            ? Icons.umbrella_outlined
            : Icons.explore_outlined
        : switch (recommendation!.type) {
            'movie' => Icons.movie_outlined,
            'event' => Icons.event_available_outlined,
            _ => Icons.local_activity_outlined,
          };
    final label = recommendation == null
        ? '$title. $detail'
        : strings.bestPlanSemantics(recommendation!.title, detail);
    return Semantics(
      container: true,
      button: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AtlasColors.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AtlasColors.teal,
                          ),
                        )
                      : Icon(icon, color: AtlasColors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AtlasColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AtlasColors.mutedInk,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onPressed != null) ...[
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 9),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: AtlasColors.azure,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AtlasColors.azure),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: AtlasColors.ink,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AtlasColors.paper.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AtlasColors.ink, fontSize: 12),
        ),
      );
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter({
    required this.progress,
    required this.mood,
  });

  final double progress;
  final WeatherMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final shift = (1 - progress) * 28;
    final route = Paint()
      ..color = AtlasColors.paper.withValues(alpha: .78)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final routePath = Path()
      ..moveTo(size.width * .18, size.height * .15 + shift)
      ..cubicTo(
        size.width * .42,
        size.height * .03 + shift,
        size.width * .58,
        size.height * .08 + shift,
        size.width * .76,
        size.height * .38 + shift,
      );
    canvas.drawPath(routePath, route);

    final soft = Paint()
      ..color =
          (mood == WeatherMood.sunny ? AtlasColors.gold : AtlasColors.paper)
              .withValues(alpha: mood == WeatherMood.sunny ? .22 : .18);
    canvas.drawCircle(Offset(size.width * .86, 72 - shift), 118, soft);
    canvas.drawCircle(Offset(size.width * .73, 126 - shift), 58, soft);

    if (mood == WeatherMood.rainy || mood == WeatherMood.stormy) {
      final rain = Paint()
        ..color = AtlasColors.azure.withValues(alpha: .24)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 13; i++) {
        final x = ((i * 83) % (size.width.toInt() + 80)) - 30.0;
        final y = 92.0 + ((i * 47) % 210) + shift;
        canvas.drawLine(Offset(x, y), Offset(x - 8, y + 20), rain);
      }
    } else if (mood == WeatherMood.sunny) {
      final center = Offset(size.width * .87, 76 - shift);
      canvas.drawCircle(
        center,
        42,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFFFE184), Color(0xFFFFC845)],
          ).createShader(Rect.fromCircle(center: center, radius: 42)),
      );
      final rays = Paint()
        ..color = AtlasColors.gold.withValues(alpha: .54)
        ..strokeWidth = 2;
      for (var i = 0; i < 8; i++) {
        final angle = i * .785;
        canvas.drawLine(
          center + Offset.fromDirection(angle, 70),
          center + Offset.fromDirection(angle, 94),
          rays,
        );
      }
    } else if (mood == WeatherMood.cloudy || mood == WeatherMood.foggy) {
      final cloud = Paint()..color = AtlasColors.paper.withValues(alpha: .58);
      final baseY = 128.0 - shift;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .82, baseY),
          width: 250,
          height: 62,
        ),
        cloud,
      );
      canvas.drawCircle(Offset(size.width * .75, baseY - 24), 48, cloud);
      canvas.drawCircle(Offset(size.width * .86, baseY - 34), 62, cloud);
    } else if (mood == WeatherMood.windy) {
      final wind = Paint()
        ..color = AtlasColors.azure.withValues(alpha: .22)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 4; i++) {
        final y = 86.0 + i * 43 - shift;
        final path = Path()
          ..moveTo(size.width * .62, y)
          ..cubicTo(
            size.width * .72,
            y - 18,
            size.width * .83,
            y + 18,
            size.width * .96,
            y,
          );
        canvas.drawPath(path, wind);
      }
    }

    final skyline = Paint()
      ..color = AtlasColors.ink.withValues(alpha: .10 * progress)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final baseline = size.height * .72;
    final start = size.width * .58;
    final unit = size.width * .026;
    final city = Path()..moveTo(start, baseline);
    for (var index = 0; index < 14; index++) {
      final x = start + index * unit;
      final tower = index == 7 || index == 8;
      final height = tower
          ? size.height * (index == 7 ? .22 : .17)
          : size.height * (.045 + (index % 4) * .017);
      city
        ..lineTo(x, baseline)
        ..lineTo(x, baseline - height)
        ..lineTo(x + unit * .36, baseline - height - (tower ? 18 : 5))
        ..lineTo(x + unit * .72, baseline - height)
        ..lineTo(x + unit * .72, baseline);
    }
    city.lineTo(size.width, baseline);
    canvas.drawPath(city, skyline);
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.mood != mood;
}

List<Color> _atlasHeroColors(WeatherMood mood) => switch (mood) {
      WeatherMood.sunny => const [
          AtlasColors.ivory,
          Color(0xFFFFF0C9),
          Color(0xFFC9EBF6),
        ],
      WeatherMood.cloudy => const [
          AtlasColors.ivory,
          Color(0xFFF0F1EC),
          Color(0xFFD7E4E8),
        ],
      WeatherMood.windy => const [
          AtlasColors.ivory,
          Color(0xFFEAEFEC),
          Color(0xFFD1E2E7),
        ],
      WeatherMood.rainy => const [
          AtlasColors.ivory,
          Color(0xFFE2EFF4),
          Color(0xFFBFDCE8),
        ],
      WeatherMood.stormy => const [
          AtlasColors.ivory,
          Color(0xFFE9E5F1),
          Color(0xFFCBCBE2),
        ],
      WeatherMood.snowy => const [
          AtlasColors.paper,
          Color(0xFFEAF4F5),
          Color(0xFFD8EAF0),
        ],
      WeatherMood.foggy => const [
          AtlasColors.ivory,
          Color(0xFFECEEE9),
          Color(0xFFD9E1DD),
        ],
    };

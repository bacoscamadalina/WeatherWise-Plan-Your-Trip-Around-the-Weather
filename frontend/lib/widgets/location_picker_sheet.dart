import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/location.dart';
import '../models/location_search_page.dart';

typedef LocationPageLoader = Future<LocationSearchPage> Function(int page);

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({
    required this.query,
    required this.initialPage,
    required this.loadPage,
    super.key,
  });

  final String query;
  final LocationSearchPage initialPage;
  final LocationPageLoader loadPage;

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  late final List<Location> _locations;
  late int _page;
  late bool _hasMore;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _locations = [...widget.initialPage.locations];
    _page = widget.initialPage.page;
    _hasMore = widget.initialPage.hasMore;
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
      _error = null;
    });
    try {
      final next = await widget.loadPage(_page + 1);
      if (!mounted) return;
      setState(() {
        _locations.addAll(next.locations);
        _page = next.page;
        _hasMore = next.hasMore;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppStrings.of(context).morePlacesFailed);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                strings.chooseLocationTitle(widget.query),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.chooseLocationSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _locations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    return _LocationChoice(
                      location: location,
                      onPressed: () => Navigator.pop(context, location),
                    );
                  },
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: colors.error),
                ),
              ],
              if (_hasMore || _error != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loadingMore ? null : _loadMore,
                    icon: _loadingMore
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded),
                    label: Text(
                      _loadingMore ? strings.findingPlaces : strings.showMore,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                strings.locationDataAttribution,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationChoice extends StatelessWidget {
  const _LocationChoice({required this.location, required this.onPressed});

  final Location location;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final details = [
      location.adminArea,
      location.countryName ?? location.countryCode,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    final population = location.population;
    return Semantics(
      button: true,
      label: location.displayName,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (population != null && population > 0)
                      Text(
                        AppStrings.of(context).residents(population),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/location.dart';

typedef LocationSavedToggler = Future<bool> Function(Location location);

class LocationLibrarySheet extends StatefulWidget {
  const LocationLibrarySheet({
    required this.saved,
    required this.recent,
    required this.onToggleSaved,
    super.key,
  });

  final List<Location> saved;
  final List<Location> recent;
  final LocationSavedToggler onToggleSaved;

  @override
  State<LocationLibrarySheet> createState() => _LocationLibrarySheetState();
}

class _LocationLibrarySheetState extends State<LocationLibrarySheet> {
  late final Set<int> _savedIds;
  int? _updatingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _savedIds = widget.saved.map((location) => location.id).toSet();
  }

  Future<void> _toggleSaved(Location location) async {
    setState(() {
      _updatingId = location.id;
      _error = null;
    });
    try {
      final isSaved = await widget.onToggleSaved(location);
      if (!mounted) return;
      setState(() {
        if (isSaved) {
          _savedIds.add(location.id);
        } else {
          _savedIds.remove(location.id);
        }
      });
    } on FormatException {
      if (mounted) {
        setState(() => _error = AppStrings.of(context).savedPlacesLimit);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppStrings.of(context).savedPlacesUpdateFailed);
      }
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    final recent = widget.recent
        .where((location) => !_savedIds.contains(location.id))
        .toList(growable: false);
    final allEmpty = _savedIds.isEmpty && recent.isEmpty;

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
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
                strings.placesSheetTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.placesSheetSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: allEmpty
                    ? _EmptyLibrary(colors: colors)
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          if (_savedIds.isNotEmpty) ...[
                            _SectionLabel(
                              icon: Icons.bookmark_rounded,
                              label: strings.savedPlacesSection,
                            ),
                            const SizedBox(height: 4),
                            for (final location in widget.saved)
                              if (_savedIds.contains(location.id))
                                _LibraryLocationRow(
                                  location: location,
                                  saved: true,
                                  updating: _updatingId == location.id,
                                  onPressed: () =>
                                      Navigator.pop(context, location),
                                  onToggleSaved: () => _toggleSaved(location),
                                ),
                          ],
                          if (recent.isNotEmpty) ...[
                            if (_savedIds.isNotEmpty)
                              const SizedBox(height: 18),
                            _SectionLabel(
                              icon: Icons.history_rounded,
                              label: strings.recentPlaces,
                            ),
                            const SizedBox(height: 4),
                            for (final location in recent)
                              _LibraryLocationRow(
                                location: location,
                                saved: false,
                                updating: _updatingId == location.id,
                                onPressed: () =>
                                    Navigator.pop(context, location),
                                onToggleSaved: () => _toggleSaved(location),
                              ),
                          ],
                        ],
                      ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
              const SizedBox(height: 12),
              Text(
                strings.storedOnDevice,
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

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.travel_explore_rounded,
              size: 36,
              color: colors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              AppStrings.of(context).placesEmptyTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.of(context).placesEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _LibraryLocationRow extends StatelessWidget {
  const _LibraryLocationRow({
    required this.location,
    required this.saved,
    required this.updating,
    required this.onPressed,
    required this.onToggleSaved,
  });

  final Location location;
  final bool saved;
  final bool updating;
  final VoidCallback onPressed;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final details = [
      location.adminArea,
      location.countryName ?? location.countryCode,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();

    return Semantics(
      button: true,
      label: location.displayName,
      child: InkWell(
        key: ValueKey('stored-location-${location.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      details.isEmpty
                          ? location.countryCode
                          : details.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('toggle-saved-location-${location.id}'),
                tooltip: saved
                    ? AppStrings.of(context).removeSavedPlace(location.name)
                    : AppStrings.of(context).savePlace(location.name),
                onPressed: updating ? null : onToggleSaved,
                icon: updating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        saved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

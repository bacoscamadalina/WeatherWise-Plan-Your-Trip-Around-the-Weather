import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/preference_profile.dart';
import '../models/recommendation_filters.dart';

class RecommendationFilterSheet extends StatefulWidget {
  const RecommendationFilterSheet({
    required this.initialFilters,
    required this.initialProfiles,
    required this.onLoadProfiles,
    required this.onSaveProfile,
    required this.onDeleteProfile,
    super.key,
  });

  final RecommendationFilters initialFilters;
  final List<PreferenceProfile> initialProfiles;
  final Future<List<PreferenceProfile>> Function() onLoadProfiles;
  final Future<List<PreferenceProfile>> Function(
    String name,
    RecommendationFilters filters,
  ) onSaveProfile;
  final Future<List<PreferenceProfile>> Function(String id) onDeleteProfile;

  @override
  State<RecommendationFilterSheet> createState() =>
      _RecommendationFilterSheetState();
}

class _RecommendationFilterSheetState extends State<RecommendationFilterSheet> {
  late RecommendationFilters _filters = widget.initialFilters;
  late List<PreferenceProfile> _profiles = [...widget.initialProfiles];
  bool _profilesLoading = true;
  String? _profilesLoadError;
  bool _savingProfile = false;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadProfiles());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final strings = AppStrings.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 12 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.tuneYourIdeas,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strings.tuneYourIdeasSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      _FilterHeading(
                        icon: Icons.bookmarks_outlined,
                        title: strings.savedProfiles,
                      ),
                      const SizedBox(height: 8),
                      if (_profilesLoading)
                        const _ProfileLoadingState()
                      else if (_profilesLoadError != null)
                        _ProfileLoadError(
                          message: _profilesLoadError!,
                          onRetry: _loadProfiles,
                        )
                      else if (_profiles.isEmpty)
                        Text(
                          strings.noProfiles,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final profile in _profiles)
                              InputChip(
                                avatar: const Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 18,
                                ),
                                label: Text(profile.name),
                                selected: _filters == profile.filters,
                                onSelected: (_) => setState(() {
                                  _filters = profile.filters;
                                  _profileError = null;
                                }),
                                onDeleted: () => _confirmDelete(profile),
                                deleteButtonTooltipMessage:
                                    strings.deleteProfileTooltip(profile.name),
                              ),
                          ],
                        ),
                        if (_selectedProfile case final selected?) ...[
                          const SizedBox(height: 8),
                          Text(
                            _profileSummary(selected.filters, strings),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                      _FilterHeading(
                        icon: Icons.schedule_outlined,
                        title: strings.when,
                      ),
                      const SizedBox(height: 8),
                      _choices(
                        values: const [null, 'morning', 'afternoon', 'evening'],
                        labels: [
                          strings.anyTime,
                          strings.filterValue('morning'),
                          strings.filterValue('afternoon'),
                          strings.filterValue('evening'),
                        ],
                        selected: _filters.timeOfDay,
                        onSelected: (value) => setState(
                          () => _filters = _filters.copyWith(timeOfDay: value),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_filters.type == null ||
                          _filters.type == 'activity') ...[
                        _FilterHeading(
                          icon: Icons.wb_twilight_outlined,
                          title: strings.setting,
                        ),
                        const SizedBox(height: 8),
                        _choices(
                          values: const [null, 'indoor', 'outdoor'],
                          labels: [
                            strings.any,
                            strings.filterValue('indoor'),
                            strings.filterValue('outdoor'),
                          ],
                          selected: _filters.setting,
                          onSelected: (value) => setState(
                            () => _filters = _filters.copyWith(setting: value),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _FilterHeading(
                          icon: Icons.interests_outlined,
                          title: strings.activityStyle,
                        ),
                        const SizedBox(height: 8),
                        _choices(
                          values: const [
                            null,
                            'culture',
                            'nature',
                            'entertainment'
                          ],
                          labels: [
                            strings.any,
                            strings.filterValue('culture'),
                            strings.filterValue('nature'),
                            strings.filterValue('entertainment'),
                          ],
                          selected: _filters.activityKind,
                          onSelected: (value) => setState(
                            () => _filters =
                                _filters.copyWith(activityKind: value),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _FilterHeading(
                          icon: Icons.near_me_outlined,
                          title: strings.activityDistance,
                        ),
                        const SizedBox(height: 8),
                        _choices<double>(
                          values: const [null, 2, 5, 10],
                          labels: [strings.any, '2 km', '5 km', '10 km'],
                          selected: _filters.maxDistanceKm,
                          onSelected: (value) => setState(
                            () => _filters =
                                _filters.copyWith(maxDistanceKm: value),
                          ),
                        ),
                      ],
                      if (_filters.type == null ||
                          _filters.type == 'movie') ...[
                        if (_filters.type == null) const SizedBox(height: 20),
                        _FilterHeading(
                          icon: Icons.movie_filter_outlined,
                          title: strings.movieMood,
                        ),
                        const SizedBox(height: 8),
                        _choices(
                          values: const [
                            null,
                            'comedy',
                            'drama',
                            'horror',
                            'mystery',
                            'family',
                            'science fiction',
                          ],
                          labels: [
                            strings.any,
                            strings.filterValue('comedy'),
                            strings.filterValue('drama'),
                            strings.filterValue('horror'),
                            strings.filterValue('mystery'),
                            strings.filterValue('family'),
                            strings.filterValue('science fiction'),
                          ],
                          selected: _filters.genre,
                          onSelected: (value) => setState(
                            () => _filters = _filters.copyWith(genre: value),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _savingProfile ||
                          !_hasPreferenceChoices ||
                          _profiles.length >= 12
                      ? null
                      : _saveProfile,
                  icon: _savingProfile
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bookmark_add_outlined),
                  label: Text(
                    _profiles.length >= 12
                        ? strings.profileLimitReached
                        : strings.saveChoices,
                  ),
                ),
              ),
              if (!_hasPreferenceChoices) ...[
                const SizedBox(height: 6),
                Text(
                  strings.choosePreference,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_profileError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _profileError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(
                      () => _filters = RecommendationFilters(
                        type: _filters.type,
                      ),
                    ),
                    child: Text(strings.reset),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(_filters),
                    icon: const Icon(Icons.check),
                    label: Text(strings.applyFilters),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _profilesLoading = true;
      _profilesLoadError = null;
    });
    try {
      final profiles = await widget.onLoadProfiles();
      if (mounted) setState(() => _profiles = profiles);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _profilesLoadError = AppStrings.of(context).profilesLoadFailed);
      }
    } finally {
      if (mounted) setState(() => _profilesLoading = false);
    }
  }

  bool get _hasPreferenceChoices =>
      _filters.type != null || _filters.hasRefinements;

  PreferenceProfile? get _selectedProfile {
    for (final profile in _profiles) {
      if (profile.filters == _filters) return profile;
    }
    return null;
  }

  Future<void> _saveProfile() async {
    final name = await _askForProfileName();
    if (name == null || !mounted) return;
    if (_profiles.any(
      (profile) => profile.name.toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _profileError = AppStrings.of(context).profileNameUsed);
      return;
    }

    setState(() {
      _savingProfile = true;
      _profileError = null;
    });
    try {
      final profiles = await widget.onSaveProfile(name, _filters);
      if (mounted) setState(() => _profiles = profiles);
    } catch (_) {
      if (mounted) {
        setState(
            () => _profileError = AppStrings.of(context).profileSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<String?> _askForProfileName() async {
    return showDialog<String>(
      context: context,
      builder: (_) => const _ProfileNameDialog(),
    );
  }

  Future<void> _confirmDelete(PreferenceProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.of(context).deleteProfileTitle(profile.name)),
        content: Text(AppStrings.of(context).deleteProfileBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.of(context).keepProfile),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppStrings.of(context).delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final profiles = await widget.onDeleteProfile(profile.id);
      if (mounted) setState(() => _profiles = profiles);
    } catch (_) {
      if (mounted) {
        setState(
            () => _profileError = AppStrings.of(context).profileDeleteFailed);
      }
    }
  }

  String _profileSummary(RecommendationFilters filters, AppStrings strings) {
    final values = [
      if (filters.type != null) strings.filterValue(filters.type!),
      if (filters.timeOfDay != null) strings.filterValue(filters.timeOfDay!),
      if (filters.setting != null) strings.filterValue(filters.setting!),
      if (filters.activityKind != null)
        strings.filterValue(filters.activityKind!),
      if (filters.genre != null) strings.movieFilter(filters.genre!),
      if (filters.maxDistanceKm != null)
        strings.withinDistance(filters.maxDistanceKm!),
    ];
    return values.join(' · ');
  }

  Widget _choices<T>({
    required List<T?> values,
    required List<String> labels,
    required T? selected,
    required ValueChanged<T?> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(values.length, (index) {
        final value = values[index];
        return ChoiceChip(
          label: Text(labels[index]),
          selected: selected == value,
          onSelected: (_) => onSelected(value),
        );
      }),
    );
  }
}

class _FilterHeading extends StatelessWidget {
  const _FilterHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(AppStrings.of(context).loadingProfiles)),
      ],
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  const _ProfileLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.sync_problem_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(AppStrings.of(context).tryAgain),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileNameDialog extends StatefulWidget {
  const _ProfileNameDialog();

  @override
  State<_ProfileNameDialog> createState() => _ProfileNameDialogState();
}

class _ProfileNameDialogState extends State<_ProfileNameDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.of(context).nameProfile),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: AppStrings.of(context).profileName,
            hintText: AppStrings.of(context).profileNameHint,
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? AppStrings.of(context).enterProfileName
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.of(context).cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(AppStrings.of(context).saveProfile),
        ),
      ],
    );
  }
}

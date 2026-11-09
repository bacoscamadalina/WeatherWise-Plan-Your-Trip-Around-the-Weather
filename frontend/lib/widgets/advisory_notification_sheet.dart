import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/advisory_notification_preferences.dart';
import '../models/location.dart';

typedef AdvisoryNotificationSaver = Future<int> Function(
  AdvisoryNotificationPreferences preferences,
);

class NotificationPermissionDenied implements Exception {
  const NotificationPermissionDenied();
}

class AdvisoryNotificationSheet extends StatefulWidget {
  const AdvisoryNotificationSheet({
    required this.location,
    required this.preferences,
    required this.supported,
    required this.onSave,
    super.key,
  });

  final Location location;
  final AdvisoryNotificationPreferences preferences;
  final bool supported;
  final AdvisoryNotificationSaver onSave;

  @override
  State<AdvisoryNotificationSheet> createState() =>
      _AdvisoryNotificationSheetState();
}

class _AdvisoryNotificationSheetState extends State<AdvisoryNotificationSheet> {
  late bool _enabled;
  late TimeOfDay _time;
  late bool _highOnly;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _enabled = widget.preferences.follows(widget.location);
    _time = TimeOfDay(
      hour: widget.preferences.hour,
      minute: widget.preferences.minute,
    );
    _highOnly = widget.preferences.highOnly;
  }

  bool get _changed {
    final follows = widget.preferences.follows(widget.location);
    if (_enabled != follows) return true;
    if (!_enabled) return false;
    return _time.hour != widget.preferences.hour ||
        _time.minute != widget.preferences.minute ||
        _highOnly != widget.preferences.highOnly;
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: AppStrings.of(context).chooseReminderTime,
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final next = widget.preferences.forLocation(
      widget.location,
      enabled: _enabled,
      hour: _time.hour,
      minute: _time.minute,
      highOnly: _highOnly,
    );
    try {
      final count = await widget.onSave(next);
      if (mounted) Navigator.pop(context, count);
    } on NotificationPermissionDenied {
      if (mounted) {
        setState(
            () => _error = AppStrings.of(context).notificationPermissionDenied);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppStrings.of(context).remindersSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    final otherLocation = widget.preferences.enabled &&
            !widget.preferences.follows(widget.location)
        ? widget.preferences.locationName
        : null;

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
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
                strings.forecastReminders,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.reminderIntro(widget.location.name),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              if (!widget.supported)
                _UnsupportedNotice(colors: colors)
              else ...[
                SwitchListTile(
                  key: const ValueKey('advisory-reminders-switch'),
                  contentPadding: EdgeInsets.zero,
                  value: _enabled,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _enabled = value),
                  title: Text(
                    _enabled
                        ? strings.remindersOnFor(widget.location.name)
                        : strings.remindThisPlace,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(strings.permissionAfterSave),
                ),
                if (otherLocation != null && !_enabled) ...[
                  const SizedBox(height: 8),
                  Text(
                    strings.remindersFollowOther(otherLocation),
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  strings.reminderTime,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('advisory-reminder-time'),
                  onPressed: _enabled && !_saving ? _pickTime : null,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(_time.format(context)),
                ),
                const SizedBox(height: 18),
                Text(
                  strings.conditions,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(strings.allPlanningAdvisories),
                      selected: !_highOnly,
                      onSelected: !_enabled || _saving
                          ? null
                          : (_) => setState(() => _highOnly = false),
                    ),
                    ChoiceChip(
                      label: Text(strings.highPriorityOnly),
                      selected: _highOnly,
                      onSelected: !_enabled || _saving
                          ? null
                          : (_) => setState(() => _highOnly = true),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  strings.reminderTimezoneNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
              const SizedBox(height: 22),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 8,
                overflowSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text(
                      widget.supported ? strings.cancel : strings.close,
                    ),
                  ),
                  if (widget.supported) ...[
                    FilledButton(
                      key: const ValueKey('save-advisory-reminders'),
                      onPressed: !_changed || _saving ? null : _save,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(strings.saveReminders),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnsupportedNotice extends StatelessWidget {
  const _UnsupportedNotice({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone_android_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppStrings.of(context).remindersUnsupported,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
}

import 'package:flutter/material.dart';

import '../theme/atlas_theme.dart';

class TripPreferencesFields extends StatelessWidget {
  const TripPreferencesFields({
    required this.romanian,
    required this.budget,
    required this.dietary,
    required this.interests,
    required this.onBudgetChanged,
    required this.onDietaryChanged,
    required this.onInterestChanged,
    this.enabled = true,
    super.key,
  });

  final bool romanian;
  final bool enabled;
  final String budget;
  final Set<String> dietary;
  final Set<String> interests;
  final ValueChanged<String> onBudgetChanged;
  final void Function(String value, bool selected) onDietaryChanged;
  final void Function(String value, bool selected) onInterestChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AtlasColors.azure),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  romanian
                      ? 'Personalizează traseul'
                      : 'Personalize your route',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            romanian
                ? 'Opțional. Alegem activități și localuri mai apropiate de stilul tău.'
                : 'Optional. We will favor activities and venues that fit your style.',
            style: const TextStyle(color: AtlasColors.mutedInk),
          ),
          const SizedBox(height: 16),
          _ChoiceGroup(
            label: romanian ? 'Ce te interesează' : 'Your interests',
            children: [
              _chip(
                  'culture',
                  romanian ? 'Cultură' : 'Culture',
                  Icons.museum_outlined,
                  interests.contains('culture'),
                  onInterestChanged),
              _chip(
                  'nature',
                  romanian ? 'Natură' : 'Nature',
                  Icons.park_outlined,
                  interests.contains('nature'),
                  onInterestChanged),
              _chip(
                  'entertainment',
                  romanian ? 'Divertisment' : 'Entertainment',
                  Icons.theater_comedy_outlined,
                  interests.contains('entertainment'),
                  onInterestChanged),
            ],
          ),
          const SizedBox(height: 14),
          _ChoiceGroup(
            label: romanian ? 'Preferințe alimentare' : 'Dietary preferences',
            children: [
              _chip('vegetarian', 'Vegetarian', Icons.eco_outlined,
                  dietary.contains('vegetarian'), onDietaryChanged),
              _chip('vegan', 'Vegan', Icons.spa_outlined,
                  dietary.contains('vegan'), onDietaryChanged),
              _chip(
                  'gluten_free',
                  romanian ? 'Fără gluten' : 'Gluten-free',
                  Icons.grass_outlined,
                  dietary.contains('gluten_free'),
                  onDietaryChanged),
            ],
          ),
          const SizedBox(height: 14),
          _ChoiceGroup(
            label: romanian ? 'Buget pentru mese' : 'Meal budget',
            children: [
              _budgetChip('value', romanian ? 'Economic' : 'Value'),
              _budgetChip('moderate', romanian ? 'Moderat' : 'Moderate'),
              _budgetChip('flexible', romanian ? 'Flexibil' : 'Flexible'),
            ],
          ),
          if (dietary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              romanian
                  ? 'Rezultatele sunt potriviri de căutare, nu meniuri verificate. Confirmă direct cu localul opțiunile, ingredientele și riscul de contaminare.'
                  : 'Results are search matches, not verified menus. Confirm options, ingredients, and cross-contamination directly with the venue.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AtlasColors.mutedInk,
                  ),
            ),
          ],
        ],
      );

  Widget _chip(
    String value,
    String label,
    IconData icon,
    bool selected,
    void Function(String, bool) onChanged,
  ) =>
      FilterChip(
        key: ValueKey('trip-preference-$value'),
        selected: selected,
        onSelected: enabled ? (next) => onChanged(value, next) : null,
        avatar: Icon(icon, size: 18),
        label: Text(label),
        showCheckmark: false,
      );

  Widget _budgetChip(String value, String label) => ChoiceChip(
        key: ValueKey('trip-budget-$value'),
        selected: budget == value,
        onSelected: enabled ? (_) => onBudgetChanged(value) : null,
        label: Text(label),
        showCheckmark: false,
      );
}

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      );
}

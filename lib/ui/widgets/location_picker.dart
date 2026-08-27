import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/gazetteer.dart';

/// Cascading State → District → City pickers, backed by the [Gazetteer].
///
/// Location is chosen, never typed. Free-text location fields let people store
/// "mandya", "Mandya ", "Mandia" or nonsense, which then cannot be grouped,
/// counted or shown on a map. Restricting input to the gazetteer means every
/// stored place is spelt one way and always has coordinates.
///
/// The three levels are dependent: choosing a state clears the district and
/// city below it, because a district from the previous state would no longer be
/// valid. City is optional — a district is enough to place a user — but state
/// and district are required.
class LocationPicker extends StatelessWidget {
  const LocationPicker({
    super.key,
    required this.state,
    required this.district,
    required this.city,
    required this.onChanged,
    this.cityLabel = 'City / town / village',
    this.requireCity = false,
  });

  final String? state;
  final String? district;
  final String? city;

  /// Called with the full selection whenever any level changes. Values below a
  /// changed level arrive as null, so the caller's state stays consistent.
  final void Function({String? state, String? district, String? city})
      onChanged;

  final String cityLabel;
  final bool requireCity;

  @override
  Widget build(BuildContext context) {
    final districts = Gazetteer.districtsIn(state);
    final cities = Gazetteer.citiesIn(state, district);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PickerLabel('State / union territory'),
        DropdownButtonFormField<String>(
          initialValue: state,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.map_outlined),
            hintText: 'Select your state',
          ),
          items: [
            for (final name in Gazetteer.stateNames)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          // Changing state invalidates the district and city beneath it.
          onChanged: (v) => onChanged(state: v),
          validator: (v) => v == null ? 'Select your state' : null,
        ),
        const SizedBox(height: 14),

        const _PickerLabel('District'),
        DropdownButtonFormField<String>(
          initialValue: districts.contains(district) ? district : null,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_city_outlined),
            hintText: state == null
                ? 'Select a state first'
                : 'Select your district',
          ),
          items: [
            for (final name in districts)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: state == null
              ? null
              : (v) => onChanged(state: state, district: v),
          validator: (v) => v == null ? 'Select your district' : null,
        ),
        const SizedBox(height: 14),

        _PickerLabel(cityLabel, optional: !requireCity),
        DropdownButtonFormField<String>(
          initialValue: cities.contains(city) ? city : null,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.place_outlined),
            hintText: district == null
                ? 'Select a district first'
                : 'Select your city, town or village',
          ),
          items: [
            for (final name in cities)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: district == null
              ? null
              : (v) => onChanged(state: state, district: district, city: v),
          validator: (v) =>
              requireCity && v == null ? 'Select your city or town' : null,
        ),
      ],
    );
  }
}

/// A single-level country dropdown, for exporters and foreign investors.
class CountryPicker extends StatelessWidget {
  const CountryPicker({
    super.key,
    required this.country,
    required this.onChanged,
    this.label = 'Country',
  });

  final String? country;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerLabel(label),
        DropdownButtonFormField<String>(
          initialValue: Gazetteer.countryNames.contains(country)
              ? country
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.public),
            hintText: 'Select your country',
          ),
          items: [
            for (final name in Gazetteer.countryNames)
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? 'Select your country' : null,
        ),
      ],
    );
  }
}

/// A place field that *suggests* gazetteer names but still accepts free text.
///
/// Used where a strict dropdown would be wrong rather than helpful: a lorry
/// pickup point is often a warehouse, mandi gate or landmark that no gazetteer
/// lists. Suggesting known names pushes people onto mappable spellings — so the
/// trip shows on a map whenever it can — without blocking the genuine cases a
/// closed list would reject.
///
/// Signup deliberately does *not* use this; there, location must be exact, so
/// it uses [LocationPicker].
class PlaceAutocompleteField extends StatelessWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon = Icons.place_outlined,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (value) => Gazetteer.search(value.text),
      // Autocomplete owns its own controller, so the caller's controller is
      // kept in sync from the field builder instead of being handed over.
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        if (textController.text != controller.text) {
          textController.text = controller.text;
        }
        return TextField(
          controller: textController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => controller.text = v,
          onSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(prefixIcon, size: 20),
          ),
        );
      },
      onSelected: (v) => controller.text = v,
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerLabel extends StatelessWidget {
  const _PickerLabel(this.text, {this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 6),
            Text(
              '(optional)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

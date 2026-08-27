/// The single source of truth for every place name the app will accept.
///
/// Two requirements meet here, and that is deliberate:
///
///  * Signup must offer **dropdowns only**, so an invalid or misspelt place can
///    never be stored.
///  * Every place shown in the UI must be **pinnable on a map**.
///
/// Both are satisfied by one rule: a place is selectable *only if* it carries
/// coordinates. Keeping the list and the coordinates in the same records makes
/// the two properties impossible to separate — you cannot add a district to the
/// dropdown without also giving the map somewhere to point, and a name that is
/// not in here cannot be entered at all, so there is no such thing as a stored
/// place the map cannot find.
///
/// Scope: **all of India**, every state and union territory down to city level,
/// from GeoNames (see `gazetteer_data.dart`). Completeness is not a nicety
/// here — a closed dropdown is only acceptable if the list actually contains
/// the user. An earlier hand-written version covered Karnataka properly and
/// gave other states two or three districts each, which meant a genuine user
/// from Salem or Nashik could not finish signing up at all. A dropdown should
/// reject bad data, never real people.
library;

import 'gazetteer_data.dart';

/// A place with a fixed position. [lat]/[lng] are the map pin.
class Place {
  const Place(this.name, this.lat, this.lng);

  final String name;
  final double lat;
  final double lng;

  @override
  String toString() => name;
}

/// A district and the cities/towns inside it.
class District {
  const District(this.place, this.cities);

  final Place place;
  final List<Place> cities;

  String get name => place.name;
}

/// A state (or union territory) and its districts.
class StateRegion {
  const StateRegion(this.place, this.districts);

  final Place place;
  final List<District> districts;

  String get name => place.name;
}

class Gazetteer {
  Gazetteer._();

  /// Where a map should sit when we have no place at all: centred on India.
  static const Place indiaCentre = Place('India', 22.5937, 78.9629);

  /// Every Indian state and union territory, to city level.
  static const List<StateRegion> states = kIndiaStates;

  /// Karnataka — BLOB's operating region, and the state the seed data uses.
  /// Resolved from [states] rather than held separately so there is only ever
  /// one copy of the data to keep correct.
  static StateRegion get karnataka => state('Karnataka')!;

  /// Countries for exporters and foreign investors. India is first because it
  /// is the common case; the rest are BLOB's main trade partners.
  static const List<Place> countries = [
    Place('India', 22.5937, 78.9629),
    Place('United Arab Emirates', 23.4241, 53.8478),
    Place('Saudi Arabia', 23.8859, 45.0792),
    Place('Qatar', 25.3548, 51.1839),
    Place('Kuwait', 29.3117, 47.4818),
    Place('Oman', 21.4735, 55.9754),
    Place('Bahrain', 25.9304, 50.6378),
    Place('United States', 37.0902, -95.7129),
    Place('United Kingdom', 55.3781, -3.4360),
    Place('Canada', 56.1304, -106.3468),
    Place('Australia', -25.2744, 133.7751),
    Place('Singapore', 1.3521, 103.8198),
    Place('Malaysia', 4.2105, 101.9758),
    Place('Germany', 51.1657, 10.4515),
    Place('Netherlands', 52.1326, 5.2913),
    Place('France', 46.2276, 2.2137),
    Place('Japan', 36.2048, 138.2529),
    Place('China', 35.8617, 104.1954),
    Place('Bangladesh', 23.6850, 90.3563),
    Place('Sri Lanka', 7.8731, 80.7718),
    Place('Nepal', 28.3949, 84.1240),
    Place('Vietnam', 14.0583, 108.2772),
    Place('Thailand', 15.8700, 100.9925),
    Place('Indonesia', -0.7893, 113.9213),
    Place('South Africa', -30.5595, 22.9375),
    Place('Kenya', -0.0236, 37.9062),
    Place('Brazil', -14.2350, -51.9253),
    Place('Russia', 61.5240, 105.3188),
    Place('Italy', 41.8719, 12.5674),
    Place('Spain', 40.4637, -3.7492),
  ];

  // ---- Lookups ----------------------------------------------------------
  // Built once, lazily. Everything the UI shows goes through these, so a name
  // that is not in the gazetteer simply has no position and no map link.

  static final Map<String, Place> _byName = _buildIndex();

  static Map<String, Place> _buildIndex() {
    final index = <String, Place>{};
    // Least specific first, so a more specific place of the same name wins:
    // "Mysuru" should resolve to the city, not the district centroid.
    for (final country in countries) {
      index[_key(country.name)] = country;
    }
    for (final state in states) {
      index[_key(state.name)] = state.place;
    }
    for (final state in states) {
      for (final district in state.districts) {
        index[_key(district.name)] = district.place;
      }
    }
    for (final state in states) {
      for (final district in state.districts) {
        for (final city in district.cities) {
          index[_key(city.name)] = city;
        }
      }
    }
    // Districts whose name is qualified with their state, because the bare
    // name is ambiguous — "Bilaspur (Himachal Pradesh)". Also index the bare
    // name so a *stored* "Bilaspur" still finds somewhere sensible, but only
    // if nothing more definite already claims it.
    for (final state in states) {
      for (final district in state.districts) {
        final bracket = district.name.indexOf(' (');
        if (bracket > 0) {
          final bare = _key(district.name.substring(0, bracket));
          index.putIfAbsent(bare, () => district.place);
        }
      }
    }
    return index;
  }

  static String _key(String name) => name.trim().toLowerCase();

  /// Resolves a stored place name to coordinates, or null if unknown.
  ///
  /// Returns null rather than a fallback position on purpose: callers use null
  /// to decide *not* to offer a map link, which is better than dropping a pin
  /// in the wrong place and asserting it is correct.
  static Place? lookup(String? name) {
    if (name == null) return null;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final direct = _resolve(trimmed);
    if (direct != null) return direct;
    // Stored values are sometimes composite, e.g. "Maddur, Mandya". Try the
    // most specific component first.
    for (final part in trimmed.split(',')) {
      final hit = _resolve(part);
      if (hit != null) return hit;
    }
    return null;
  }

  /// Direct hit, else a superseded spelling ("Mysore" for Mysuru). Aliases are
  /// tried second so a name that is current somewhere else in India always
  /// wins over being read as somebody's old name for a different place.
  static Place? _resolve(String raw) {
    final key = _key(raw);
    if (key.isEmpty) return null;
    final hit = _byName[key];
    if (hit != null) return hit;
    final alias = kPlaceAliases[key];
    return alias == null ? null : _byName[_key(alias)];
  }

  /// True when [name] can be pinned on a map.
  static bool isKnown(String? name) => lookup(name) != null;

  static List<String> get stateNames =>
      states.map((s) => s.name).toList(growable: false);

  static StateRegion? state(String? name) {
    if (name == null) return null;
    for (final s in states) {
      if (_key(s.name) == _key(name)) return s;
    }
    return null;
  }

  /// Districts within [stateName], alphabetically.
  static List<String> districtsIn(String? stateName) {
    final s = state(stateName);
    if (s == null) return const [];
    final names = s.districts.map((d) => d.name).toList()..sort();
    return names;
  }

  /// Cities within a district, alphabetically.
  static List<String> citiesIn(String? stateName, String? districtName) {
    final s = state(stateName);
    if (s == null || districtName == null) return const [];
    for (final d in s.districts) {
      if (_key(d.name) == _key(districtName)) {
        final names = d.cities.map((c) => c.name).toList()..sort();
        return names;
      }
    }
    return const [];
  }

  /// The state a district belongs to — used to back-fill the state dropdown
  /// for accounts created before state was collected.
  static String? stateOfDistrict(String? districtName) {
    if (districtName == null) return null;
    final key = _key(districtName);
    for (final s in states) {
      for (final d in s.districts) {
        if (_key(d.name) == key) return s.name;
      }
    }
    // An unqualified name for a district we store qualified, e.g. a stored
    // "Bilaspur" against "Bilaspur (Himachal Pradesh)". Only accept it when
    // exactly one state has it, since guessing between two is worse than
    // leaving the dropdown for the user to set.
    final matches = <String>[];
    for (final s in states) {
      for (final d in s.districts) {
        final bracket = d.name.indexOf(' (');
        if (bracket > 0 && _key(d.name.substring(0, bracket)) == key) {
          matches.add(s.name);
        }
      }
    }
    return matches.length == 1 ? matches.first : null;
  }

  static List<String> get countryNames =>
      countries.map((c) => c.name).toList(growable: false);

  /// Place names matching [query], for type-ahead fields where a strict
  /// dropdown would be wrong — a lorry pickup point can legitimately be a
  /// warehouse or a landmark, not just a town. Suggesting gazetteer names
  /// steers people onto mappable spellings without blocking the rest.
  ///
  /// Prefix matches rank above substring matches so typing "man" offers
  /// "Mandya" before "Chikkamagaluru".
  static List<String> search(String query, {int limit = 8}) {
    final q = _key(query);
    if (q.isEmpty) return const [];
    final prefix = <String>[];
    final contains = <String>[];
    for (final entry in _byName.entries) {
      if (entry.key.startsWith(q)) {
        prefix.add(entry.value.name);
      } else if (contains.length < limit && entry.key.contains(q)) {
        contains.add(entry.value.name);
      }
      if (prefix.length >= limit) break;
    }
    prefix.sort();
    contains.sort();
    return [...prefix, ...contains].take(limit).toList(growable: false);
  }
}

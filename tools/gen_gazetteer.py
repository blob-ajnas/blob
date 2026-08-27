#!/usr/bin/env python3
"""Generate lib/data/gazetteer_data.dart from GeoNames.

Why generated rather than hand-written: the previous gazetteer was typed from
memory and only covered Karnataka to district level, so a genuine user from
Salem or Nashik could not complete signup at all. A closed dropdown is only
acceptable if the list is actually complete, otherwise it blocks real people
instead of blocking bad data.

Source: GeoNames (CC-BY 4.0) IN.txt + admin1CodesASCII.txt.
  - states    <- admin1 (36 states and union territories)
  - districts <- feature A/ADM2 (763), coordinates from the same record
  - cities    <- feature P above a population floor, attributed to their ADM2

Two data problems are corrected here, both verified against the dump:

1. Stale names. GeoNames still carries colonial-era spellings ("Mysore",
   "Belgaum", "Gulbarga"). Users pick from this list, so it must show the
   name on their address proof. RENAMES maps them forward; the old spelling
   is kept as a lookup alias so accounts and seed rows written earlier still
   resolve.

2. Duplicate district names. Balrampur, Bilaspur and Raigarh each exist in
   two different states. Left alone, one would silently shadow the other and
   a Bilaspur user could be pinned 1,500km away. These are disambiguated as
   "Bilaspur (Himachal Pradesh)".
"""

import csv
import os
import sys
import unicodedata

SRC = "/tmp"
OUT = "/home/user/flutter_app/lib/data/gazetteer_data.dart"

# Minimum population for a town to be offered as a city. 20k keeps the list
# to towns a person would name as their home while staying small enough to
# scroll; district headquarters are added regardless of size below.
CITY_POP_FLOOR = 20000
# Per-district cap, largest first. Long dropdowns are their own usability
# problem, and past ~15 entries people stop reading and start scrolling.
CITY_CAP = 15
# When a district has no town above the floor, offer this many of its largest
# regardless, so the city dropdown is never empty.
CITY_FALLBACK = 5

# GeoNames spelling -> current official name.
#
# Renames are scoped to a state on purpose. A blind global table is unsafe:
# "Bijapur" is the old name of Karnataka's Vijayapura, but Chhattisgarh has a
# genuinely different district also called Bijapur, and renaming both merges
# two real places 900km apart into one. Verified against the dump.
RENAMES = {
    "Karnataka": {
        "Mysore": "Mysuru",
        "Bangalore Rural": "Bengaluru Rural",
        "Bangalore Urban": "Bengaluru Urban",
        "Belgaum": "Belagavi",
        "Bellary": "Ballari",
        "Bijapur": "Vijayapura",
        "Chikmagalur": "Chikkamagaluru",
        "Gulbarga": "Kalaburagi",
        "Shimoga": "Shivamogga",
        "Tumkur": "Tumakuru",
        "Hubli": "Hubballi",
        "Uttar Kannada": "Uttara Kannada",
        "Bagalkote": "Bagalkot",
        "Chamrajnagar": "Chamarajanagar",
        "French Rocks": "Pandavapura",
    },
    "Haryana": {
        "Gurgaon": "Gurugram",
        "Mewat": "Nuh",
    },
    "Uttar Pradesh": {
        "Allahabad": "Prayagraj",
        "Faizabad": "Ayodhya",
    },
    "Kerala": {
        "Trivandrum": "Thiruvananthapuram",
        "Calicut": "Kozhikode",
        "Alleppey": "Alappuzha",
        "Quilon": "Kollam",
        "Cannanore": "Kannur",
        "Trichur": "Thrissur",
        "Palghat": "Palakkad",
        "Cochin": "Kochi",
        "Tellicherry": "Thalassery",
    },
    "West Bengal": {"Calcutta": "Kolkata"},
    "Tamil Nadu": {"Madras": "Chennai"},
    "Maharashtra": {"Bombay": "Mumbai", "Poona": "Pune"},
    "Gujarat": {"Baroda": "Vadodara"},
    "Himachal Pradesh": {"Simla": "Shimla"},
    "Goa": {"Panjim": "Panaji"},
    "Puducherry": {"Pondicherry": "Puducherry"},
}

# States whose display name we prefer over GeoNames'.
STATE_RENAMES = {
    "Andaman and Nicobar": "Andaman and Nicobar Islands",
}


def ascii_name(name: str, fallback: str) -> str:
    """Prefer the ASCII spelling; the UI is English and a dropdown full of
    macrons ("Bilāspur") reads as a typo to the people choosing from it."""
    n = (fallback or "").strip()
    if not n:
        n = (
            unicodedata.normalize("NFKD", name)
            .encode("ascii", "ignore")
            .decode()
            .strip()
        )
    # Collapse runs of whitespace: the dump contains "North  & Middle Andaman",
    # and a double space in a dropdown reads as a typo.
    return " ".join(n.split())


def strip_suffix(name: str) -> str:
    """Drop a trailing "District".

    GeoNames labels 33 of 763 districts "Kaushambi District" while the other
    730 are bare. In a dropdown that inconsistency reads as a data bug, and it
    also breaks matching against a district name stored without the suffix."""
    for suffix in (" District", " district"):
        if name.endswith(suffix) and len(name) > len(suffix):
            return name[: -len(suffix)].strip()
    return name


def canonical(name: str, state: str) -> str:
    """Current official name for [name] as used in [state]."""
    return RENAMES.get(state, {}).get(name, name)


def load_states():
    states = {}
    path = os.path.join(SRC, "admin1.txt")
    with open(path, encoding="utf-8") as fh:
        for row in csv.reader(fh, delimiter="\t", quoting=csv.QUOTE_NONE):
            if not row or not row[0].startswith("IN."):
                continue
            code = row[0].split(".")[1]
            name = STATE_RENAMES.get(row[2].strip(), row[2].strip())
            states[code] = {"name": name, "lat": None, "lng": None, "districts": {}}
    return states


def load_places(states):
    """Single pass over the 660k-row dump, collecting three things at once."""
    path = os.path.join(SRC, "IN.txt")
    towns = []  # (state_code, admin2_code, name, lat, lng, pop)
    with open(path, encoding="utf-8") as fh:
        for row in csv.reader(fh, delimiter="\t", quoting=csv.QUOTE_NONE):
            if len(row) < 15:
                continue
            fclass, fcode = row[6], row[7]
            a1, a2 = row[10], row[11]
            try:
                lat, lng = float(row[4]), float(row[5])
            except ValueError:
                continue
            name = ascii_name(row[1], row[2])
            if not name:
                continue

            if fclass == "A" and fcode == "ADM1" and a1 in states:
                st = states[a1]
                if st["lat"] is None:
                    st["lat"], st["lng"] = lat, lng
            elif fclass == "A" and fcode == "ADM2" and a1 in states and a2:
                bare = strip_suffix(name)
                states[a1]["districts"][a2] = {
                    "name": canonical(bare, states[a1]["name"]),
                    "raw": bare,
                    "lat": lat,
                    "lng": lng,
                    "cities": [],
                }
            elif fclass == "P" and a1 in states and a2:
                pop = int(row[14]) if row[14].isdigit() else 0
                towns.append((a1, a2, name, lat, lng, pop))
    return towns


def backfill_empty_districts(states):
    """Give any still-empty district itself as its single city.

    Two enclaves (Puducherry's Yanam and Mahe) have no populated-place records
    attributed to them in the dump, because the district *is* the town. Using
    the district's own name and coordinates is accurate rather than a guess,
    and it keeps the invariant that the city dropdown is never empty."""
    filled = 0
    for st in states.values():
        for d in st["districts"].values():
            if not d["cities"]:
                d["cities"] = [(d["name"], d["lat"], d["lng"])]
                filled += 1
    return filled


def attach_cities(states, towns):
    """Attach towns to their district, largest first, honouring the cap.

    The district headquarters is force-included even when it is below the
    population floor, because a district with no selectable city would leave
    the third dropdown permanently empty."""
    by_district = {}
    for a1, a2, name, lat, lng, pop in towns:
        town = canonical(name, states[a1]["name"])
        by_district.setdefault((a1, a2), []).append((pop, town, lat, lng))

    for (a1, a2), items in by_district.items():
        district = states[a1]["districts"].get(a2)
        if district is None:
            continue
        items.sort(key=lambda t: (-t[0], t[1]))
        picked, seen = [], set()
        # Force the HQ in: a town sharing the district's name.
        for pop, name, lat, lng in items:
            if name.lower() == district["name"].lower() and name.lower() not in seen:
                picked.append((name, lat, lng))
                seen.add(name.lower())
                break
        for pop, name, lat, lng in items:
            if len(picked) >= CITY_CAP:
                break
            if pop < CITY_POP_FLOOR or name.lower() in seen:
                continue
            picked.append((name, lat, lng))
            seen.add(name.lower())
        # Thinly populated districts — much of the north-east, and the island
        # territories — have no town above the floor at all. Leaving the city
        # dropdown empty there would read as a broken form, so take the
        # largest few whatever their recorded population.
        if not picked:
            for pop, name, lat, lng in items[:CITY_FALLBACK]:
                if name.lower() in seen:
                    continue
                picked.append((name, lat, lng))
                seen.add(name.lower())
        picked.sort(key=lambda t: t[0])
        district["cities"] = picked


def dedupe_district_names(states):
    """Disambiguate names that occur in more than one state.

    Without this, one Bilaspur silently shadows the other in the name index
    and a user from the Himachal one gets a pin in Chhattisgarh."""
    counts = {}
    for st in states.values():
        for d in st["districts"].values():
            counts[d["name"]] = counts.get(d["name"], 0) + 1
    clashes = {n for n, c in counts.items() if c > 1}
    for st in states.values():
        for d in st["districts"].values():
            if d["name"] in clashes:
                d["display"] = f"{d['name']} ({st['name']})"
            else:
                d["display"] = d["name"]
    return sorted(clashes)


def dart_string(s: str) -> str:
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'") + "'"


def emit(states, clashes):
    lines = []
    w = lines.append
    w("// GENERATED FILE - DO NOT EDIT BY HAND.")
    w("//")
    w("// Regenerate with: python3 tools/gen_gazetteer.py")
    w("//")
    w("// Source: GeoNames (https://www.geonames.org), licensed CC-BY 4.0.")
    w("//   states    <- admin1CodesASCII.txt")
    w("//   districts <- IN.txt feature A/ADM2")
    w(f"//   cities    <- IN.txt feature P, population >= {CITY_POP_FLOOR:,},")
    w(f"//                at most {CITY_CAP} per district, plus each district HQ.")
    w("//")
    w("// Colonial-era spellings in the source are mapped forward to current")
    w("// official names (Mysore -> Mysuru); the old spelling stays a lookup")
    w("// alias so data written before the rename still resolves.")
    if clashes:
        w("//")
        w("// District names occurring in more than one state are shown with the")
        w("// state in brackets so they cannot shadow each other:")
        for c in clashes:
            w(f"//   {c}")
    w("")
    w("import 'gazetteer.dart';")
    w("")
    w("/// Every Indian state and union territory, to city level.")
    w("const List<StateRegion> kIndiaStates = [")

    for st in sorted(states.values(), key=lambda s: s["name"]):
        if st["lat"] is None or not st["districts"]:
            continue
        w(
            f"  StateRegion(Place({dart_string(st['name'])}, "
            f"{st['lat']:.4f}, {st['lng']:.4f}), ["
        )
        for d in sorted(st["districts"].values(), key=lambda d: d["display"]):
            w(
                f"    District(Place({dart_string(d['display'])}, "
                f"{d['lat']:.4f}, {d['lng']:.4f}), ["
            )
            for name, lat, lng in d["cities"]:
                w(f"      Place({dart_string(name)}, {lat:.4f}, {lng:.4f}),")
            w("    ]),")
        w("  ]),")
    w("];")
    w("")

    # Aliases: old spelling -> current name, so historical values resolve.
    #
    # Only renames that are unambiguous nationwide are exported. "Bijapur" is
    # deliberately excluded: it is Karnataka's former name for Vijayapura but
    # also a current, different district in Chhattisgarh, so aliasing it would
    # send Chhattisgarh users 900km to the wrong state.
    global_aliases = {}
    ambiguous = set()
    current = {
        d["name"].lower() for s in states.values() for d in s["districts"].values()
    }
    for table in RENAMES.values():
        for old, new in table.items():
            key = old.lower()
            if key in current or global_aliases.get(key, new) != new:
                ambiguous.add(old)
                continue
            global_aliases[key] = new
    for old in ambiguous:
        global_aliases.pop(old.lower(), None)

    w("/// Superseded spellings, kept so places stored before a rename still")
    w("/// resolve to the same coordinates instead of losing their map pin.")
    if ambiguous:
        w("///")
        w("/// Excluded as unsafe, because the old name is also a *current*")
        w("/// place elsewhere in India, so aliasing it would move the pin:")
        for a in sorted(ambiguous):
            w(f"///   {a}")
    w("const Map<String, String> kPlaceAliases = {")
    for old, new in sorted(global_aliases.items()):
        w(f"  {dart_string(old)}: {dart_string(new)},")
    w("};")
    w("")

    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))

    d_total = sum(len(s["districts"]) for s in states.values())
    c_total = sum(
        len(d["cities"]) for s in states.values() for d in s["districts"].values()
    )
    return len(states), d_total, c_total


def main():
    states = load_states()
    towns = load_places(states)
    attach_cities(states, towns)
    backfilled = backfill_empty_districts(states)
    clashes = dedupe_district_names(states)
    print(f"backfilled districts (district used as its own city): {backfilled}")
    ns, nd, nc = emit(states, clashes)
    print(f"states={ns} districts={nd} cities={nc}")
    print(f"disambiguated={clashes}")
    empty = [
        f"{s['name']}/{d['display']}"
        for s in states.values()
        for d in s["districts"].values()
        if not d["cities"]
    ]
    print(f"districts with no city: {len(empty)}")
    for e in empty[:15]:
        print("   ", e)
    return 0


if __name__ == "__main__":
    sys.exit(main())

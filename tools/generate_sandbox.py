#!/usr/bin/env python3
"""Lay the sandbox options out across pages instead of one 322-row list.

Pages are cosmetic in Project Zomboid -- every option still lands flat on
SandboxVars.BundleUp.<Name> whatever page it sits on -- so this only rewrites
`page =` values and block order, never an option name, type or default. Saves
keep their stored values and sandbox-options.txt needs no VERSION bump.

Which page a per-item slider lands on is derived, not listed: the same
resolve_base -> BU.BaseCategory walk BU_ApplyWeights.lua does at runtime, so an
item always sits with the category slider it actually inherits from.

Labels and tooltips are hand-written prose. This reads them out of Sandbox.json
to sort and validate, and rewrites none of them -- only the page titles are
generated.

Output is committed. Re-running with no source change must produce no diff.

    python tools/generate_sandbox.py [--check]
"""

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MEDIA = ROOT / "Contents/mods/Vanilla/42/media"
OPTIONS = MEDIA / "sandbox-options.txt"
STRINGS = MEDIA / "lua/shared/Translate/EN/Sandbox.json"

BANNER = "/*----------*/\n/*--ESTRAL--*/\n/*----------*/\n\nVERSION = 1,\n"
MODULE = "BundleUp"

PAGES = [
    ("BundleUpPage_Spawns",  "Bundle Up: Loot Spawns"),
    ("BundleUpPage_Weights", "Bundle Up: Weight & Spoilage"),
    ("BundleUpPage_Food",    "Bundle Up: Weight - Food & Drink"),
    ("BundleUpPage_Leather", "Bundle Up: Weight - Leather & Hides"),
    ("BundleUpPage_Metal",   "Bundle Up: Weight - Metal"),
    ("BundleUpPage_Stone",   "Bundle Up: Weight - Stone"),
    ("BundleUpPage_Wood",    "Bundle Up: Weight - Wood"),
    ("BundleUpPage_Other",   "Bundle Up: Weight - Everything Else"),
]

# The two curated pages keep a hand-chosen order, so they are listed rather than
# sorted. An option that belongs on one but is missing here is an error, not a
# silent fallthrough onto an item page.
CURATED = {
    "BundleUpPage_Spawns": [
        "SpawnDefault", "SpawnSixPacks", "SpawnFood", "SpawnMaterials", "SpawnSupplies",
        "SpawnFishing", "SpawnMedical", "SpawnAmmo", "SpawnSeeds", "SpawnScrap",
        "SpawnJewelry", "SpawnLiterature",
    ],
    "BundleUpPage_Weights": [
        "ReductionDefault", "ReductionMetal", "ReductionWood", "ReductionStone",
        "ReductionFood", "ReductionMedical", "ReductionLeather", "ReductionOther",
        "CartonSpoilRate",
    ],
}

CATEGORY_PAGE = {
    "ReductionFood":    "BundleUpPage_Food",
    "ReductionLeather": "BundleUpPage_Leather",
    "ReductionMetal":   "BundleUpPage_Metal",
    "ReductionStone":   "BundleUpPage_Stone",
    "ReductionWood":    "BundleUpPage_Wood",
    "ReductionOther":   "BundleUpPage_Other",
}

BLOCK = re.compile(r"option " + MODULE + r"\.(\w+)\s*\n\{\s*\n(.*?)\}", re.S)

# sync_weights.py parses the same rows but is gitignored, so this repeats the two
# patterns rather than importing it -- CI has no copy of that file.
WEIGHT_DATA = ("BU_WeightData.lua", "BU_WeightData_Packs.lua", "BU_WeightData_Tiers.lua")
ROW = re.compile(r'\["([\w.]+)"\]\s*=\s*\{\s*base\s*=\s*"([\w.]+)"')
CATEGORY = re.compile(r'\["([\w.]+)"\]\s*=\s*"(Reduction\w+)"')
MAX_DEPTH = 16


def read(path):
    """Always \\n, whatever the file uses, so generated text compares cleanly."""
    with path.open(encoding="utf-8", newline=None) as handle:
        return handle.read()


def write(path, text, newline, changed, check):
    if read(path) == text:
        return
    changed.append(str(path.relative_to(ROOT)).replace("\\", "/"))
    if not check:
        with path.open("w", encoding="utf-8", newline=newline) as handle:
            handle.write(text)


def load_bundles():
    src = "".join(read(MEDIA / "lua/shared" / name) for name in WEIGHT_DATA)
    return ({m.group(1): m.group(2) for m in ROW.finditer(src)},
            {m.group(1): m.group(2) for m in CATEGORY.finditer(src)})


def resolve_base(full_type, bundles):
    """Walk a pack down to the vanilla item it bottoms out at, as BU.resolveBase does."""
    base = bundles[full_type]
    for _ in range(MAX_DEPTH):
        if base not in bundles:
            return base
        base = bundles[base]
    sys.exit("cycle resolving " + full_type)


def read_options():
    """Every option block as (name, [setting lines]), with page = dropped."""
    blocks = []
    for match in BLOCK.finditer(read(OPTIONS)):
        settings = [re.sub(r"page = \w+, ", "", line.strip())
                    for line in match.group(2).splitlines() if line.strip()]
        blocks.append((match.group(1), settings))
    if not blocks:
        sys.exit("no option blocks found in " + str(OPTIONS))
    return blocks


def page_for(name, bundles, categories):
    for key, names in CURATED.items():
        if name in names:
            return key
    if not name.startswith("Item_"):
        sys.exit("option " + name + " is neither Item_* nor listed in CURATED")
    full_type = MODULE + "." + name[len("Item_"):]
    if full_type not in bundles:
        sys.exit("option " + name + " has no weight row for " + full_type)
    # no BaseCategory row means it falls through to ReductionDefault at runtime,
    # which is exactly what the Everything Else page collects
    base = resolve_base(full_type, bundles)
    return CATEGORY_PAGE.get(categories.get(base), "BundleUpPage_Other")


def emit_options(assigned):
    out = [BANNER]
    for key, title in PAGES:
        if not assigned[key]:
            sys.exit("page " + key + " (" + title + ") has no options")
        out.append("\n/* ---- " + title + " ---- */\n")
        for name, settings in assigned[key]:
            body = ["option " + MODULE + "." + name, "{"]
            for line in settings:
                # page rides on the translation line, the way the file already had it
                if line.startswith("translation = "):
                    line = "page = " + key + ", " + line
                body.append("    " + line)
            body.append("}")
            out.append("\n" + "\n".join(body) + "\n")
    return "".join(out)


def emit_strings(existing):
    """Swap the single page title for one per page, leaving every other key put."""
    titles = {"Sandbox_" + key: title for key, title in PAGES}
    kept = {k: v for k, v in existing.items()
            if k != "Sandbox_" + MODULE and k not in titles}
    collisions = sorted(k for k in titles if k in existing and existing[k] != titles[k])
    if collisions:
        sys.exit("page key collides with an option key: " + ", ".join(collisions))
    merged = list(titles.items()) + list(kept.items())
    return "{\n" + ",\n".join("    " + json.dumps(k) + ": " + json.dumps(v)
                              for k, v in merged) + "\n}\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true",
                        help="fail if regenerating would change anything")
    args = parser.parse_args()

    bundles, categories = load_bundles()
    strings = json.loads(read(STRINGS))
    options = read_options()

    def key_for(name, suffix=""):
        return "Sandbox_" + MODULE + "_" + name + suffix

    bare = [name for name, _ in options
            if key_for(name) not in strings or key_for(name, "_tooltip") not in strings]
    if bare:
        sys.exit("no label or tooltip for: " + ", ".join(bare))

    assigned = {key: [] for key, _ in PAGES}
    for name, settings in options:
        assigned[page_for(name, bundles, categories)].append((name, settings))

    for key, order in CURATED.items():
        found = {name for name, _ in assigned[key]}
        if found != set(order):
            sys.exit("page " + key + " is missing " + ", ".join(sorted(set(order) - found)))
        assigned[key].sort(key=lambda row: order.index(row[0]))
    # eighty sliders on a page are only findable in the order the UI shows them
    for key in assigned:
        if key not in CURATED:
            assigned[key].sort(key=lambda row: (strings[key_for(row[0])], row[0]))

    changed = []
    # sandbox-options.txt is CRLF in this repo and .gitattributes normalises nothing
    write(OPTIONS, emit_options(assigned), "\r\n", changed, args.check)
    write(STRINGS, emit_strings(strings), "\n", changed, args.check)

    if args.check:
        if changed:
            print("out of date:\n  " + "\n  ".join(changed), file=sys.stderr)
            return 1
        print("sandbox options are up to date")
        return 0

    for key, title in PAGES:
        print("%-38s %3d" % (title, len(assigned[key])))
    print("changed:\n  " + "\n  ".join(changed) if changed else "no changes")
    return 0


if __name__ == "__main__":
    sys.exit(main())

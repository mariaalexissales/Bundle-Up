# Bundle Up!

[![checks](https://github.com/mariaalexissales/Bundle-Up/actions/workflows/check.yml/badge.svg)](https://github.com/mariaalexissales/Bundle-Up/actions/workflows/check.yml)
[![workshop parity](https://github.com/mariaalexissales/Bundle-Up/actions/workflows/parity.yml/badge.svg)](https://github.com/mariaalexissales/Bundle-Up/actions/workflows/parity.yml)
[![latest release](https://img.shields.io/github/v/release/mariaalexissales/Bundle-Up?label=release)](https://github.com/mariaalexissales/Bundle-Up/releases/latest)
[![workshop subscribers](https://img.shields.io/steam/subscriptions/3746632343?label=workshop%20subscribers)](https://steamcommunity.com/sharedfiles/filedetails/?id=3746632343)

Packing mod for Project Zomboid. Live on the Steam Workshop: 1,000+ packs covering ~700 vanilla items, 130 recipes, ~6,000 lines of Lua, 70+ merged PRs.

Project Zomboid is a zombie survival game. You loot everything, every item has weight and takes a slot, and a big base turns into shelves of half-full crates. Bundle Up packs those items into bundles, boxes, sacks and cartons and unpacks them exactly as they went in.

Packing is the simple part. Most of the work went into these:

- weights have to land before the save loads, or every saved bundle keeps the old weight
- packed food has to keep rotting at the right rate across a reload
- loot goes into tables another mod may be rewriting on the same event

The modding layer has no docs. Most of this README is what I found out by reading the game's code and breaking things.

![Bundle Up preview](preview.png)

**[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3746632343)** · [Releases](https://github.com/mariaalexissales/Bundle-Up/releases) · [Ko-fi](https://ko-fi.com/estralexe) · [Twitch](https://www.twitch.tv/itsestral)

---

## What it does

Put 99 nails in a box and half your base goes missing to server chunk rot. Sheet metal ends up spread across 20 crates because it won't fit in one. Bundle Up packs all of it down.

- **1,000+ packs covering ~700 vanilla items** across old and new B42 stock: rope bundles, boxes, bags, sacks, six-packs, cartons and cases.
- **Packing never launders an item.** Part-used, damaged, wet, loaded or rotten stock stays out, and what goes in comes back out exactly as it was, down to the colour of the wine.
- **Tiered packing.** Cartons pack into Cases, so a hoard that used to bottom out at "a shelf of cartons" collapses one more time. A Food Case takes four of any of the 166 food cartons, 48 items in a single slot.
- **Everything you drop is visible.** Every item carries a world model, so a dropped pack is an actual pile instead of thin air, and the 10-count bundles look bigger than the 5-count ones.
- **Food keeps rotting while it's packed.** A carton is storage, not a stasis pod. It chills, freezes and thaws on the same schedule as the loose food beside it.
- **Part-used stock merges back.** Half-empty spools, rolls and bottles merge into whole ones, and *Add to* / *Consolidate all* read every container in reach, not just your main inventory.
- **322 sandbox options** across eight pages: loot spawn rates, then per-category and per-item weight sliders grouped by the category each one inherits from, so servers can tune the whole thing without touching a file.

An optional UI add-on ships in the same subscription. The base mod has no dependencies and isn't gaining any.

One load-order note, if you also run Remove Vanilla Anything: both mods edit the loot tables on `OnGameStart`, and which goes first follows your mod list. Load Bundle Up first and *Also remove modded items* will strip its packs; load it second and they survive. Both work, so pick the one you want.

---

## How it's put together

| Path | What lives there |
| --- | --- |
| `Contents/mods/Vanilla/42/` | The base mod. ~16,000 lines of zedscript, ~4,300 of Lua, 322 sandbox options. |
| `Contents/mods/BundleUpUI/42/` | Optional UI add-on. ~1,800 lines of Lua, off by default, needs NeatUI Framework. |

The base mod's folder is called `Vanilla` because that's what it was named on the first day, and renaming it now would change every file path the Workshop has. Its id is `BundleUp`. B42 only reads the `42/` folder.

The Python lives in estral-tools, a private repo cloned next to this folder, one folder per mod. CI checks it out with a read-only deploy key. It reads the mod out of the working directory, so it runs from here.

[ARCHITECTURE.md](ARCHITECTURE.md) has the file-by-file map, the load order and how a change gets from here to the Workshop.

It's written in three languages. **zedscript** declares items, recipes and the flags the engine already enforces. **Lua** does what the scripts can't. **Python** generates the files too big to review by hand and checks the rest.

The `shared` / `client` / `server` split matters:

- **`shared/`**: weight and spoilage data, because a dedicated server has to get the same numbers its clients do.
- **`client/`**: inventory walks, which only touch what the local player can see.
- **`server/`**: loot injection. ~1,500 lines, mostly item and weight tables.

---

## Figuring out an engine with no docs

Most of the bugs here weren't logic errors. The engine did something I didn't know it did, and I found out by reading the game's code and testing in game.

### Which event you hook decides whether it works after a reload

Bundle weights come from sandbox sliders, so they have to be stamped onto the script items at load. `OnGameStart` is too late: by then the player's inventory is already loaded, so every bundle in the save was built from the unpatched script.

`OnInitGlobalModData` fires after the sandbox options load and before the inventory does. It's the only event where both are true.

```lua
-- OnInitGlobalModData is the only event after the sandbox loads and before any inventory
-- does. the other two are re-runs. guarded so a build without it keeps the rest.
if Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(BU.applyWeights)
end
Events.OnGameStart.Add(BU.applyWeights)
Events.OnServerStarted.Add(BU.applyWeights)
```

Only the `OnInitGlobalModData` registration is guarded, so a build without that event keeps going instead of dying on a nil index. `OnGameStart` still runs it either way, and `OnServerStarted` is the one a dedicated server fires.

Loot had the opposite problem and took a lot longer to find. Spawn rates also come from sliders, and `OnPreDistributionMerge` seemed like the right hook: it's named after the thing I want to change and fires before the loot tables are read. But `IsoWorld.init()` fires the merge events at bytecode offsets 2051 to 2066 and doesn't load the sandbox settings (`map_sand.bin`, via `SandboxOptions.load()`) until 2126.

It took so long to find because a new game works. The new-game screen has already loaded your settings, so the merge handler sees them. Every load after that only sees the defaults, and since `SandboxVars.BundleUp` exists either way, `if not sv then return end` doesn't catch it. Set loot to Double, play, quit, come back, and it's back to default with no error.

`OnInitGlobalModData`, the fix for weights, doesn't work for loot either. It fires after `ItemPickerJava.Parse()` has already copied the tables into Java, so it can't reach loot at all.

`OnGameStart` is the first event where the settings are loaded. Java already has its copy of the tables by then, so it has to be rebuilt with the same call vanilla's admin panel makes after a sandbox change:

```lua
-- loot is filled from the java copy taken at world init, before any of this, so rebuild
-- it. clients never read that copy. no StoryClutter.Init(), it would double-register.
local needed = (removed > 0 or inserted > 0) and not isClient()
local rebuilt = false
if needed and IsoWorld and IsoWorld.parseDistributions then
    rebuilt = pcall(function() IsoWorld.parseDistributions() end)
end
```

That rebuild re-reads every loot table in the game, other mods' too, so it only runs when something actually changed, and never on a multiplayer client.

Running that late also means running after every other mod has edited the same arrays. So instead of remembering *where* its entries went (an index another mod can shift), it remembers *what* it put in. Every name starts with `BundleUp.`, vanilla has none of them, and each goes in at most once per array, so removing by name is an exact undo and the pass can safely run again. A spawn rate of None now leaves the entry out instead of writing a weight of 0 into a vanilla table.

### Not calling `setCustomWeight`

`BU.refreshWeight` restamps bundles loaded from a save. It doesn't call `setCustomWeight`, because a custom weight stays on the item for good. Leaving it unset keeps the weight coming from the script, so the next sandbox change still reaches bundles already in someone's save.

### Food keeps its own spoil timers

Patching the script works for weight because an item copies its weight from the script when it's built. Food saves its own `offAge` and `offAgeMax`, so patching the script never reaches food that's already saved. Packed food needed a migration instead, and the order matters:

```lua
-- settle the age under the old thresholds first, or the days since lastAged
-- get counted at the new scale.
item:updateAge()
item:setAge(item:getAge() * (rotten / current))
```

Rescale first and every hour the item already spent in a crate gets recounted at the new spoil rate.

### No recipe flag reaches `ReplaceOnDeplete`

Some items leave a replacement behind when used up: use up a sack of gravel and the game hands you the empty sack. For a packing mod that's a sack dupe. No recipe flag turns it off, so it gets undone in Lua, but `onCreate` runs *before* the game makes the replacements. So it notes where each one will land and removes them next tick:

```lua
-- no recipe flag reaches ReplaceOnDeplete and onCreate runs before the sacks are
-- minted, so note where each will land and take it next tick.
```

### Other things I learned the hard way

- **`PetrolCan`'s `Fluids` block is what it starts with, not how much it holds.** A new can spawns with a full 10 litres, so unpacking *empty* cans handed out free petrol until the unpack started emptying them.
- **New `Food` has `lastFrozenUpdate = 0`.** Stamp it frozen and it melts next tick, because the game reads that 0 as a freeze long enough ago to have thawed. `updateAge()` first, *then* `copyFrozenFrom()`.
- **`getResultTexture()` calls `getFirstInputItem()` on every input**, so asking a row that's short an ingredient for its icon throws. Read the output mapper instead.
- **The soda test functions are built by string**, so grepping for `testPackOrangeSodaCan` finds nothing. That one has a comment pointing at the callers, because I lost twenty minutes to it.

---

## Packing never launders an item

The one rule the whole mod follows:

> What goes in comes back out exactly as it went in. Nothing gets made or lost on the way.

Breaking it means an item dupe or an item shredder, and players find those fast. After fixing the second one I realised they were the same bug in different places, so I went looking for the rest instead of waiting for reports.

| What broke | Which way |
| --- | --- |
| Part-used food packed into a carton and came back whole ([`4b9663c`](https://github.com/mariaalexissales/Bundle-Up/commit/4b9663c)) | Created value |
| Sack recipes consumed sacks that still had things in them ([`3cdb472`](https://github.com/mariaalexissales/Bundle-Up/commit/3cdb472)) | Destroyed value |
| Fresh cartons minted empty jars ([`ce52c77`](https://github.com/mariaalexissales/Bundle-Up/commit/ce52c77)) | Created value |
| Bag bundles minted empty sacks ([`bb6c0af`](https://github.com/mariaalexissales/Bundle-Up/commit/bb6c0af)) | Created value |
| Empty gas can bundles unpacked as full cans ([`c7eba3a`](https://github.com/mariaalexissales/Bundle-Up/commit/c7eba3a)) | Created value |
| Loaded magazines packed at all, losing the ammo ([`f4c7b10`](https://github.com/mariaalexissales/Bundle-Up/commit/f4c7b10)) | Destroyed value |

The pass that closed the rest by rule instead of by report was [`7a9af17`](https://github.com/mariaalexissales/Bundle-Up/commit/7a9af17) in [PR #48](https://github.com/mariaalexissales/Bundle-Up/pull/48): every unpack input got the exclusivity flags.

Where the engine has a flag for a guard, the guard goes in the script. `IsEmpty`, `IsFull`, `IsUndamaged`, `IsExclusive` and `ItemCount` are enforced by the engine, work the same on a dedicated server, and no Lua code path can skip them. A Lua `onTest` is only for when there's no flag.

`testPackPerishable` needed Lua:

```lua
function BUInv.testPackPerishable(item, character)
    -- isRotten is Food-only. the non-perishable cartons are base:normal, so this
    -- guard is what keeps the handcraft window from dying on them.
    return item == nil or not item:IsFood() or not item:isRotten()
end
```

`isRotten()` only exists on `Food`, and the non-perishable cartons are `base:normal`. Before that type check went in, opening the crafting window near one of them crashed the whole UI.

---

## The optional UI add-on

`BundleUpUI` adds a panel that reads every container in reach and lists everything you could pack, unpack or merge right now, with a `-` / `+` / `MAX` dial per row and a **Bundle All** that runs everything ready at once. It's a separate mod in the same subscription, off by default, and the base mod works the same with or without it.

**It finds recipes by module name.** The panel builds its list from `ScriptManager.instance:getAllCraftRecipes()`, filtered on one table:

```lua
BUUI.modules = BUUI.modules or { BundleUp = true }
```

The base mod needed no changes for it, and another packing mod only has to add its module name to that table to show up.

**It finds what a craft made by diffing item IDs.** `CraftRecipeData` doesn't give Lua a list of what it created, so the queue snapshots inventory IDs before the craft and diffs after:

```lua
-- CraftRecipeData exposes no created-items list to Lua, so what the craft made is
-- whatever is in the player's inventory that was not there when it started.
```

It filters that diff to the expected output types, so anything you picked up mid-craft doesn't get moved into a container. If it can't work out the output types, it uses the raw diff instead of guessing. A wrong guess would leave the real outputs stuck in your inventory, while a diff that's slightly too wide only moves one extra item.

**It patches vanilla UI once.** The sidebar button wraps four `ISEquippedItem` methods behind a `BUUI_PatchApplied` flag so loading twice can't wrap twice. It patches on `OnGameStart`, not at file load, because the sidebar isn't finished building at file load.

**It measures the crafting popup.** Where the sidebar button goes depends on how wide the crafting popup is, and Project Cook makes it two cells wide. Instead of special-casing that mod or relying on load order, it measures the popup every frame, so any other mod that widens it works too.

**It picks the main input by amount.** The panel picks each recipe's main input by the biggest amount, not by `flags[ItemCount]`, because the flags aren't consistent across the recipe files. `BoxSmall` has none at all, but every recipe has amounts.

---

## Generated content

There are 166 food cartons, each needing an item block, a pack and an unpack recipe, a weight row and a display name. That's too much to review by hand, so the upper tiers are generated from the pack ladders the mod already declares.

`generate_tiers.py` reads `BU_WeightData_Packs.lua` and writes three whole files stamped *do not edit by hand*, plus a sorted block at the end of `ItemName.json` and `Recipes.json`. All of it is committed. Running it again with no source change must produce no diff, and `--check` enforces that on every PR.

`generate_sandbox.py` does the same for `sandbox-options.txt`. A per-item slider belongs on the page of the category slider that item inherits from, which means walking `resolve_base` down to the vanilla item the same way `BU_ApplyWeights.lua` does in game. Doing that by hand for 322 options is where typos come from, and deriving it keeps the pages right when new tiers land. Labels and tooltips are written by hand and the generator doesn't touch them. It owns block order, `page =` values and the eight page titles, nothing else.

`generate_tiers.py` stops with an error, not a warning, on anything that would produce wrong output, like a carton packed by a recipe with no weight row, or one that resolves to a non-food category. It decides tier membership from the *recipes*, not item-name suffixes, because `DogFoodBagCrate` doesn't end in "Carton" and would have been skipped.

`sync_weights.py` works out each pack's script `Weight`. The Lua sets weights on the client, but a dedicated server reads the script value, so the two have to agree.

---

## Working on it

The repo is the mod folder. It lives at `Zomboid/Workshop/Bundle Up` and the game loads it in place, so there's no build step.

Check the generated files are current (drop `--check` to regenerate after changing a pack ladder):

```bash
python ../estral-tools/bundle-up/generate_tiers.py --check
python ../estral-tools/bundle-up/generate_sandbox.py --check
python ../estral-tools/bundle-up/sync_weights.py --check
```

Run the rest of what CI runs:

```bash
python ../estral-tools/bundle-up/check_translations.py
python ../estral-tools/bundle-up/check_scripts.py
python ../estral-tools/bundle-up/check_lua.py
python ../estral-tools/bundle-up/check_line_endings.py
```

All of them are stdlib-only except `check_lua.py`, which needs `luaparser`. `sync_weights.py --refresh` needs a Project Zomboid install to rebuild the vanilla weights it starts from; `--check` doesn't.

A topic branch per bug or feature goes into `dev`, and `dev` goes into `main` at release. `main` matches the published Workshop build byte for byte, because Project Zomboid won't let you join a server whose mod files differ.

---

## Checks and releases

Every push and PR runs these, and `dev` and `main` only take a merge when they pass:

| Check | What it catches |
| --- | --- |
| Tiers are up to date | A pack ladder changed and the generated tiers weren't regenerated, or a generated file was edited by hand and the next regenerate would undo it. |
| Sandbox options are up to date | A new slider with no label, or on the page of a category it doesn't inherit from. |
| Script weights are up to date | A pack whose script `Weight` disagrees with the Lua. Dedicated servers read the script, so everyone on a server gets the wrong weight. |
| Every item, recipe and label has a name | Broken JSON, a missing name, or a name left over from a deleted item. None of these error in game; the label just shows its raw key. |
| Scripts only point at things that exist | A recipe that outputs an undeclared item never shows up, and a typo in `DoubleClickRecipe` makes double click do nothing. |
| Lua files parse | A syntax error only shows up once the game loads the file, and then the whole file is skipped. |
| No file mixes line endings | Files are CRLF or LF one by one and nothing normalises them. A patch that writes LF lines into a CRLF file doesn't show in most editors, but it changes the bytes the Workshop compares. |

The checks are scripts in estral-tools, the same ones I run locally.

**Workshop parity.** Every morning CI downloads the live Workshop build with steamcmd and diffs it against `main`. Any file that differs turns it red.

**Releases.** Pushing a version tag publishes a [GitHub release](https://github.com/mariaalexissales/Bundle-Up/releases) with the patch notes from that version's release PRs, every PR and commit that went into it, and the Workshop build zipped. Every version back to 1.21 has one. The Workshop upload itself is still done by hand, because it needs a Steam login. Steam has its own [change notes](https://steamcommunity.com/sharedfiles/filedetails/changelog/3746632343) for each upload.

**PR titles** have to start with `fix:`, `feat:`, `chore:`, `refactor:`, `docs:` or `[Patch 2.x] -`, so the history says what changed. **Dependabot** keeps the workflow actions current and opens its PRs against `dev`, never `main`.

---

## On the way

- Engine Parts
- Clay Bricks

## Credits

By **Estral**. The UI add-on is built on [NeatUI Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3508537032) by Rocco & Afyrmo.

Found a bug or want something packed? Use the [bug report or coverage form](https://github.com/mariaalexissales/Bundle-Up/issues/new/choose), or leave a comment on the Workshop page.

## More from Estral

- **[Pinoy Pantry](https://steamcommunity.com/sharedfiles/filedetails/?id=3791631305)**: sarap ng Pinas in Knox Country
- **[Quest System Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3794717412)**: add quests to your multiplayer servers

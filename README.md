# Bundle Up!

[![checks](https://github.com/mariaalexissales/Bundle-Up/actions/workflows/check.yml/badge.svg)](https://github.com/mariaalexissales/Bundle-Up/actions/workflows/check.yml)

Packing mod for Project Zomboid. Live on the Steam Workshop: 1,000+ items, 120+ recipes, ~6,000 lines of Lua, 60+ merged PRs.

Project Zomboid is a zombie survival game. You loot everything, every item has weight and takes a slot, and a big base turns into shelves of half-full crates. Bundle Up packs those items into bundles, boxes, sacks and cartons and unpacks them exactly as they went in.

The packing is the easy part. The hard part:

- weights have to land before the save loads, or every saved bundle keeps the old weight
- packed food has to keep rotting at the right rate across a reload
- loot goes into tables another mod may be rewriting on the same event

The modding layer has no docs. Most of this README is what I found out by reading the game's code and breaking things.

![Bundle Up preview](preview.png)

**[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3746632343)** · [Ko-fi](https://ko-fi.com/estralexe) · [Twitch](https://www.twitch.tv/itsestral)

---

## What it does

Put 99 nails in a box and half your base goes missing to server chunk rot. Spread sheet metal across 20 crates because it won't fit in one. That's the problem this solves.

- **1,000+ items covered** across old and new B42 stock — rope bundles, boxes, bags, sacks, six-packs, cartons and cases.
- **Packing never launders an item.** Part-used, damaged, wet, loaded or rotten stock stays out, and what goes in comes back out exactly as it was, down to the colour of the wine.
- **Tiered packing.** Cartons pack into Cases, so a hoard that used to bottom out at "a shelf of cartons" collapses one more time. A Food Case takes four of any of the 166 food cartons — 48 items in a single slot.
- **Everything you drop is visible.** Every item carries a world model, so a dropped pack is an actual pile instead of thin air, and the 10-count bundles look bigger than the 5-count ones.
- **Food keeps rotting while it's packed.** A carton is storage, not a stasis pod — it chills, freezes and thaws on the same schedule as the loose food beside it.
- **Part-used stock merges back.** Half-empty spools, rolls and bottles merge into whole ones, and *Add to* / *Consolidate all* read every container in reach, not just your main inventory.
- **322 sandbox options** across eight pages — loot spawn rates, then per-category and per-item weight sliders grouped by the category each one inherits from, so servers can tune the whole thing without touching a file.

An optional UI add-on ships in the same subscription. The base mod has no dependencies and isn't gaining any.

One load-order note, if you also run [Remove Vanilla Anything](https://github.com/mariaalexissales/Remove-Vanilla-Anything): both mods edit the loot tables on `OnGameStart`, and which goes first follows your mod list. Load Bundle Up first and *Also remove modded items* will strip its packs; load it second and they survive. Neither order is broken, but only one of them is probably what you meant.

---

## How it's put together

| Path | What lives there |
| --- | --- |
| `Contents/mods/Vanilla/42/` | The base mod. ~14,000 lines of zedscript, ~4,000 of Lua, 322 sandbox options. |
| `Contents/mods/BundleUpUI/42/` | Optional UI add-on. ~1,800 lines of Lua, off by default, needs NeatUI Framework. |
| `Contents/mods/Vanilla/media/` | Old B41 files, kept for pre-B42 loads. |
| `tools/` | Python generators and art tooling. |

Three languages. **zedscript** declares items, recipes and the flags the engine already enforces. **Lua** does what the scripts can't. **Python** generates the files too big to review by hand.

The `shared` / `client` / `server` split matters:

- **`shared/`**: weight and spoilage data, because a dedicated server has to get the same numbers its clients do.
- **`client/`**: inventory walks, which only touch what the local player can see.
- **`server/`**: loot injection. ~1,500 lines, mostly item and weight tables.

---

## Figuring out an engine with no docs

Most of the bugs here weren't logic errors. The engine did something reasonable I didn't know about, and the only way to find out was reading the game's code and watching what happened.

### Which event you hook decides whether it works after a reload

Bundle weights come from sandbox sliders, so they have to be stamped onto the script items at load. `OnGameStart` looks right and isn't. By then the player's inventory is already loaded, so every bundle in the save was built from the unpatched script.

`OnInitGlobalModData` fires after the sandbox options load and before the inventory does. It's the only event where both are true.

```lua
-- OnInitGlobalModData is the first event to fire after SandboxOptions.load(),
-- and it lands before the cell deserializes any inventory, so a saved bundle is
-- built from an already-patched script item.
if Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(BU.applyWeights)
end
Events.OnGameStart.Add(BU.applyWeights)
```

Only the `OnInitGlobalModData` registration is guarded, so a build without that event keeps going instead of dying on a nil index. `OnGameStart` still runs it either way.

Loot was the same problem backwards, and it took a lot longer. Spawn rates also come from sliders, so `OnPreDistributionMerge` looks right: it's named after the thing I want to change and fires before the loot tables are read. It's wrong. `IsoWorld.init()` fires the merge events at bytecode offsets 2051–2066 and doesn't load the sandbox settings (`map_sand.bin`, via `SandboxOptions.load()`) until 2126.

That's why it hid for so long. On a new game the merge handler sees your real settings, because the new-game screen already loaded them. On every load after that it only sees the defaults, and since `SandboxVars.BundleUp` exists either way, `if not sv then return end` doesn't catch it. Set loot to Double, play, quit, come back, and it's quietly back to default. No error anywhere.

`OnInitGlobalModData`, the right answer for weights, is worse for loot. It fires after `ItemPickerJava.Parse()` has already copied the tables into Java, so it can't reach loot at all.

`OnGameStart` is the first event where the settings are real. The catch is Java already has its copy, so it has to be rebuilt, with the same call vanilla's admin panel makes after a sandbox change:

```lua
-- fillContainer returns straight away on a client, so the java copy there is never read.
local needed = (removed > 0 or inserted > 0) and not isClient()
local rebuilt = false
if needed and IsoWorld and IsoWorld.parseDistributions then
    rebuilt = pcall(function() IsoWorld.parseDistributions() end)
end
```

That rebuild re-reads every loot table in the game, other mods' too, so it only runs when something actually changed, and never on a multiplayer client.

Running that late also means running after every other mod has edited the same arrays. So instead of remembering *where* its entries went (an index another mod can shift), it remembers *what* it put in. Every name starts with `BundleUp.`, vanilla has none of them, and each goes in at most once per array, so removing by name is an exact undo and the pass can safely run again. A spawn rate of None now leaves the entry out instead of writing a weight of 0 into a vanilla table.

### Sometimes the fix is not calling the API

`BU.refreshWeight` restamps bundles loaded from a save and never calls `setCustomWeight`. A custom weight is pinned for good. Leaving it unset keeps the weight coming from the script, so the *next* sandbox change still reaches bundles already in someone's save.

### Same problem, opposite fix

Weights patch cleanly on the script because an item copies its weight from the script when it's built. Food doesn't. It saves its own `offAge` and `offAgeMax`, so patching the script never reaches food that's already saved. Packed food needed a migration instead, and the order matters:

```lua
-- settle the age under the old thresholds first, or the days since lastAged
-- get counted at the new scale.
item:updateAge()
item:setAge(item:getAge() * (rotten / current))
```

Rescale first and every hour the item already spent in a crate gets recounted at the new spoil rate.

### No recipe flag reaches `ReplaceOnDeplete`

Some containers leave a replacement behind when used up. Use up a sack of gravel and the game hands you the empty sack. Fine for cooking, a sack dupe for a packing mod. No recipe flag turns it off, so it gets undone in Lua, but `onCreate` runs *before* the game makes them. So it writes down where each one will land and sweeps them up next tick:

```lua
-- no recipe flag reaches ReplaceOnDeplete, so the minted sacks have to go in
-- lua. onCreate runs before processDestroyAndUsedItems creates them - note
-- where each will land, take it next tick.
```

### Stuff you only know after it bites you

- **`PetrolCan`'s `Fluids` block is what it starts with, not how much it holds.** A new can spawns with a full 10 litres, so unpacking *empty* cans handed out free petrol until the unpack started emptying them.
- **New `Food` has `lastFrozenUpdate = 0`.** Stamp it frozen and it melts next tick, because the game reads that 0 as frozen since the beginning of time. `updateAge()` first, *then* `copyFrozenFrom()`.
- **`getResultTexture()` calls `getFirstInputItem()` on every input**, so asking a row that's short an ingredient for its icon throws. Read the output mapper instead.
- **The soda test functions are built by string**, so grepping for `testPackOrangeSodaCan` finds nothing. That one has a comment pointing at the callers, because I lost twenty minutes to it and wasn't doing that twice.

---

## Packing never launders an item

One rule holds the whole mod up:

> What goes in comes back out exactly as it went in. Nothing gets made or lost on the way.

Break it and you've built an item dupe or an item shredder, and players find those fast. After fixing the second one I realised they were the same bug in different places, so I went looking for the rest instead of waiting for reports.

| What broke | Which way |
| --- | --- |
| Part-used food packed into a carton and came back whole ([`4b9663c`](https://github.com/mariaalexissales/Bundle-Up/commit/4b9663c)) | Created value |
| Sack recipes consumed sacks that still had things in them ([`3cdb472`](https://github.com/mariaalexissales/Bundle-Up/commit/3cdb472)) | Destroyed value |
| Fresh cartons minted empty jars ([`ce52c77`](https://github.com/mariaalexissales/Bundle-Up/commit/ce52c77)) | Created value |
| Bag bundles minted empty sacks ([`bb6c0af`](https://github.com/mariaalexissales/Bundle-Up/commit/bb6c0af)) | Created value |
| Empty gas can bundles unpacked as full cans ([`c7eba3a`](https://github.com/mariaalexissales/Bundle-Up/commit/c7eba3a)) | Created value |
| Loaded magazines packed at all, losing the ammo ([`f4c7b10`](https://github.com/mariaalexissales/Bundle-Up/commit/f4c7b10)) | Destroyed value |

The pass that closed the rest by rule instead of by report was [`7a9af17`](https://github.com/mariaalexissales/Bundle-Up/commit/7a9af17) in [PR #48](https://github.com/mariaalexissales/Bundle-Up/pull/48): every unpack input got the exclusivity flags.

**What I'd do again:** put the guard in the script flags whenever the engine has one. `IsEmpty`, `IsFull`, `IsUndamaged`, `IsExclusive` and `ItemCount` are enforced by the engine, work the same on a dedicated server, and can't be skipped by some code path I forgot. Only fall back to a Lua `onTest` when there's no flag for it.

`testPackPerishable` is one that needed Lua, and it shows why these need care:

```lua
function BUInv.testPackPerishable(item, character)
    -- isRotten is Food-only. the non-perishable cartons are base:normal, so this
    -- guard is what keeps the handcraft window from dying on them.
    return item == nil or not item:IsFood() or not item:isRotten()
end
```

`isRotten()` only exists on `Food`. The non-perishable cartons are `base:normal`. Before that type check, opening the crafting window near the wrong carton crashed the whole UI. It shipped as a crash before it shipped as a check.

---

## The optional UI add-on

`BundleUpUI` adds a panel that reads every container in reach and lists everything you could pack, unpack or merge right now, with a `-` / `+` / `MAX` dial per row and a **Bundle All** that runs everything ready at once. It's a separate mod in the same subscription, off by default, and the base mod doesn't know or care if it's there.

**It finds recipes by module name.** The panel builds its list from `ScriptManager.instance:getAllCraftRecipes()`, filtered on one table:

```lua
BUUI.modules = BUUI.modules or { BundleUp = true }
```

That's the whole integration. The base mod needed no changes, and another packing mod only has to add its module name to show up.

**It finds what a craft made by diffing item IDs.** `CraftRecipeData` doesn't give Lua a list of what it created, so the queue snapshots inventory IDs before the craft and diffs after:

```lua
-- CraftRecipeData exposes no created-items list to Lua, so what the craft made is
-- whatever is in the player's inventory that was not there when it started.
```

It filters that diff to the expected output types, so anything you picked up mid-craft doesn't get moved into a container. If it can't work out the output types, it uses the raw diff instead of guessing. A wrong guess would leave the real outputs stuck in your inventory. A slightly too-wide diff is the better way to fail.

**It patches vanilla UI once.** The sidebar button wraps four `ISEquippedItem` methods behind a `BUUI_PatchApplied` flag so loading twice can't wrap twice. It patches on `OnGameStart`, not at file load, because the sidebar isn't finished building at file load.

**It measures instead of assuming.** Where the sidebar button goes depends on how wide the crafting popup is, and Project Cook makes it two cells wide. Instead of special-casing that mod or relying on load order, it measures the popup every frame. Works with mods that don't exist yet.

**It trusts the amounts over the flags.** The panel picks each recipe's main input by the biggest amount, not by `flags[ItemCount]`, because the flags aren't consistent across the recipe files. `BoxSmall` has none at all. The amounts were always right.

---

## Generated content

166 food cartons, each needing an item block, both halves of a pack/unpack recipe, a weight row and a display name. That's not reviewable by hand, so the upper tiers are generated from the ladders the mod already declares.

`tools/generate_tiers.py` reads `BU_WeightData_Packs.lua` and emits five files, all committed and stamped *do not edit by hand*. The contract is in the docstring: **re-running with no source change must produce no diff**, and `--check` enforces it on every PR.

`tools/generate_sandbox.py` does the same job for `sandbox-options.txt`. Splitting 322 options across eight pages by hand is one typo away from a slider that silently reads the wrong var, and the page a per-item slider belongs on isn't a matter of taste — it's whichever category slider that item actually inherits from, which means walking `resolve_base` down to the vanilla item exactly as `BU_ApplyWeights.lua` does at runtime. Deriving it is the only way the two stay in agreement when a new tier batch lands. Labels and tooltips are hand-written prose and the generator rewrites none of them; it owns block order, `page =` values and the eight page titles, nothing else.

It raises rather than warns on anything that would silently produce wrong output — a carton packed by a recipe with no weight row, or one resolving to a non-food reduction category. It also determines tier membership from the *recipes* rather than item-name suffixes, because `DogFoodBagCrate` doesn't end in "Carton" and would have been dropped without a word.

---

## Working on it

The repo is the mod folder — it lives at `Zomboid/Workshop/Bundle Up` and the game loads it in place, so there's no build step and no packaging.

Check that the generated files are current:

```bash
python tools/generate_tiers.py --check && python tools/generate_sandbox.py --check
```

Regenerate them after changing a pack ladder:

```bash
python tools/generate_tiers.py && python tools/generate_sandbox.py
```

Both are stdlib-only — no install, no virtualenv — and CI runs both on every push and PR. Neither may import `tools/sync_weights.py`, which is gitignored and absent on CI.

Branching is `dev` → `main` with a topic branch per bug or feature, and `main` mirrors the published Workshop build. `tools/sync_weights.py` and `tools/base_weights.json` are gitignored: they resolve script weights for dedicated servers (which read script values rather than the client Lua) and need a Project Zomboid install to regenerate, so they stay local.

---

## On the way

- Engine Parts
- Clay Bricks

## Credits

By **Estral**. The UI add-on is built on [NeatUI Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3508537032) by Rocco & Afyrmo.

Bug reports and coverage suggestions are welcome, in the Workshop comments or as an issue here.

## More from Estral

- **[Pinoy Pantry](https://steamcommunity.com/sharedfiles/filedetails/?id=3791631305)** — sarap ng Pinas in Knox Country
- **[Quest System Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3794717412)** — add quests to your multiplayer servers

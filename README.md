# Bundle Up!

[![checks](https://github.com/mariaalexissales/Bundle-Up/actions/workflows/check.yml/badge.svg)](https://github.com/mariaalexissales/Bundle-Up/actions/workflows/check.yml)

**A Project Zomboid inventory-compaction mod — 1,020 item definitions, 118 crafting recipes and ~5,200 lines of Lua, shipped on the Steam Workshop and maintained across 49 merged PRs.**

The visible half packs a thousand vanilla items into bundles, boxes, sacks and cartons, then unpacks them back. The half that took the actual work is the part nobody sees: getting weights patched into script items *before* the engine deserializes a save, keeping spoilage math honest across a reload, and injecting loot into shared tables that another mod is rewriting on the same event.

Project Zomboid's modding layer has no formal API and no reference docs. Most of what follows is the record of finding out how it behaves by reading the game's own Lua and watching things break.

![Bundle Up preview](preview.png)

**[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3746632343)** · [Ko-fi](https://ko-fi.com/estralexe) · [Twitch](https://www.twitch.tv/itsestral)

---

## What it does

Put 99 nails in a box and half your base goes missing to server chunk rot. Spread sheet metal across 20 crates because it won't fit in one. That's the problem this solves.

- **1,000+ items covered** across old and new B42 stock — rope bundles, boxes, bags, sacks, six-packs, cartons and cases.
- **Packing never launders an item.** Part-used, damaged, wet, loaded or rotten stock stays out, and what goes in comes back out exactly as it was, down to the colour of the wine.
- **Tiered packing.** Cartons pack into Cases, so a hoard that used to bottom out at "a shelf of cartons" collapses one more time. A Food Case takes four of any of the 166 food cartons — 48 items in a single slot.
- **Everything you drop is visible.** All 1,020 items carry a world model, so a dropped pack is an actual pile instead of thin air, and the 10-count bundles look bigger than the 5-count ones.
- **Food keeps rotting while it's packed.** A carton is storage, not a stasis pod — it chills, freezes and thaws on the same schedule as the loose food beside it.
- **322 sandbox options** across eight pages — loot spawn rates, then per-category and per-item weight sliders grouped by the category each one inherits from, so servers can tune the whole thing without touching a file.

An optional UI add-on ships in the same subscription. The base mod has no dependencies and isn't gaining any.

One load-order note, if you also run [Remove Vanilla Anything](https://github.com/mariaalexissales/Remove-Vanilla-Anything): both mods edit the loot tables on `OnGameStart`, and which goes first follows your mod list. Load Bundle Up first and *Also remove modded items* will strip its packs; load it second and they survive. Neither order is broken, but only one of them is probably what you meant.

---

## How it's put together

| Path | What lives there |
| --- | --- |
| `Contents/mods/Vanilla/42/` | The base mod. 13,632 lines of zedscript, 3,685 of Lua, 322 sandbox options. |
| `Contents/mods/BundleUpUI/42/` | Optional UI add-on. 1,587 lines of Lua, opt-in, hard-requires NeatUI Framework. |
| `Contents/mods/Vanilla/media/` | Legacy B41-era tree kept as a fallback for pre-B42 loads. |
| `tools/` | Python codegen and art tooling. |

Three languages, each doing the thing it's least bad at. **zedscript** declares content — items, recipes, the flags the engine already knows how to enforce. **Lua** covers behaviour the scripts can't express. **Python** generates the content that would be unreviewable by hand.

The `shared` / `client` / `server` split is deliberate and load-bearing:

- **`shared/`** — weight and spoilage data, because a dedicated server has to arrive at the same numbers its clients do.
- **`client/`** — inventory walks, which only ever touch what the local player can actually see.
- **`server/`** — loot injection, 1,469 lines of it across 20 distribution calls.

---

## Reading an engine that doesn't document itself

Most of the interesting bugs here weren't logic errors. They were cases where the engine did something reasonable that I hadn't accounted for, and finding out meant reading the game's Lua and watching what actually happened.

### The event you register on decides whether your mod works after a reload

Bundle weights come from sandbox sliders, so they have to be stamped onto script items at load. The obvious hook is `OnGameStart`. `OnGameStart` is wrong — by then the cell has already deserialized the player's inventory, and every bundle in that save was built from an unpatched script.

`OnInitGlobalModData` is the first event that fires after `SandboxOptions.load()` and still lands *before* inventory deserialization, which makes it the only window where both facts are true.

```lua
-- OnInitGlobalModData is the first event to fire after SandboxOptions.load(),
-- and it lands before the cell deserializes any inventory, so a saved bundle is
-- built from an already-patched script item.
if Events.OnInitGlobalModData then
    Events.OnInitGlobalModData.Add(BU.applyWeights)
end
Events.OnGameStart.Add(BU.applyWeights)
```

Every event registration in the mod is guarded like that, so a build that doesn't have the event degrades instead of taking the whole file down with a nil index. `OnGameStart` stays on as a harmless re-run.

Loot is the same lesson inverted, and it cost a lot more to learn. Spawn rates also come from sandbox sliders, so `OnPreDistributionMerge` looks like the obvious hook — it is named after the thing it wants to change and it fires before the loot tables are read. It is wrong. `IsoWorld.init()` fires the three merge events at bytecode offsets 2051–2066 but does not read `map_sand.bin` until offset 2126, where `SandboxOptions.load()` ends in `toLua()`.

That gap is why the bug hid for so long. On a **new game** a merge handler sees the player's real settings, because the new-game screen already ran `toLua()`. On **every later load of that save** it sees nothing but the declared defaults — and since `SandboxVars.BundleUp` exists either way, a `if not sv then return end` guard catches none of it. Set loot to Double, play, quit, come back, and the rate silently reverts with no error anywhere.

`OnInitGlobalModData` — the right answer for weights — is worse still here. It lands *after* `ItemPickerJava.Parse()` has snapshotted the tables into Java, so it can never reach loot at all.

`OnGameStart` runs from `IngameState`, after `IsoWorld.init()` has returned, so it is the first event where the settings are real. The cost of arriving that late is that Java already has its copy, and rebuilding it takes the call vanilla's own admin panel makes after a sandbox change:

```lua
local rebuilt = false
if IsoWorld and IsoWorld.parseDistributions then
    rebuilt = pcall(function() IsoWorld.parseDistributions() end)
end
```

Arriving after every other mod has loaded also means arriving after they have rewritten the arrays. The fix stopped recording *where* its entries went — an index another mod is free to invalidate — and started recording *what* it inserts. Every name is `BundleUp.*`, vanilla has none of them, and each lands at most once per array, so removing by name is an exact undo and the whole pass becomes re-runnable. A spawn rate of None now drops the entry instead of writing a weight of zero into a vanilla table.

### Not calling the API is sometimes the fix

`BU.refreshWeight` restamps bundles restored from a save, and deliberately never calls `setCustomWeight`. Setting a custom weight would pin the number permanently; leaving it unset keeps the weight script-derived, so the *next* sandbox change still reaches bundles already sitting in someone's save file.

### The same problem, needing the opposite solution

Weights patch cleanly at the script level because an item copies its weight from the script when it's built. Food doesn't work that way — it serializes its own `offAge` and `offAgeMax`, so patching the script never reaches anything already saved. Packed food needed a migration path instead, and the order matters:

```lua
-- settle the age under the old thresholds first, or the days since lastAged
-- get counted at the new scale.
item:updateAge()
item:setAge(item:getAge() * (rotten / current))
```

Rescale before settling and every hour the item spent in a crate gets retroactively recounted at the new spoil rate.

### `ReplaceOnDeplete` can't be reached from a recipe flag

Some containers mint a replacement when consumed — use up a sack of gravel and the engine hands you the empty sack. Correct for cooking, an infinite sack duplicator for a packing mod. No recipe flag suppresses it, so it has to be undone in Lua, and `onCreate` runs *before* the engine creates them. The fix records where each replacement is going to land and sweeps them on the next tick:

```lua
-- no recipe flag reaches ReplaceOnDeplete, so the minted sacks have to go in
-- lua. onCreate runs before processDestroyAndUsedItems creates them - note
-- where each will land, take it next tick.
```

### Some of it is just trivia you have to have been bitten by

- **`PetrolCan`'s `Fluids` block is initial contents, not capacity.** A freshly created can spawns holding a full 10 litres, so unpacking a bundle of *empty* cans mints petrol unless you explicitly empty them.
- **New `Food` has `lastFrozenUpdate = 0`.** Stamp a frozen state onto it and it melts on the next tick, because the engine reads that zero as "frozen since the beginning of time". `updateAge()` first, *then* `copyFrozenFrom()`.
- **`getResultTexture()` dereferences `getFirstInputItem()` on every input**, so asking a blocked row for its icon throws. Read the output mapper instead.
- **A whole family of test functions is built by string concatenation**, which means grepping for `testPackOrangeSodaCan` finds nothing at all. That one has a comment pointing at where the callers live, because I lost twenty minutes to it and wasn't going to do that twice.

---

## Packing must never launder an item

One invariant holds the whole mod up:

> What goes in comes back out exactly as it went in, and nothing is created or destroyed on the way.

Every violation is an item duplicator or an item shredder, and players find those immediately. Once I'd fixed the second one it was obvious they weren't unrelated bugs — they were one bug wearing different hats, so I went looking for the rest of the family instead of waiting for the reports.

| What broke | Which direction it broke |
| --- | --- |
| Part-used food packed into a carton and came back whole ([`4b9663c`](https://github.com/mariaalexissales/Bundle-Up/commit/4b9663c)) | Created value |
| Sack recipes consumed sacks that still had things in them ([`3cdb472`](https://github.com/mariaalexissales/Bundle-Up/commit/3cdb472)) | Destroyed value |
| Fresh cartons minted empty jars ([`ce52c77`](https://github.com/mariaalexissales/Bundle-Up/commit/ce52c77)) | Created value |
| Bag bundles minted empty sacks ([`bb6c0af`](https://github.com/mariaalexissales/Bundle-Up/commit/bb6c0af)) | Created value |
| Empty gas can bundles unpacked as full cans ([`c7eba3a`](https://github.com/mariaalexissales/Bundle-Up/commit/c7eba3a)) | Created value |
| Loaded magazines packed at all, losing the ammo ([`f4c7b10`](https://github.com/mariaalexissales/Bundle-Up/commit/f4c7b10)) | Destroyed value |

The generalising pass was [PR #48](https://github.com/mariaalexissales/Bundle-Up/pull/48) — *give every unpack input the exclusivity flags* — which closed the remaining holes by rule rather than by report.

**The design lesson I'd actually repeat:** put the guard in the script flags wherever the engine offers one. `IsEmpty`, `IsFull`, `IsUndamaged`, `IsExclusive` and `ItemCount` are enforced by the engine, work identically on a dedicated server, and can't be bypassed by a code path I forgot about. Only drop to a Lua `onTest` callback when there's genuinely no flag for it.

`testPackPerishable` is one of the few that earned it, and it's a good illustration of why these are worth being careful with:

```lua
function BUInv.testPackPerishable(item, character)
    -- isRotten is Food-only. the non-perishable cartons are base:normal, so this
    -- guard is what keeps the handcraft window from dying on them.
    return item == nil or not item:IsFood() or not item:isRotten()
end
```

`isRotten()` only exists on `Food`. The non-perishable cartons are `base:normal`. Before that type guard existed, opening the crafting window near the wrong carton took the whole UI down — it shipped as a crash before it shipped as a check.

---

## The optional UI add-on

`BundleUpUI` adds a panel that reads every container in reach and lists everything you could pack right now, with a `-` / `+` / `MAX` dial per row and a **Bundle All** that maxes out everything ready at once. It's a separate mod in the same subscription, off by default, and the base mod neither knows nor cares whether it's installed.

**Indexed by module prefix, not by recipe name.** The panel builds its index from `ScriptManager.instance:getAllCraftRecipes()` filtered on one table:

```lua
BUUI.modules = BUUI.modules or { BundleUp = true }
```

That's the entire integration contract. The base mod needed no changes to be supported, and another packing mod only has to add its module name to be picked up for free.

**Outputs are detected by diffing inventory item IDs.** `CraftRecipeData` exposes no created-items list to Lua, so the queue snapshots inventory IDs before the craft and takes the difference after:

```lua
-- CraftRecipeData exposes no created-items list to Lua, so what the craft made is
-- whatever is in the player's inventory that was not there when it started.
```

It filters that diff by resolved output types so anything picked up mid-craft doesn't get swept into a container. When the mapper can't be resolved, it deliberately falls back to the raw diff rather than filtering on a guess — a guess would strand the real outputs in the player's inventory, and a slightly over-broad diff is the better failure.

**Monkey-patching vanilla UI, idempotently.** The sidebar button wraps four `ISEquippedItem` methods behind a `BUUI_PatchApplied` flag so a double-load can't double-wrap, and applies on `OnGameStart` rather than at file load, because wrapping during UI boot catches the class half-built.

**Measuring instead of assuming.** The sidebar cell's position depends on how wide the crafting popup is, and Project Cook makes it two cells wide. Rather than special-casing that mod or depending on load order, the patch measures the popup's width every frame and computes the offset. Works against mods that don't exist yet.

**Trusting the data over the metadata.** The panel picks each recipe's pivot input by largest amount rather than by `flags[ItemCount]`, because those flags turned out to be inconsistent across the recipe files — `BoxSmall` carries none at all. The amounts were always right; the flags weren't.

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

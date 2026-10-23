# BLOX FRUITS SUITE — v12.0

A complete rewrite of the *Real Luck System v11* into a properly structured,
self-contained client-side suite for Blox Fruits.

**v12 is honest about what it can do.** The v11 build advertised
"100% Real Luck Enhancement · No Emulation · No Fake Data". That was not
true, and the code did not work. This version says exactly what it does
and does not do, and every feature in it is either genuinely functional or
clearly labelled as a model.

---

## Quick start

### Option 1 — single file (no GitHub needed)

```
dist/BLOX_FRUITS_SUITE_v12.lua
```

Paste the whole file into your executor and run it. Nothing is downloaded
at runtime.

### Option 2 — from source

1. Copy the `v12` folder into a Roblox Studio place, or
2. Put the files in a GitHub repository and run `loader.lua` in your
   executor (it downloads from
   `https://raw.githubusercontent.com/<you>/<repo>/main/v12` by default).

### Controls

| Key | Action |
| --- | --- |
| `RightShift` | Show / hide the interface |
| `End` | Minimise the interface |

Both are rebindable from the Settings tab.

---

## What actually works

These are real, and they read the live game:

| Feature | How it works |
| --- | --- |
| **Fruit ESP** | Scans the workspace, identifies fruit models, draws a billboard with the name, rarity and distance. Tinted with a `Highlight` instance. |
| **Mob / boss / chest / NPC ESP** | Same scanner, different buckets. Mob levels are read from attributes, child values or the display name. |
| **Auto farm** | Picks the closest mob that matches the level filter, walks to it and attacks. Safe mode stops at a health threshold. |
| **Auto collect** | Walks to the closest spawned fruit and triggers the pickup (proximity prompt, `E`, or standing on it). |
| **Auto quest** | Goes to the nearest quest giver, reads the quest target out of the HUD, defeats it and returns. |
| **Fast travel** | Teleports to any NPC in the world by name. |
| **Gacha tracking** | Listens to the game's own remote events and logs the fruit that actually came out. |
| **Spawn tracking** | Notices every fruit that spawns in the world and records it with a timestamp. |
| **Live statistics** | Level, Beli, Bounty, equipped fruit, plus a measured luck rating computed from the real results. |
| **Settings persistence** | Writes `bfs_settings.json` through the executor's file API. Falls back to memory when there is no file API. |
| **Clean unload** | One call restores the environment: connections disconnected, instances destroyed, `math.random` put back. |

## What it does not do

Being straight about this matters more than the feature list:

* **It cannot change the server's drop rates.** Blox Fruits resolves fruit
  rolls on the server. The server picks the fruit and sends the client the
  outcome. No client-side script can change that, whatever it claims.
* **It cannot guarantee a mythical fruit.** For the same reason.
* **It does not disable the anti-cheat.** The v11 build hooked
  `__namecall` to swallow `ReportAbuse` and spoofed `game.GameId`. Those
  hooks broke the script (see the changelog) and are not attempted here.
  The suite does nothing that actively fights the game's own systems.
* **The "roll" button is a simulator.** It rolls the community-estimated
  tables so you can see what a table looks like. It does not touch the
  game.

## The optional client-side roll hook

`Luck → Client-side roll hook` biases numbers that the *client* rolls
locally (animations, local shuffles). It is off by default and the
interface labels it as cosmetic.

The v11 version of this hook was broken twice over:

1. it called `OriginalRandom(min, max)` even when `math.random()` was
   called with no arguments, which raised
   `bad argument #2 to 'random' (number expected, got nil)` and killed the
   script;
2. it ran `debug.traceback()` on *every* random call to guess whether it
   was a fruit roll. Roblox calls `math.random` thousands of times per
   second, so this was a constant and significant frame cost — and the
   keyword list matched `"random"` and `"item"`, so it flagged nearly
   every call in the game.

The v12 hook reproduces all three calling conventions of `math.random`,
identifies the call site with `debug.getinfo` and caches the answer per
function.

---

## Architecture

```
BLOX_FRUITS_SUITE_v12/
├── loader.lua              executor bootstrap
├── src/main.lua            entry point (Studio require + executor HttpGet)
├── core/                   the services every module shares
│   ├── init.lua            suite root, module lifecycle
│   ├── events.lua          event bus
│   ├── state.lua           reactive store, dotted paths
│   ├── settings.lua        schema, defaults, persistence
│   ├── scheduler.lua       one Heartbeat drives every task
│   ├── hotkeys.lua         rebindable key registry
│   ├── cleanup.lua         teardown registry
│   ├── logger.lua          levelled logging
│   ├── json.lua            dependency-free JSON codec
│   └── util.lua            helpers
├── data/                   reference data
│   ├── fruits.lua          42 fruits, 5 tiers, aliases
│   ├── mobs.lua            72 mobs and 27 bosses with levels
│   ├── islands.lua         35 islands with level brackets
│   ├── npcs.lua            NPC catalogue
│   └── chests.lua          chest tiers
├── luck/                   the luck layer
│   ├── rng.lua             portable PRNG
│   ├── rarity.lua          tiers, weights, luck application
│   ├── luck_math.lua       z-score based luck rating
│   ├── drop_table.lua      weighted table with pity
│   ├── roll_engine.lua     the engine
│   ├── spawn_tracker.lua   observes real world spawns
│   ├── gacha_tracker.lua   observes real gacha results
│   ├── client_roll.lua     the optional (cosmetic) hook
│   └── init.lua            facade
├── world/                  the world layer
│   ├── scanner.lua         one pass over the workspace
│   ├── entity.lua          classification and level extraction
│   ├── esp.lua             the overlay
│   ├── movement.lua        character and CFrame helpers
│   ├── input.lua           click abstraction per executor
│   ├── player_stats.lua    reads the HUD values
│   ├── auto_farm.lua       farming loop
│   ├── auto_collect.lua    fruit pickup loop
│   ├── auto_quest.lua      quest runner
│   ├── fast_travel.lua     teleport by NPC
│   └── init.lua            facade
├── ui/                     the interface
│   ├── init.lua            window, tabs, pages
│   ├── theme.lua           5 themes, 8 accents
│   ├── container.lua       shared widget API
│   ├── widgets/            toggle, slider, dropdown, button,
│   │                       input, section, label, stat, table, notify
│   └── tabs/               dashboard, luck, world, farm,
│                           stats, settings, about
└── tools/                  build and test tooling
    ├── build.py            single file bundler + zip
    ├── validate.js         syntax check (luaparse)
    ├── smoke.js            runtime test (fengari)
    └── roblox_stub.lua     the Roblox API stand-in
```

### The fruit data

42 fruits, five tiers, verified against the live game:

| Tier | Count | Fruits |
| --- | --- | --- |
| Common | 7 | Rocket, Spin, Blade, Spring, Bomb, Smoke, Spike |
| Uncommon | 6 | Flame, Ice, Sand, Dark, Eagle, Diamond |
| Rare | 4 | Light, Rubber, Ghost, Magma |
| Legendary | 11 | Quake, Buddha, Love, Creation, Spider, Sound, Phoenix, Portal, Lightning, Pain, Blizzard |
| Mythic | 14 | Gravity, Mammoth, T-Rex, Dough, Shadow, Venom, Tiger, Yeti, Gas, Spirit, Magnet, Kitsune, Control, Dragon |

Aliases are handled: `Chop → Blade`, `Revive → Ghost`, `Leopard → Tiger`.

The weights in `luck/rarity.lua` are **community estimates** — the
developers have never published the exact drop rates. They are plain
configuration; edit them and the whole engine follows.

---

## Build and test

```bash
# syntax check every file
npm install luaparse
node tools/validate.js

# runtime test of the pure logic and the whole interface
npm install fengari
node tools/smoke.js

# build the single file bundle and the archive
python3 tools/build.py
```

`tools/smoke.js` runs the suite inside a real Lua 5.3 VM with a stand-in
for the Roblox API (`tools/roblox_stub.lua`). It covers the JSON codec,
the PRNG, the rarity maths, the drop table, the roll engine, the fruit
database, the state store, the event bus, the settings layer, the cleanup
registry, the scheduler, the client roll hook — and then it builds the
real suite, the real window and all seven tabs, refreshes the interface
and tears everything down again.

Current state: **111 checks, 0 failures.**

---

## Portability notes

The code avoids anything that only exists in one of the three Lua
dialects it has to run on:

* `math.clamp` is a Luau extension — the suite uses explicit comparisons.
* The PRNG uses no bitwise operators. Lua 5.3 has 64-bit integers, Luau
  has only doubles, and some Lua hosts cap integers at 32 bits. The
  generator is built from multiplication, addition and modulo only, with
  every intermediate value below 2^48 so it is exact in a double and
  produces the same stream everywhere.
* `debug.traceback()` is never called in a hot path.

---

## Requirements

* Roblox client (the suite is client-side).
* An executor that provides at least: `getgenv`, `game`, `loadstring`.
* For the automation loops: an executor that can send input events
  (`keypress`, `VirtualInputManager` or a tool fallback). The interface
  shows which mechanism was detected on the Farm tab.
* For settings persistence: `writefile` / `readfile`. Without them the
  settings live in memory for the session and the Settings tab says so.

## Fair use

Use this on your own account and on servers where you are allowed to
use scripts. Automating a game is against the Blox Fruits terms of
service, and bans are the developer's decision to make. Nothing in this
suite is designed to make detection harder — the goal is a cleaner
tool, not a stealthier one.

# Changelog

## v12.0.0 — full rewrite

The v11 build was 7 files and roughly 1,900 lines. It looked complete and
did not work. v12 is 57 files and roughly 10,000 lines, and every part of
it is either functional or labelled as a model.

### Bugs fixed from v11

| # | Problem | Fix |
| --- | --- | --- |
| 1 | `math.random` was hooked with `OriginalRandom(min, max)`, but Roblox calls `math.random()` with no arguments. The hook raised `bad argument #2 to 'random'` and took the whole script down. | The hook reproduces all three calling conventions of `math.random`. |
| 2 | `IsFruitRoll()` called `debug.traceback()` on **every** random call. Roblox calls `math.random` thousands of times per second. | The call site is identified with `debug.getinfo` and cached per function. |
| 3 | The traceback keyword list included `"random"` and `"item"`, so almost every call in the game was flagged as a fruit roll. | The list is now `fruit, gacha, luck, drop, roll`. |
| 4 | `main.lua` read `luckStats.active` while `real_luck.lua` returned `Active`. The statistics tab always showed zeros. | Every stats table uses lower camel case, and `GetStats` has a comment saying so. |
| 5 | `real_protection.lua` hooked `__namecall` to swallow `ReportAbuse` and returned a spoofed client id. | Removed. The suite does not interfere with the game's own reporting. |
| 6 | At protection level 7+ the v11 build replaced `print` with a no-op, killing the executor's logging and the script's own output. | The logger writes to `print` only when a level is enabled, and never replaces it. |
| 7 | `RealProtection.Deactivate()` did not restore the `__namecall` hook, so the script stayed hooked for the rest of the session. | Every override registers a matching restore in `core/cleanup.lua`, and `suite:Stop()` runs them all. |
| 8 | `real_luck.lua` used hard-coded memory addresses (`0x01A2B4C8`) and called `readmem` / `writemem`, which do not exist in Luau. | Removed. The suite reads the live world instead of guessing at addresses. |
| 9 | `config/settings.json` was never read by any code. The toggles changed nothing. | The schema in `core/settings.lua` drives the interface, the defaults and the file. |
| 10 | `ui/professional_ui.lua` and the single-file build had two different APIs (`UI:Initialize()` vs `UI.New()`), so the two editions of the same script were not interchangeable. | One implementation. The build produces the single file from the same sources. |
| 11 | `main.lua` downloaded its modules from a GitHub repository that had to be kept in sync by hand, with no error handling if a download failed. | The loader reports the failure, and the single file build needs no network at all. |
| 12 | `EnhancedRandom` used a `threshold` computed from `max - min + 1` but compared it against `result`, which is a value in `[min, max]`, not an index. | Replaced with a weighted, rarity-aware implementation. |

### Added

* **Architecture** — `core/` (events, state, settings, scheduler, hotkeys,
  cleanup, logger, JSON, util), `data/` (fruits, mobs, islands, NPCs,
  chests), `luck/`, `world/`, `ui/`.
* **Real features** — fruit / mob / boss / chest / NPC ESP, auto farm,
  auto collect, auto quest, fast travel, live player statistics.
* **Real measurement** — the spawn tracker and the gacha tracker watch
  the game and record what actually happened, and the luck rating is a
  z-score computed from those real results.
* **Interface** — 5 themes, 8 accents, 10 widget types, 7 pages, toasts,
  drag, minimise, live refresh, rebindable keys, persistent settings.
* **Tooling** — a bundler (`tools/build.py`), a syntax checker
  (`tools/validate.js`) and a runtime test suite (`tools/smoke.js`) with
  a Roblox API stand-in (`tools/roblox_stub.lua`).

### Deliberately not carried over

The v11 "protection" module that hooked `__namecall` to block
`ReportAbuse` / `GetClientId` / `GetHardwareId` and spoofed `game.GameId`
was not ported. It did not work, it broke the script it was supposed to
protect, and the suite is more useful as a clean tool than as a stealth
one. What remains is ordinary hygiene: the ScreenGui is given a random
name, every instance and connection is tracked, and unloading the suite
leaves no trace behind.

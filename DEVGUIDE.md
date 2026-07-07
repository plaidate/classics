# Classics — developer guide

Ten small games, two *Code the Classics* volumes, one shared core. Each
game is an original Lua reimplementation of a book design (no upstream
code or assets reused as code; the artwork and audio are the books' own,
converted for the Playdate's 1-bit display). This guide covers the shared
layer, the build system, the per-game conventions every game follows, and
how to add an eleventh.

See [MANUAL.md](MANUAL.md) for the player-facing rules of every game, and
[MIGRATION.md](MIGRATION.md) for the checklist used to port a standalone
project into this repo.

## Layout

```
core/            shared modules staged into every build
  lib.lua        one import that pulls in CoreLibs/graphics + the two below
  cutil.lua      Util: clamp + the Util.after / Util.runPending scheduler
  harness.lua    Harness: the smoke-test harness (free when disabled)
games/<name>/    each game's modules + its images/ sounds/ music/ pdxinfo
tools/smoke.sh   build a smoke variant, run it headless, report telemetry
Makefile         stages core + one game into build/<name>/source, runs pdc
dist/            committed ready-to-play release .pdx (one per game)
```

`games/boing/` is the reference migration — the smallest, cleanest game;
read it first.

## The shared core

Everything is a global table (the repo convention — `import` runs each
file once into the shared global namespace, so `Util`, `Harness`, and each
game's `C`, `G`, `Draw`, `Input`, `Sfx`, … are just globals). This is
deliberate; keep it. Lua 5.4, `import` (not `require`).

### `lib.lua`

One line per game: `import "lib"`. It pulls in `CoreLibs/graphics` and then
`cutil` and `harness`. A game that needs more CoreLibs (e.g.
`CoreLibs/crank`) imports those itself.

### `cutil.lua` — `Util`

- `Util.clamp(v, lo, hi)` — the one helper every game uses.
- `Util.after(delay, fn)` / `Util.runPending(dt)` — a tiny delayed-call
  scheduler. **`runPending` requires the `dt` argument**; call it once a
  frame with the game's `C.DT` (typically `1/30`). Games that don't use
  `Util.after` still call `runPending(C.DT)` harmlessly.

A game may add its own helpers by opening the table with
`Util = Util or {}` in its local `util.lua` (see `avenger/util.lua`,
`soccer/util.lua`) — never `Util = {}`, which would clobber the core's
`clamp`.

### `harness.lua` — `Harness`

The smoke-test harness, folded permanently into every game because it
costs nothing when disabled. The Makefile stages a generated
`smokeflag.lua` into each build: `SMOKE_BUILD = false` for a release,
`true` for a `-smoke` build (plus a `SMOKE_SHOT_PATH` for screenshots).

- `Harness.enabled` — `SMOKE_BUILD`. Games gate their **autopilot** on this
  (`if Harness.enabled then …` inside `Input.gather`), so a smoke build
  plays itself.
- `Harness.count(key, n)` / `Harness.set(key, val)` — telemetry counters;
  no-ops when disabled.
- `Harness.frame(frame, updateFn)` — wraps the real per-frame tick. When
  enabled it `pcall`s the tick (writing any error to the `err` datastore),
  writes a counter heartbeat to the `smoke` datastore every 90 frames, and
  dumps a screenshot to `SMOKE_SHOT_PATH` every 300 frames. When disabled it
  just calls `updateFn()`.
- `Harness.extra = function(t) … end` — optional hook a game sets to add
  fields (state, score, lives…) to each heartbeat.

## The per-game shape

Every game follows the same skeleton (`boing` is the minimal version):

- **`config.lua`** — `C = { … }`: all tunables and screen constants
  (`SCREEN_W/H = 400/240`, `DT = 1/30`). Smoke-only tuning lives here as
  `KEY = SMOKE_BUILD and X or Y` (e.g. eggzy's longer clock).
- **`gamestate.lua`** — `G = { … }`: all mutable state plus small helpers
  (`G.reset`, `G.saveHigh`). `G.state` is the string state machine
  (`"title" | "play" | "over"/"gameover"` and per-game variants);
  `G.frame` is the monotonic frame counter.
- **`input.lua`** — `Input.gather()` returns the frame's control values;
  the **autopilot** branch (`if Harness.enabled`) synthesises them instead
  of reading hardware.
- **`draw.lua`** — `Draw`: all rendering and menu screens.
- Game logic modules (`game`, `player`, `enemies`, `ball`, `ai`, …).
- **`sfx.lua`** — `Sfx`: sampled/synth sounds and streamed music.
- **`assets.lua`** (larger games) — loads and caches every image once at
  startup.
- **`main.lua`** — imports (`lib` first, then the game's modules in
  dependency order), a `local function tick()` holding the real
  per-frame body, then:

  ```lua
  function playdate.update()
      Harness.frame(G.frame + 1, tick)
  end
  Harness.extra = function(t) t.state = G.state; … end
  playdate.getSystemMenu():addMenuItem("restart", function() … end)
  math.randomseed(playdate.getSecondsSinceEpoch())
  playdate.display.setRefreshRate(30)
  ```

Conventions shared across games: 30 fps; a `title → play → over` state
machine driven from `tick`; A confirms/serves and both A/B often start;
a 1-second lockout on the game-over screen before input dismisses it; high
scores/records persisted with `playdate.datastore` and keyed per game; the
world runs at half the original arcade pixel scale to fit 400×240.

## Building

Requires the Playdate SDK with `pdc` on `PATH`.

- `make <game>` → `out/<Title>.pdx` (release: `SMOKE_BUILD=false`).
- `make <game>-smoke` → `out/<Title>Smoke.pdx` (autopilot + telemetry).
- `make all` — every game, release builds.
- `make clean` — wipe `build/` and `out/`.

Each rule stages `core/*.lua` + `games/<game>/*` into
`build/<game>/source` (pdc wants a single source root), strips
`README.md`/`screenshot.png`/`*.py`, copies `LICENSE` + `LICENSE-ASSETS`
in so every pdx carries the notice, writes `smokeflag.lua`, and runs pdc.
`<Title>` is the game name title-cased (`leadingedge` → `Leadingedge.pdx`).

## Smoke testing

`tools/smoke.sh <game> [seconds] [until-grep]` builds the smoke variant,
runs it headless in the Simulator, polls the `smoke`/`err` datastores, and
prints the last heartbeat plus any error and the latest screenshot path.
Example: `tools/smoke.sh cavern 180 '"gameovers":[1-9]'` runs cavern until
it has recorded at least one game-over. The Simulator is single-instance,
so run smoke tests serially.

## Adding a game

1. Create `games/<name>/` with the module shape above; start from
   `games/boing/` and grow it.
2. `pdxinfo`: `bundleID=com.sdwfrost.classics.<name>`, a `name=`
   (display name), author, description, `version`, `buildNumber`.
3. `import "lib"` first in `main.lua`; add any extra CoreLibs the game
   needs.
4. If your `util.lua` only duplicates clamp/after/runPending, delete it
   and rely on the core; otherwise open it with `Util = Util or {}` and
   drop the duplicated trio. Pass `C.DT` to every `Util.runPending` call.
5. Fold the harness in: gate the autopilot on `Harness.enabled`, sprinkle
   `Harness.count(...)` at meaningful events, wrap the tick in
   `Harness.frame`, and set `Harness.extra`. Screenshots need no per-game
   code.
6. Add `<name>` to the `GAMES` list in the Makefile.
7. `make <name> && make <name>-smoke` to verify it compiles and self-plays.
8. Add a row to the README table, a per-game `README.md` + `screenshot.png`,
   and a section in `MANUAL.md`.

## The games at a glance

- **Boing** (Vol 1) — Pong-style table tennis; crank bat, 1P vs a wobbling
  AI or 2P on one device; deflection set by where the ball meets the bat;
  first to 10. The reference migration.
- **Cavern** (Vol 1) — single-screen, vertically-wrapping platformer; blow
  orbs to trap patrolling robots, pop them into fruit; 4 rotating layouts,
  aggressive robots drop hearts/lives.
- **Bunner** (Vol 1) — endless Frogger-style road/river crosser; one life,
  a scrolling camera that ramps, an eagle that punishes dawdling, crank or
  d-pad to hop.
- **Myriapod** (Vol 1) — Centipede-style fixed-screen shooter; split the
  segmented myriapod (each kill hardens into a rock) while a bee, fly, and
  spider harass the rock field; d-pad flight + crank fine-aim.
- **Soccer** (Vol 1, "Sunday Soccer") — top-down 7-a-side football on a
  scrolling pitch; open goals, control follows your passes, EASY/HARD AI,
  persistent W/D/L record.
- **Kinetix** (Vol 2) — Arkanoid-style brick breaker; crank bat, nine
  capsule power-ups (some traps), armored/metal bricks, 6 looping layouts,
  ride the bat through the exit portal.
- **Avenger** (Vol 2) — Defender-style shooter over a wrapping landscape;
  rescue falling colonists before landers haul them to the sky and mutate;
  escalating waves of landers, pods, baiters, mutants, swarmers.
- **Eggzy** (Vol 2) — ladder-climbing gem-grab platformer against a clock;
  collect every gem then escape through the door before time runs out.
- **Leading Edge** (Vol 2) — pseudo-3D night circuit racer; crank steers,
  A accelerates, B brakes; out-drive the rival field over five laps.
- **Beat Streets** (Vol 2) — side-scrolling brawler; punch/kick/jump-kick
  combos, knockdowns, barrels and health pickups; two stages of five waves
  each ending in a heavy boss.

## Licensing note for contributors

This is a **derivative work** of *Code the Classics* (Raspberry Pi Press),
under the same BSD terms. Do **not** alter `LICENSE`, `LICENSE-ASSETS`, or
the upstream copyright/attribution anywhere — the Makefile stages both
license files into every pdx so binary redistribution carries the notice,
as the license requires. Volume 2 content credits: games by Andrew Gillett
with Eben Upton and Sean M. Tracey, graphics by Dan Malone, audio by
Allister Brimble.

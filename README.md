# Classics

Both volumes of Code the Classics, ported to the
[Playdate](https://play.date) as original Lua implementations sharing one
core library — game logic written from scratch, driving the books'
artwork and audio, converted for the 1-bit display.

Each game links to its own page with controls, rules, and a screenshot.

| Game | Style | Volume |
|---|---|---|
| [Boing](games/boing/) | table tennis (crank bat, 2P on one device) | 1 |
| [Cavern](games/cavern/) | trap-and-pop platformer | 1 |
| [Bunner](games/bunner/) | endless road/river crosser | 1 |
| [Myriapod](games/myriapod/) | garden chain shooter | 1 |
| [Soccer](games/soccer/) | 7-a-side top-down football | 1 |
| [Kinetix](games/kinetix/) | brick breaker (crank bat) | 2 |
| [Avenger](games/avenger/) | colonist-defense shooter | 2 |
| [Eggzy](games/eggzy/) | gem-grab platformer on a clock | 2 |
| [Leading Edge](games/leadingedge/) | pseudo-3D circuit racer (crank wheel) | 2 |
| [Beat Streets](games/beatstreets/) | street brawler | 2 |

## Playing (no build needed)

Ready-to-run copies of every game live in [`dist/`](dist/).

- **On a Playdate**: sign in at [play.date/account/sideload](https://play.date/account/sideload),
  upload the `.pdx` you want (zip it first if your browser requires a
  single file), then download it to the device from Settings → Games.
- **In the Playdate Simulator** (ships with the
  [Playdate SDK](https://play.date/dev/)): open the `.pdx` directly, or
  drag it onto the Simulator window.

High scores and records save per game on the device.

## Development

Requires the Playdate SDK with `pdc` on your PATH.

- `make <game>` — build one game to `out/<Title>.pdx`
- `make all` — build everything
- `make <game>-smoke` — instrumented build: the game plays itself
  (autopilot) and writes telemetry counters, errors, and periodic
  screenshots through the built-in harness
- `tools/smoke.sh <game> [seconds] [until-grep]` — build the smoke
  variant, run it headlessly in the Simulator, and report

### Layout

- `core/` — the shared modules: `cutil.lua` (clamp + scheduler) and
  `harness.lua` (the smoke-test harness; a staged `smokeflag.lua`
  switches it on per build).
- `games/<name>/` — each game's modules plus its converted
  images/sounds/music; `games/boing/` is the reference migration.
- The Makefile stages `core/` + the game into `build/<name>/source` and
  runs `pdc`; `dist/` holds committed release builds.

## Licensing

The Code the Classics content (including the artwork and audio,
converted here for the Playdate's 1-bit display) is copyright 2019
Eben Upton and licensed under BSD terms. Volume 2 content credits:
games by Andrew Gillett with Eben Upton and Sean M. Tracey, graphics by
Dan Malone, audio by Allister Brimble.

The Lua implementations are a derivative work of
[Code the Classics](https://github.com/raspberrypipress), reimplemented
for the Playdate, and are licensed under the same BSD terms (3-clause:
the upstream notice's body includes the no-endorsement clause despite
its header's 2-clause label). [LICENSE](LICENSE) covers the whole work
and retains the upstream copyright notice per its terms;
[LICENSE-ASSETS](LICENSE-ASSETS) preserves the upstream notice file
verbatim. The Makefile stages both files into every built pdx so binary
redistribution carries the notice, as the license requires.

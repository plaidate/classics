# Migrating a game into the classics repo

Each game moves from its standalone project `~/Projects/playdate/<game>/`
into `games/<game>/` here, onto the shared core. **games/boing/ is the
finished exemplar — diff it against ../boing/source to see every change.**
Do not modify core/, the Makefile, tools/, or other games' directories.

## Steps

1. `cp -r ../<game>/source games/<game>` (assets — images/sounds/music —
   come along; keep them). Do NOT copy the old `smoke-test/` directory.
2. **pdxinfo**: change bundleID to `com.sdwfrost.classics.<game>`.
3. **Imports**: replace `import "CoreLibs/graphics"` with `import "lib"`
   (core provides CoreLibs/graphics, Util, Harness). Keep any other
   CoreLibs imports the game uses (e.g. CoreLibs/crank).
4. **util.lua dedup**: if the game's util.lua ONLY has clamp/after/
   runPending, delete the file and its import. If it has extra helpers,
   keep it but change `Util = {}` to `Util = Util or {}` and delete the
   duplicated trio. Either way: core's `Util.runPending(dt)` REQUIRES the
   dt argument — fix every `Util.runPending()` call site to pass the
   game's DT constant.
5. **Fold the smoke instrumentation into the source permanently** (it is
   free when disabled). The old `../<game>/smoke-test/patch.py` documents
   every site:
   - Delete the `AUTOPILOT = ...` flag from config; change every
     `if AUTOPILOT` to `if Harness.enabled`.
   - Each patch.py counter hunk becomes a permanent
     `Harness.count("name")` at the same spot in the real source.
   - The pcall/heartbeat wrapper becomes: rename the playdate.update body
     to `local function tick()` and add
     `function playdate.update() Harness.frame(G.frame + 1, tick) end`
     (use the game's frame counter), plus
     `Harness.extra = function(t) t.state = ... end` with the same fields
     the old heartbeat wrote, and
     `Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/<game>-shot.png"`.
   - Smoke-only tuning that lived in patches (e.g. soccer's short halves,
     eggzy's long clock) becomes `KEY = SMOKE_BUILD and X or Y` in config
     with a brief comment.
   - Ignore any screenshot/writeToFile lines in old smoke sources —
     Harness.shotPath replaces them.
6. **Build**: `cd /Users/sdwfrost/Projects/playdate/classics && make
   <game> && make <game>-smoke`. If the sandbox denies make/pdc, write
   everything and report "pdc denied" — the parent compiles. NEVER launch
   the Playdate Simulator.

## Game-specific notes

- **soccer**: old bundleID was com.sdwfrost.sundaysoccer — it becomes
  com.sdwfrost.classics.soccer like the rest.
- **eggzy**: the smoke clock extension (LEVEL_TIME 120) is a
  `SMOKE_BUILD and 120 or 30`.
- **beatstreets**: keep the zero-distance strike fix and telemetry fields
  (e1/px/camX) from its smoke main in mind — fold the telemetry into
  Harness.extra only if it was in patch.py; otherwise skip it.
- Games whose patch.py edited multiple modules: translate every hunk.

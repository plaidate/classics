-- Leading Edge for Playdate
-- An original pseudo-3D night racer in the spirit of the Code the
-- Classics Vol 2 game: out-drive nineteen rivals over five laps.
-- Crank steers, A accelerates, B brakes.
--
-- Module layout (globals shared across imports):
--   config.lua    C: tunables and flags
--   util.lua      Util: small numeric helpers
--   assets.lua    Img: image loading and the scaled-sprite cache
--   sfx.lua       Sfx: sample banks, engine/skid loops, music
--   gamestate.lua G: app state + persisted best times
--   track.lua     Track: the circuit as per-piece offset arrays
--   cars.lua      Cars: rival AI and player handling/laps/collisions
--   race.lua      Race: the field, camera, countdown, race order
--   input.lua     Input: crank/d-pad controls and the autopilot
--   draw.lua      Draw: road renderer, bitmap text, HUD, menus

import "lib"

import "config"
import "util"
import "assets"
import "sfx"
import "gamestate"
import "track"
import "cars"
import "race"
import "input"
import "draw"

Main = {}

local function startDemo()
    G.race = Race.new(false)
    G.demoT = 0
    G.state = "title"
end

local function startRace()
    G.race = Race.new(true)
    Harness.count("races")
    G.newLapRecord, G.newRaceRecord = false, false
    G.state = "play"
end

local function backToTitle()
    Sfx.engineStop()
    Sfx.skid(0)
    startDemo()
    Sfx.music("title_theme")
end

local function tick()
    G.frame = G.frame + 1
    local steer, accel, brake, start = Input.gather()
    G.input.steer, G.input.accel, G.input.brake = steer, accel, brake

    if G.state == "title" then
        G.demoT = G.demoT + C.DT
        Race.update(G.race, C.DT)
        Draw.scene(G.race)
        Draw.title()
        if start then
            startRace()
        elseif G.demoT >= C.DEMO_RESET then
            -- the demo race must restart before the AI runs out of road
            startDemo()
        end
    elseif G.state == "play" then
        Race.update(G.race, C.DT)
        Draw.scene(G.race)
        Draw.hud(G.race)
        if G.race.raceComplete then
            G.state = "gameover"
            G.stateT = 0
        end
    elseif G.state == "gameover" then
        G.stateT = G.stateT + C.DT
        Race.update(G.race, C.DT) -- the pack cruises behind the flag
        Draw.scene(G.race)
        Draw.hud(G.race)
        if start and G.stateT > 1 then
            backToTitle()
        end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/leadingedge-shot.png"
Harness.extra = function(t)
    local R = G.race
    local p = R and R.player
    t.state = G.state
    t.speed = p and p.speed or 0
    t.position = p and Util.indexOf(R.cars, p) or 0
end

playdate.getSystemMenu():addMenuItem("restart", backToTitle)

-- startup
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
Img.preload()
Track.build()
startDemo()
Sfx.music("title_theme")

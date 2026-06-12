-- Myriapod PD: a Centipede-style fixed-screen shooter for Playdate
-- An original implementation of the "Myriapod" game design from
-- Code the Classics Vol 1. D-pad flies the ship in the lower zone;
-- hold A or B for autofire; the crank gives a fine sideways nudge.
--
-- Module layout (globals shared across imports):
--   config.lua    C: tunables and flags
--   sfx.lua       Sfx: sampled sound effects (synth fallback) + music
--   sprites.lua   Sprites: real artwork loaded at startup
--   gamestate.lua G: all mutable game state + helpers
--   grid.lua      Grid: the rock field and cell math
--   myriapod.lua  Myriapod: segment marching, splitting, waves
--   player.lua    Player: ship movement, bullets, lives
--   flyers.lua    Flyers: the bee, fly, and spider pests
--   input.lua     Input: d-pad/crank controls and the smoke-test autopilot
--   draw.lua      Draw: rendering and menu screens

import "lib"

import "config"
import "sfx"
import "sprites"
import "gamestate"
import "grid"
import "myriapod"
import "player"
import "flyers"
import "input"
import "draw"

Main = {}

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.wave = 0
    G.nextLife = C.EXTRA_LIFE_AT
    G.rocks, G.segs = {}, {}
    G.particles, G.popups, G.explosions = {}, {}, {}
    Flyers.reset()
    Player.reset()
    G.state = "play"
end

local function updatePlay()
    local dx, dy, fire, _, nudge = Input.gather()
    Player.update(dx, dy, fire, nudge)
    Player.updateBullets()
    Myriapod.update()
    Flyers.update()
    G.updateFx()

    if #G.segs == 0 then
        -- between waves: grow the rock field back, then send the next myriapod
        if Grid.count() < C.BASE_ROCKS + G.wave then
            Grid.addRandomRock()
        else
            Myriapod.spawnWave()
        end
    end

    if G.lives <= 0 and not G.player.alive and G.player.respawnT <= 0 then
        G.state = "gameover"
        G.stateT = 0
        G.saveHigh()
        Sfx.gameover()
        Harness.count("gameovers")
    end
end

local function tick()
    G.frame = G.frame + 1
    Util.runPending(C.DT)

    if G.state == "title" then
        Draw.title()
        local _, _, _, start = Input.gather()
        if start then startGame() end
    elseif G.state == "play" then
        updatePlay()
        Draw.play()
    else -- gameover
        G.stateT = G.stateT + C.DT
        Draw.gameover()
        local _, _, _, start = Input.gather()
        if start and G.stateT > 1 then startGame() end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/myriapod-shot.png"
Harness.extra = function(t)
    t.state = G.state
    t.score = G.score
    t.lives = G.lives
    t.wave = G.wave
end

playdate.getSystemMenu():addMenuItem("restart", function()
    G.state = "title"
end)

-- startup
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
Sprites.build()

-- Infinite Bunner-style endless road-crosser for Playdate
-- An original implementation inspired by the Code the Classics design.
-- D-pad hops one cell; cranking forward also hops ahead. The screen scrolls
-- forever - dawdle off the bottom and the eagle collects you.
--
-- Module layout (globals shared across imports):
--   config.lua    C: tunables and flags
--   util.lua      Util: clamp, pick, delayed-call scheduler
--   sfx.lua       Sfx: sampled sound effects and the looping theme
--   sprites.lua   Sprites: 1-bit art converted from the original assets
--   gamestate.lua G: all mutable game state + helpers
--   rows.lua      Rows: band generation, cars/logs/trains, collisions
--   player.lua    Player: hop movement, log riding, dying
--   input.lua     Input: d-pad/crank controls and the smoke-test autopilot
--   draw.lua      Draw: rendering and menu screens

import "lib"

import "config"
import "util"
import "sfx"
import "sprites"
import "gamestate"
import "rows"
import "player"
import "input"
import "draw"

Main = {}

local function startGame()
    G.reset()
    Rows.reset()
    Player.spawn()
    G.stateT = 0
    G.state = "play"
    Sfx.start()
    Harness.count("games")
end

function Main.gameOver()
    G.saveHigh()
    G.stateT = 0
    G.state = "gameover"
end

local function updatePlay()
    local dir = Input.gather()
    if dir then Player.queueHop(dir) end

    local p = G.player
    if p.state == "alive" then
        -- scroll harder the further up the screen the rabbit sits
        local lag = G.camY + C.SCREEN_H - p.y
        G.camY = G.camY - Util.clamp(lag / 60, 1, 3) * C.SCROLL_BASE * C.DT
    end

    Rows.update()
    Player.update()
    G.updateFx()
end

local function tick()
    G.frame = G.frame + 1
    Util.runPending(C.DT)

    if G.state == "title" then
        G.camY = G.camY - C.SCROLL_BASE * C.DT
        Rows.update()
        Draw.title()
        local _, start = Input.gather()
        if start then startGame() end
    elseif G.state == "play" then
        updatePlay()
        if G.state == "play" then
            Draw.play()
        else
            Draw.gameover()
        end
    elseif G.state == "gameover" then
        G.stateT = G.stateT + C.DT
        G.camY = G.camY - C.SCROLL_BASE * C.DT
        Rows.update()
        Draw.gameover()
        local _, start = Input.gather()
        if start and G.stateT > 1 then startGame() end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/bunner-shot.png"
Harness.extra = function(t)
    t.state = G.state
    t.score = G.score
end

playdate.getSystemMenu():addMenuItem("restart", function()
    G.reset()
    Rows.reset()
    G.state = "title"
    Sfx.musicVolume(1)
end)

-- startup
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
Sprites.build()
Sfx.music()
G.reset()
Rows.reset()

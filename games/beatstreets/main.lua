-- Beat Streets-style scrolling brawler for Playdate
-- An original implementation inspired by the classic streets brawlers.
-- Controls: d-pad walks the street (x plus depth), A punches (chains into
-- a three-hit combo), B kicks (B while moving: jump kick).
--
-- Module layout (globals shared across imports):
--   config.lua    C: tunables and flags
--   util.lua      Util: math helpers
--   sfx.lua       Sfx: wav sample pools + the theme loop
--   assets.lua    Assets: the curated sprite subset
--   gamestate.lua G: all mutable game state + persistence
--   fighters.lua  Fighters/Attacks: shared brawler behaviour
--   player.lua    Player: the hero
--   enemies.lua   Enemies: thug + heavy AI
--   stages.lua    Stages: waves, camera, barrels, backgrounds
--   input.lua     Input: d-pad controls and the smoke-test autopilot
--   draw.lua      Draw: depth-sorted rendering, HUD, menus

import "lib"

import "config"
import "util"
import "sfx"
import "assets"
import "gamestate"
import "fighters"
import "player"
import "enemies"
import "stages"
import "input"
import "draw"

local function startGame()
    G.score = 0
    G.player = Player.new()
    Stages.load(1)
    G.state = "stageintro"
    G.stateT = 0
    Sfx.startMusic()
end

local function updatePlay()
    Player.update(G.player)
    if G.state ~= "play" then return end
    Enemies.update()
    Stages.update()
end

local function tick()
    G.frame = G.frame + 1
    Input.gather()

    if G.state == "title" then
        Draw.title()
        if G.input.start then startGame() end
    elseif G.state == "stageintro" then
        G.stateT = G.stateT + 1
        Draw.play()
        Draw.stageBanner()
        if G.stateT > 45 then
            G.state = "play"
        end
    elseif G.state == "play" then
        updatePlay()
        if G.state == "play" then
            Draw.play()
        elseif G.state == "stageintro" then
            Draw.play()
            Draw.stageBanner()
        end
    elseif G.state == "gameover" then
        G.stateT = G.stateT + 1
        Draw.gameover()
        if G.input.start and G.stateT > 30 then startGame() end
    elseif G.state == "win" then
        G.stateT = G.stateT + 1
        Draw.win()
        if G.input.start and G.stateT > 45 then
            G.state = "title"
        end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/beatstreets-shot.png"
Harness.extra = function(t)
    t.state = G.state
    t.score = G.score
    t.health = G.player and G.player.health or -1
    t.lives = G.player and G.player.lives or -1
    t.stage = G.stage
end

playdate.getSystemMenu():addMenuItem("restart", function()
    G.state = "title"
end)

-- startup
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
Assets.build()
Sfx.build()

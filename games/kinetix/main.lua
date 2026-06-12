-- Kinetix for Playdate: an Arkanoid/Breakout-style brick breaker.
-- An original implementation in the spirit of the Code the Classics game.
-- The crank moves the bat; A serves the ball and fires the gun.
--
-- Module layout (globals shared across imports):
--   config.lua    C: tunables
--   util.lua      Util: vectors and centered blits
--   assets.lua    Assets: every image, loaded once at startup
--   sfx.lua       Sfx: sampleplayer effects and the title music
--   gamestate.lua G: all mutable game state + the high score
--   levels.lua    Levels: mirrored brick layouts
--   bricks.lua    Bricks: offscreen brick layers and collision
--   bat.lua       Bat: movement, morphing, the gun, the exit
--   ball.lua      Ball: flight, bounces, speed creep, multiball
--   drops.lua     Drops: capsules, bullets, impact flashes
--   input.lua     Input: crank/d-pad and the smoke-test autopilot
--   draw.lua      Draw: rendering and menu screens

import "lib"

import "config"
import "util"
import "assets"
import "sfx"
import "gamestate"
import "levels"
import "bricks"
import "bat"
import "ball"
import "drops"
import "input"
import "draw"

Main = {}

local function resetServe()
    G.balls = { Ball.newServing() }
end

local function startLevel(n)
    G.level = n
    Harness.count("levels")
    Levels.build(n)
    Bricks.rebuildLayers()
    Bat.reset()
    resetServe()
    G.capsules, G.bullets, G.impacts = {}, {}, {}
    G.portalOpen = false
    G.portalFrame = 0
    G.portalT = 0
    Sfx.play("start_game")
end

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.state = "play"
    Sfx.stopMusic()
    startLevel(1)
end

function Main.openPortal()
    if not G.portalOpen then
        G.portalOpen = true
        Sfx.play("portal_exit")
    end
end

-- If every ball has gone half a minute without touching a brick or the
-- bat, they're trapped in a metal-brick pocket; soften the metal.
local function rescueTrappedBalls()
    if #G.balls == 0 then return end
    local limit = C.STUCK_SECS * 30
    for _, b in ipairs(G.balls) do
        if b.sinceBrick < limit or b.sinceBat < limit then return end
    end
    if Bricks.softenMetal() then
        Sfx.play("bat_small")
    end
    G.balls[1].sinceBat = 0 -- don't re-trigger every frame
end

local function updatePlay()
    local dx, fireDown, firePressed = Input.gather()
    Bat.update(dx, fireDown)

    for _, b in ipairs(G.balls) do
        Ball.update(b, firePressed)
    end

    -- balls that reach the open bottom are gone
    for i = #G.balls, 1, -1 do
        if G.balls[i].y > C.SCREEN_H + C.BALL_R then
            table.remove(G.balls, i)
        end
    end

    if #G.balls == 0 then
        G.lives = G.lives - 1
        Harness.count("ballsLost")
        Sfx.play("lose_life")
        if G.lives <= 0 then
            Sfx.play("game_over")
            G.saveHigh()
            G.state = "gameover"
            G.stateT = 0
            Harness.count("gameovers")
            return
        end
        resetServe()
        Bat.morphTo(Bat.NORMAL)
    end

    Drops.update()

    -- the exit swings open; sliding out through it ends the level
    if G.portalOpen then
        if G.portalFrame < 3 then
            G.portalT = G.portalT - 1
            if G.portalT <= 0 then
                G.portalT = C.PORTAL_FRAME_T
                G.portalFrame = G.portalFrame + 1
            end
        elseif Bat.hasLeftArena() then
            startLevel(G.level + 1)
        end
    end

    rescueTrappedBalls()
end

local function tick()
    G.frame = G.frame + 1
    Util.runPending(C.DT)

    if G.state == "title" then
        Sfx.startMusic()
        Draw.title()
        local _, _, pressed = Input.gather()
        if pressed then startGame() end
    elseif G.state == "play" then
        updatePlay()
        Draw.play()
    elseif G.state == "gameover" then
        G.stateT = G.stateT + C.DT
        Draw.play()
        Draw.gameover()
        local _, _, pressed = Input.gather()
        if pressed and G.stateT > 1 then
            G.state = "title"
        end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/kinetix-shot.png"
Harness.extra = function(t)
    t.state = G.state
    t.score = G.score
    t.lives = G.lives
    t.level = G.level
end

playdate.getSystemMenu():addMenuItem("restart", function()
    G.state = "title"
end)

-- startup
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
Assets.load()
Sfx.load()

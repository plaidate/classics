-- Eggzy: a ladders-and-gems single-screen platformer for Playdate.
-- An original implementation inspired by the "Eggzy" design from
-- Code the Classics Vol 2 (original code and level layouts).
-- Controls: d-pad run and climb, A jump. Grab every gem before the clock
-- runs out, then escape through the door.
--
-- Module layout (all globals, shared across imports):
--   config.lua    C: tunables and flags
--   util.lua      Util: clamp, sign, delayed-call scheduler
--   assets.lua    Assets: the startup image cache
--   sfx.lua       Sfx: sample players and music
--   levels.lua    Level: original layouts, grid collision, gravity
--   gamestate.lua G: all mutable game state + helpers
--   fx.lua        Fx: sprite-sequence effects
--   input.lua     Input: controls and the smoke-test autopilot
--   player.lua    Player: the hero
--   enemies.lua   Enemies: patrolling walkers and sweeping flyers
--   gems.lua      Gems: pickups and the exit door
--   draw.lua      Draw: rendering and menu screens

import "lib"

import "config"
import "util"
import "assets"
import "sfx"
import "levels"
import "gamestate"
import "fx"
import "input"
import "player"
import "enemies"
import "gems"
import "draw"

Main = {}

local function startLevel(n)
    G.level = n
    Level.load((n - 1) % #Level.LAYOUTS + 1, G.cycle())
    G.timeLeft = C.LEVEL_TIME * 30
    G.gainedT = 0
    G.introT = 45
    G.combo, G.comboT = 0, 0
    Player.resetTo(G.player)
    Draw.prepLevel()
end

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.newHigh = false
    G.player = Player.new()
    Level.newGame()
    startLevel(1)
    G.state = "play"
    Sfx.music("game")
end

function Main.gameOver()
    Harness.count("gameovers")
    G.state = "gameover"
    G.overT = 0
    G.saveHigh()
    Sfx.music(nil)
    Sfx.play("gameover")
end

-- the clock ran out: costs a life like any other death
function Main.timeUp()
    Harness.count("timeouts")
    Player.kill()
end

local function levelCleared()
    G.addScore(C.CLEAR_SCORE + C.CLEAR_TIME_SCORE * (G.timeLeft // 30))
    Sfx.play("new_wave")
    Harness.count("levelsCleared")
    startLevel(G.level + 1)
end

local function updatePlay(inp)
    G.gainedT = G.gainedT - 1
    G.introT = G.introT - 1
    G.timeLeft = G.timeLeft - 1

    Player.update(inp)
    if G.state ~= "play" then return end -- that death ended the game

    Enemies.update()
    Gems.update()

    if G.timeLeft <= 0 and not G.player.hurt then
        Main.timeUp()
    end

    if Gems.atExit() then
        levelCleared()
    end
end

local function tick()
    G.frame = G.frame + 1
    Util.runPending(C.DT)
    local inp = Input.gather()

    if G.state == "title" then
        Sfx.music("title")
        Draw.title()
        if inp.start then G.state = "controls" end
    elseif G.state == "controls" then
        Draw.controls()
        if inp.start then startGame() end
    elseif G.state == "play" then
        updatePlay(inp)
        Fx.update()
        Draw.play()
    else -- gameover
        G.overT = G.overT + 1
        Draw.gameover()
        if G.overT > 30 and inp.start then
            G.state = "title"
        end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/eggzy-shot.png"
Harness.extra = function(t)
    t.state = G.state
    t.score = G.score
    t.lives = G.lives
    t.level = G.level
    t.timeLeft = G.timeLeft
end

playdate.getSystemMenu():addMenuItem("restart", function()
    G.state = "title"
end)

-- startup
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
Assets.load()
Sfx.load()

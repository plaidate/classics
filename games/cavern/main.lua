-- Bubble Bobble-style single-screen platformer for Playdate.
-- An original implementation inspired by the "Cavern" design from
-- Code the Classics Vol 1.
-- Controls: d-pad move, A jump, B blow an orb (hold B to inflate it bigger).
--
-- Module layout (all globals, shared across imports):
--   config.lua    C: tunables and flags
--   sfx.lua       Sfx: sampled sound effects
--   sprites.lua   Sprites: 1-bit artwork loaded from images/
--   level.lua     Level: grid layouts and tile collision
--   gamestate.lua G: all mutable game state + helpers
--   input.lua     Input: controls and the smoke-test autopilot
--   player.lua    Player: the miner
--   enemies.lua   Enemies: the two robot types and their flame breath
--   orbs.lua      Orbs: orbs, bolts, fruit, pop animations
--   draw.lua      Draw: rendering and menu screens

import "lib"

import "config"
import "sfx"
import "sprites"
import "level"
import "gamestate"
import "input"
import "player"
import "enemies"
import "orbs"
import "draw"

local function startLevel(n)
    G.level = n
    G.theme = (n - 1) % 4
    Level.load((n - 1) % #Level.LAYOUTS + 1)
    G.levelFrame = -1
    G.robots, G.orbs, G.bolts = {}, {}, {}
    G.fruits, G.pops, G.flames = {}, {}, {}
    local strong = 1 + math.floor((n - 1) / 1.5)
    local total = 9 + n
    G.pending = {}
    for i = 1, total do
        G.pending[i] = (i <= strong) and 2 or 1
    end
    for i = total, 2, -1 do
        local j = math.random(i)
        G.pending[i], G.pending[j] = G.pending[j], G.pending[i]
    end
    Player.reset()
    Sfx.level()
end

local function startGame()
    G.score = 0
    G.lives = C.START_LIVES
    G.player = Player.new()
    startLevel(1)
    G.state = "play"
end

local function dropFruit()
    for _ = 1, 12 do
        local x, y = math.random(20, 380), math.random(40, 200)
        if not Level.solid(x, y) then
            Orbs.spawnFruit(x, y, 1)
            return
        end
    end
end

local function levelCleared()
    if #G.pending > 0 or #G.robots > 0 or #G.fruits > 0 or #G.pops > 0 then
        return false
    end
    for _, o in ipairs(G.orbs) do
        if o.trapped then return false end
    end
    return true
end

local function updatePlay()
    G.levelFrame = G.levelFrame + 1
    local dir, jump, blowPress, blowHeld = Input.gather()
    Player.update(dir, jump, blowPress, blowHeld)
    if G.lives < 0 then
        Harness.count("gameovers")
        G.state = "gameover"
        G.overT = 0
        G.saveHigh()
        Sfx.over()
        return
    end
    Enemies.spawnTick()
    Enemies.update()
    Enemies.updateFlames()
    Orbs.update()
    if G.levelFrame % C.FRUIT_RAIN_FRAMES == 0 and #G.pending + #G.robots > 0 then
        dropFruit()
    end
    if levelCleared() then
        Harness.count("levels")
        startLevel(G.level + 1)
    end
end

local function tick()
    G.frame = G.frame + 1
    Util.runPending(C.DT)

    if G.state == "title" then
        Draw.title()
        local _, _, _, _, start = Input.gather()
        if start then startGame() end
    elseif G.state == "play" then
        updatePlay()
        Draw.play()
    else -- gameover
        G.overT = G.overT + C.DT
        Draw.play()
        Draw.gameover()
        local _, _, _, _, start = Input.gather()
        if start and G.overT > 1 then G.state = "title" end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/cavern-shot.png"
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
Sprites.build()
Level.load(1)

local music = playdate.sound.fileplayer.new("music/theme")
if music then
    music:setVolume(0.3)
    music:play(0) -- loop forever
end

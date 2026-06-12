-- Avenger for Playdate
-- An original Defender-style shooter over a wrapping landscape, inspired by
-- the Code the Classics Vol 2 game.
-- Controls: up/down move, left/right face + thrust, A fire, B reverse facing,
-- crank trims altitude.
--
-- Module layout (all globals, shared across imports):
--   config.lua      C: tunables and flags
--   util.lua        Util: clamping and wrap-around math
--   gamestate.lua   G: all mutable game state + helpers
--   assets.lua      Assets: every image, cached at startup
--   sfx.lua         Sfx: sampled sounds and streamed music
--   input.lua       Input: controls and the smoke-test autopilot
--   humans.lua      Humans: the ground crew being fought over
--   enemies.lua     Enemies: landers, mutants, baiters, pods, swarmers
--   projectiles.lua Projectiles: player lasers and enemy bullets
--   player.lua      Player: the ship - momentum, flipping, firing, carrying
--   draw.lua        Draw: rendering, radar, HUD, and menu screens

import "lib"

import "config"
import "util"
import "gamestate"
import "assets"
import "sfx"
import "input"
import "humans"
import "enemies"
import "projectiles"
import "player"
import "draw"

-- Each wave fields six landers plus one more per wave, with pods joining
-- from wave four. Every fifth wave is baiters with a mutant escort instead,
-- and every tenth swaps the mutants for swarmers. Humans are restocked.
local function newWave()
    G.wave = G.wave + 1
    Harness.count("waves")
    local landers = 4 + G.wave
    local pods = -1 + G.wave // 2
    local baiters, mutants, swarmers = 0, 0, 0
    if G.wave % 5 == 0 then
        landers, pods = 0, 0
        baiters = G.wave
        if G.wave % 10 == 0 then
            swarmers = G.wave // 2
        else
            mutants = G.wave // 2
        end
    end
    for i = 0, landers - 1 do Enemies.spawn("lander", -i * 10) end
    for i = 0, pods - 1 do Enemies.spawn("pod", -i * 25) end
    for i = 0, baiters - 1 do Enemies.spawn("baiter", -i * 50) end
    for i = 0, mutants - 1 do Enemies.spawn("mutant", -i * 5) end
    for i = 0, swarmers - 1 do Enemies.spawn("swarmer", -i * 5) end
    Humans.spawnAll()
    Sfx.play("new_wave")
end

local function startGame()
    G.state = "play"
    G.stateT = 0
    G.score = 0
    G.wave = 0
    G.waveTimer = 0
    G.camOffX = C.SCREEN_W / 3
    G.enemies, G.lasers, G.bullets = {}, {}, {}
    Player.new()
    newWave()
    Sfx.music("ambience")
end

local function updateGame(xIn, yIn, fire, reverse, crank)
    -- the wave timer counts up while fighting; after a wave it is set
    -- negative and the next wave starts when it climbs back to zero
    G.waveTimer = G.waveTimer + 1
    if G.waveTimer == 0 then newWave() end

    -- a fresh baiter turns up periodically to discourage camping
    if G.waveTimer > 0 and G.waveTimer % C.BAITER_INTERVAL == 0
            and G.player.lives > 0 then
        Enemies.spawn("baiter")
    end

    Player.update(xIn, yIn, fire, reverse, crank)
    Projectiles.update()
    for _, e in ipairs(G.enemies) do Enemies.update(e) end
    for _, h in ipairs(G.humans) do Humans.update(h) end

    for i = #G.humans, 1, -1 do
        if G.humans[i].dead then table.remove(G.humans, i) end
    end
    for i = #G.enemies, 1, -1 do
        if G.enemies[i].state == "dead" then
            table.remove(G.enemies, i)
            G.score = G.score + C.ENEMY_SCORE
        end
    end

    -- the wave ends once the sky is clear: no enemies, nobody mid-fall,
    -- and no passenger still aboard
    if G.waveTimer > 0 and #G.enemies == 0 and not G.player.carried then
        local falling = false
        for _, h in ipairs(G.humans) do
            if h.falling then falling = true end
        end
        if not falling then
            G.waveTimer = -C.WAVE_COMPLETE_TIME
            Player.levelEnded(G.shieldRestore(), G.humansSaved())
            Sfx.play("wave_complete")
        end
    end
end

local function tick()
    G.frame = G.frame + 1
    G.stateT = G.stateT + 1

    local xIn, yIn, fire, reverse, start, crank = Input.gather()

    if G.state == "title" then
        Draw.title()
        if start then startGame() end
    elseif G.state == "play" then
        updateGame(xIn, yIn, fire, reverse, crank)
        if G.player.lives <= 0 then
            G.state = "gameover"
            Harness.count("gameovers")
            G.stateT = 0
            G.saveHigh()
        end
        Draw.play()
    else -- gameover: the battle rolls on behind the text
        updateGame(xIn, yIn, fire, reverse, crank)
        Draw.play()
        Draw.gameoverText()
        if G.stateT > 30 and start then
            G.state = "title"
            G.stateT = 0
            Sfx.music("menu_theme")
        end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/avenger-shot.png"
Harness.extra = function(t)
    t.state = G.state
    t.score = G.score
    t.lives = G.player and G.player.lives or -1
    t.wave = G.wave
end

playdate.getSystemMenu():addMenuItem("restart", function()
    G.state = "title"
    G.stateT = 0
    Sfx.setThrust(false)
    Sfx.music("menu_theme")
end)

-- startup
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
Assets.build()
Sfx.build()
Sfx.music("menu_theme")

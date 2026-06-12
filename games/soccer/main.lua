-- Sensible-style 7-a-side football for Playdate
-- An original implementation of the "Substitute Soccer" game design from
-- Code the Classics Vol 1: top-down football on a scrolling pitch, you steer
-- whoever is nearest the ball, and the goals are small but unguarded.
--
-- Module layout (globals shared across imports):
--   config.lua    C: tunables and flags
--   util.lua      Util: vector helpers (core adds clamp/after/runPending)
--   sfx.lua       Sfx: synth sound effects
--   gamestate.lua G: all mutable game state + helpers
--   pitch.lua     Pitch: field geometry and bounds
--   ai.lua        AI: positioning, chasing, marking, CPU kicks
--   players.lua   Players: formations, kickoffs, movement, switching
--   ball.lua      Ball: dribbling, kicks, possession, goals
--   input.lua     Input: controls and the smoke-test autopilot
--   draw.lua      Draw: rendering and menu screens

import "lib"

import "config"
import "util"
import "sfx"
import "gamestate"
import "pitch"
import "ai"
import "players"
import "ball"
import "input"
import "draw"

Main = {}

function Main.kickoff(team)
    Ball.reset()
    Players.toKickoff(team)
    G.charge = nil
    G.camY = Util.clamp(C.CENTER_Y - C.SCREEN_H / 2, 0, C.WORLD_H - C.SCREEN_H)
end

function Main.goalScored(team)
    if G.state ~= "play" then return end
    G.score[team] = G.score[team] + 1
    if team == 1 then
        Harness.count("goalsFor")
    else
        Harness.count("goalsAgainst")
    end
    G.kickTeam = (team == 1) and 2 or 1
    G.ball.owner = nil
    G.ball.vx, G.ball.vy = 0, 0
    G.state = "goal"
    G.stateT = 2.4
    Sfx.goal()
end

function Main.endHalf()
    Harness.count("halves")
    if G.half == 1 then
        Sfx.whistle()
        G.state = "halftime"
        G.stateT = 3
    else
        Sfx.fullTime()
        local r = G.record
        if G.score[1] > G.score[2] then
            r.w = r.w + 1
        elseif G.score[1] < G.score[2] then
            r.l = r.l + 1
        else
            r.d = r.d + 1
        end
        G.saveRecord()
        G.state = "fulltime"
        Harness.count("matches")
        G.stateT = 0
    end
end

local function startMatch()
    G.score = { 0, 0 }
    G.half = 1
    G.clock = 0
    Players.build()
    Main.kickoff(1)
    G.state = "play"
    Sfx.whistle()
end

local function updateCamera()
    local target = Util.clamp(G.ball.y - C.SCREEN_H / 2, 0, C.WORLD_H - C.SCREEN_H)
    G.camY = G.camY + (target - G.camY) * math.min(1, 8 * C.DT)
end

local function updatePlay(inp)
    if inp.switch and not G.prekick and G.ball.owner ~= G.ctl then
        Players.switchControl()
    end
    Players.update(inp)
    Ball.update(inp)
    if G.state == "play" then
        G.clock = G.clock + C.DT
        if G.clock >= C.HALF_LEN then Main.endHalf() end
    end
end

local function tick()
    G.frame = G.frame + 1
    Util.runPending(C.DT)
    local inp = Input.gather()

    if G.state == "menu" then
        if inp.menuUp or inp.menuDown then
            G.difficulty = 3 - G.difficulty
            Sfx.menu()
        end
        Draw.menu()
        if inp.start then startMatch() end
    elseif G.state == "play" then
        updatePlay(inp)
        updateCamera()
        Draw.play()
    elseif G.state == "goal" then
        G.stateT = G.stateT - C.DT
        updateCamera()
        Draw.play()
        Draw.banner("GOAL!")
        if G.stateT <= 0 then
            Main.kickoff(G.kickTeam)
            G.state = "play"
            Sfx.peep()
        end
    elseif G.state == "halftime" then
        G.stateT = G.stateT - C.DT
        Draw.play()
        Draw.banner("HALF TIME")
        if G.stateT <= 0 then
            G.half = 2
            G.clock = 0
            Main.kickoff(2)
            G.state = "play"
            Sfx.peep()
        end
    elseif G.state == "fulltime" then
        G.stateT = G.stateT + C.DT
        Draw.fulltime()
        if inp.start and G.stateT > 1 then
            G.state = "menu"
        end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/soccer-shot.png"
Harness.extra = function(t)
    t.state = G.state
    t.score = G.score[1] .. "-" .. G.score[2]
    t.clock = math.floor(G.clock)
    t.half = G.half
end

playdate.getSystemMenu():addMenuItem("quit match", function()
    G.state = "menu"
end)

-- startup: an idle kickoff scene sits behind the menu
math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)
Draw.build()
Players.build()
Ball.reset()
Players.toKickoff(1)

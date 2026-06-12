-- Boing-style table tennis for Playdate
-- An original implementation of the classic design from Code the Classics
-- Vol 1 (no code or assets reused). The crank is your bat.
--
--   config.lua    C: tunables
--   util.lua      Util: clamp + scheduler
--   sfx.lua       Sfx: sampled sounds + title music
--   gamestate.lua G: shared state
--   game.lua      Game: ball physics, bats, AI, scoring
--   input.lua     Input: crank/d-pad + smoke autopilot
--   draw.lua      Draw: rendering

import "lib"

import "config"
import "sfx"
import "gamestate"
import "game"
import "input"
import "draw"

local function tick()
    G.frame = G.frame + 1
    Util.runPending(C.DT)

    local p1dy, p2dy, confirm, up, down = Input.gather()

    if G.state == "title" then
        Sfx.musicOn()
        if up and G.menuSel ~= 1 then
            G.menuSel = 1
            Sfx.menuUp()
        end
        if down and G.menuSel ~= 2 then
            G.menuSel = 2
            Sfx.menuDown()
        end
        Draw.title()
        if confirm then
            Sfx.musicOff()
            Game.reset(G.menuSel == 2)
            G.state = "play"
        end
    elseif G.state == "play" then
        if p1dy ~= 0 then Game.moveBat(1, p1dy) end
        if not G.bats[2].isAI and p2dy ~= 0 then Game.moveBat(2, p2dy) end
        Game.update()
        if G.state == "play" then
            Draw.play()
        else
            Sfx.win()
            Draw.over()
        end
    elseif G.state == "over" then
        G.overT = G.overT + C.DT
        Draw.over()
        if confirm and G.overT > 1 then
            G.state = "title"
        end
    end
end

function playdate.update()
    Harness.frame(G.frame + 1, tick)
end

Harness.shotPath = "/Users/sdwfrost/Projects/playdate/classics/build/boing-shot.png"
Harness.extra = function(t)
    t.state = G.state
    t.p1 = G.bats and G.bats[1].score or -1
    t.p2 = G.bats and G.bats[2].score or -1
end

playdate.getSystemMenu():addMenuItem("restart", function()
    G.state = "title"
end)

math.randomseed(playdate.getSecondsSinceEpoch())
playdate.display.setRefreshRate(30)

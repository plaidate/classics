-- Shared game state and the helpers that mutate it.

G = {
    state = "title", -- "title" | "play" | "gameover"
    frame = 0,
    stateT = 0,
    camY = -C.SCREEN_H, -- world y of the top of the screen; decreases forever
    rows = {},          -- bottom-to-top; each row is one horizontal band
    player = nil,
    eagle = nil,
    fx = {},            -- splash ripples, in world coords
    score = 0,          -- furthest row reached this run
    lastHorn = -999,
}

local saved = playdate.datastore.read()
G.highScore = (saved and saved.highScore) or 0

function G.saveHigh()
    if G.score > G.highScore then
        G.highScore = G.score
        playdate.datastore.write({ highScore = G.highScore })
    end
end

function G.reset()
    G.camY = -C.SCREEN_H
    G.rows = {}
    G.player = nil
    G.eagle = nil
    G.fx = {}
    G.score = 0
end

function G.addSplash(x, y)
    G.fx[#G.fx + 1] = { x = x, y = y, t = 0 }
end

function G.updateFx()
    for i = #G.fx, 1, -1 do
        local f = G.fx[i]
        f.t = f.t + C.DT
        if f.t > 0.54 then table.remove(G.fx, i) end
    end
    if G.eagle then
        G.eagle.y = G.eagle.y + C.EAGLE_SPEED * C.DT
    end
end

-- Shared game state and persistence helpers.

G = {
    state = "title", -- "title" | "play" | "stageintro" | "gameover" | "win"
    frame = 0,
    stateT = 0,
    score = 0,
    stage = 1,
    waveIdx = 1,
    camX = 0,
    maxScroll = 0,
    scrolling = false,
    player = nil,
    enemies = {},
    barrels = {},  -- { x, y, hp, hitT }
    pickups = {},  -- { x, y }
    input = { dx = 0, dy = 0, punch = false, kick = false, start = false },
    auto = { t = 0 }, -- autopilot scratch state
}

local saved = playdate.datastore.read()
G.highScore = (saved and saved.highScore) or 0

function G.saveHigh()
    if G.score > G.highScore then
        G.highScore = G.score
        playdate.datastore.write({ highScore = G.highScore })
    end
end

function G.addScore(n)
    G.score = G.score + n
end

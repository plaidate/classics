-- Shared mutable game state, score helpers, and the persisted high score.

G = {
    state = "title", -- "title" | "play" | "gameover"
    frame = 0,
    stateT = 0,    -- frames spent in the current state
    score = 0,
    wave = 0,
    waveTimer = 0, -- counts up while fighting; negative = wave-complete card
    camOffX = C.SCREEN_W / 3,
    player = nil,
    enemies = {},
    humans = {},
    lasers = {},
    bullets = {},
    auto = { t = 0, x = 0, y = 0 }, -- autopilot scratchpad
}

local saved = playdate.datastore.read()
G.highScore = (saved and saved.highScore) or 0

function G.saveHigh()
    if G.score > G.highScore then
        G.highScore = G.score
        playdate.datastore.write({ highScore = G.highScore })
    end
end

function G.humansSaved()
    local n = 0
    for _, h in ipairs(G.humans) do
        if not h.exploding then n = n + 1 end
    end
    return n
end

function G.shieldRestore()
    -- one shield back for every two humans still standing
    return math.min(G.humansSaved() // 2, C.MAX_SHIELDS)
end

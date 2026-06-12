-- Shared game state and the helpers that read it.

G = {
    state = "title", -- "title" | "play" | "gameover"
    frame = 0,
    levelFrame = 0,
    score = 0,
    lives = C.START_LIVES,
    level = 1,
    theme = 0,
    grid = {},
    player = nil,
    robots = {}, orbs = {}, bolts = {},
    fruits = {}, pops = {}, flames = {},
    pending = {}, -- robot types still to drop in this level
    overT = 0,
    auto = { t = 0, dir = 1, holdT = 0 },
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

-- per-frame chance of a robot opening fire; rises with the level
function G.fireChance()
    return 0.002 + 0.0002 * math.min(100, G.level)
end

function G.maxRobots()
    return math.min(math.floor((G.level + 5) / 2), 8)
end

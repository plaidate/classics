-- Shared game state and the helpers that read or mutate it.

G = {
    state = "title", -- "title" | "controls" | "play" | "gameover"
    frame = 0,
    score = 0,
    lives = 0,
    level = 1,
    timeLeft = 0,    -- frames on the clock
    gainedT = 0,     -- flash frames after the clock grows
    combo = 0,
    comboT = 0,
    introT = 0,      -- frames the level banner stays up
    overT = 0,

    grid = {},       -- 15 row strings of " ", "X", "L", "H"
    biome = "forest",
    ladders = {},    -- { x, top, bot } feet heights, for the autopilot
    gems = {},
    enemies = {},
    fx = {},
    door = nil,
    exitOpen = false,
    startX = 200, startY = 224,
    player = nil,
    newHigh = false,

    auto = { t = 0, dir = 0 },
}

local saved = playdate.datastore.read()
G.highScore = (saved and saved.highScore) or 0

function G.saveHigh()
    if G.score > G.highScore then
        G.highScore = G.score
        G.newHigh = true
        playdate.datastore.write({ highScore = G.highScore })
    end
end

function G.addScore(n)
    G.score = G.score + n
end

-- how many times the layout list has been completed
function G.cycle()
    return (G.level - 1) // #Level.LAYOUTS
end

-- gem time bonus shrinks on later cycles
function G.gemBonus()
    local t = C.GEM_TIME_BONUS
    return t[math.min(G.cycle() + 1, #t)]
end

-- grow the clock and pop the matching effects at (x, y)
function G.gainTime(sec, x, y)
    G.timeLeft = G.timeLeft + math.floor(sec * 30)
    G.gainedT = 10
    local id = (sec == 0.5) and "half" or tostring(math.floor(sec))
    Fx.add("timer_plus_" .. id .. "_", 14, 2, x, y, { delay = 3, rise = 17 })
    Fx.add("pickup_", 8, 2, x, y)
end

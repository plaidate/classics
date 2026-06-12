-- Shared game state and the high score.

G = {
    state = "title", -- "title" | "play" | "gameover"
    frame = 0,
    stateT = 0,      -- seconds spent in an overlay state
    score = 0,
    lives = C.START_LIVES,
    level = 1,           -- 1-based; layouts and arena art both wrap
    bricks = {},         -- [row][col] = brick id 0..13, or false for empty
    rows = 0,
    bricksLeft = 0,      -- destructible bricks still standing
    bat = nil,           -- built by Bat.reset()
    balls = {},
    capsules = {},       -- falling powerups
    bullets = {},
    impacts = {},
    portalOpen = false,
    portalFrame = 0,     -- 0..3, the exit swinging open
    portalT = 0,
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

function G.addImpact(x, y, kind)
    G.impacts[#G.impacts + 1] = { x = x, y = y, kind = kind, age = 0 }
end

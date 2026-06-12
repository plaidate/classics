-- Shared game state and the helpers that mutate it.

G = {
    state = "title", -- "title" | "play" | "gameover"
    frame = 0,
    score = 0,
    lives = C.START_LIVES,
    wave = 0,
    nextLife = C.EXTRA_LIFE_AT,
    rocks = {},   -- [row][col] = hit points left
    segs = {},    -- myriapod segments, heads lead their chains
    bullets = {},
    bee = nil,
    fly = nil,
    spider = nil,
    player = { x = 200, y = 228, alive = true, respawnT = 0, invulnT = 0, fireT = 0 },
    stepT = 0,    -- fraction of the current myriapod step elapsed
    particles = {},
    popups = {},
    explosions = {}, -- visual-only explosion animations
    stateT = 0,
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
    if G.score >= G.nextLife then
        G.nextLife = G.nextLife + C.EXTRA_LIFE_AT
        G.lives = G.lives + 1
        G.addPopup(G.player.x, G.player.y - 16, "1UP")
        Sfx.extraLife()
    end
end

function G.addPopup(x, y, text)
    G.popups[#G.popups + 1] = { x = x, y = y, text = text, life = 1 }
end

-- visual only: type 0 = rock puff, 1 = big player blast, 2 = segment/meanie
function G.addExplosion(x, y, type)
    G.explosions[#G.explosions + 1] = { x = x, y = y, type = type, t = 0 }
end

function G.burst(x, y, n)
    for _ = 1, n do
        local a = math.random() * math.pi * 2
        local s = 30 + math.random(70)
        G.particles[#G.particles + 1] = {
            x = x, y = y,
            vx = math.cos(a) * s, vy = math.sin(a) * s,
            life = 0.25 + math.random() * 0.3,
        }
    end
end

function G.updateFx()
    for i = #G.particles, 1, -1 do
        local p = G.particles[i]
        p.life = p.life - C.DT
        if p.life <= 0 then
            table.remove(G.particles, i)
        else
            p.x = p.x + p.vx * C.DT
            p.y = p.y + p.vy * C.DT
        end
    end
    for i = #G.popups, 1, -1 do
        local p = G.popups[i]
        p.life = p.life - C.DT
        p.y = p.y - 16 * C.DT
        if p.life <= 0 then table.remove(G.popups, i) end
    end
    -- explosion animations: 8 frames, one every 1/15 s (as the original)
    for i = #G.explosions, 1, -1 do
        local e = G.explosions[i]
        e.t = e.t + C.DT
        if e.t * 15 >= 8 then table.remove(G.explosions, i) end
    end
end

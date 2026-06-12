-- Orbs, robot bolts, fruit pickups, and pop animations.

Orbs = {}

function Orbs.spawn(x, y, dir)
    local o = {
        x = x, y = y, dir = dir,
        t = 0, r = 3,
        blowT = C.ORB_BLOW0,
        floating = false,
        trapped = nil, -- robot type sealed inside, if any
    }
    G.orbs[#G.orbs + 1] = o
    return o
end

function Orbs.spawnFruit(x, y, fromType)
    local kind
    if fromType == 2 then
        -- popping an aggressive robot can yield a heart or, rarely, a star
        local roll = math.random(40)
        if roll == 1 then kind = 5
        elseif roll <= 10 then kind = 4
        else kind = math.random(3) end
    else
        kind = math.random(3)
    end
    G.fruits[#G.fruits + 1] = {
        x = x, y = y, vy = 0, landed = false,
        type = kind, ttl = C.FRUIT_TTL,
    }
end

local function popOrb(i)
    local o = G.orbs[i]
    G.pops[#G.pops + 1] = { x = o.x, y = o.y, t = 0, big = true }
    if o.trapped then
        Harness.count("popped")
        Orbs.spawnFruit(o.x, math.max(o.y, 4), o.trapped)
    end
    if G.player and G.player.blowOrb == o then G.player.blowOrb = nil end
    table.remove(G.orbs, i)
    Sfx.pop()
end

local function updateOrbs()
    for i = #G.orbs, 1, -1 do
        local o = G.orbs[i]
        o.t = o.t + C.DT
        local maxR = 8 + math.min(3, (o.blowT - C.ORB_BLOW0) * 1.6)
        o.r = math.min(maxR, 3 + o.t * 36)
        if not o.floating then
            if o.t >= o.blowT then
                o.floating = true
            else
                local nx = o.x + o.dir * C.ORB_SPEED * C.DT
                if nx < o.r + 4 or nx > C.SCREEN_W - o.r - 4
                    or Level.solid(nx + o.dir * o.r, o.y) then
                    o.floating = true
                else
                    o.x = nx
                end
            end
        else
            o.y = o.y - C.ORB_RISE * C.DT
        end
        if o.t >= C.ORB_LIFE or o.y < -16 then
            popOrb(i)
        end
    end
end

local function updateBolts()
    local c = G.player
    for i = #G.bolts, 1, -1 do
        local b = G.bolts[i]
        local dead = false
        local left = C.BOLT_SPEED * C.DT
        while left > 0 and not dead do
            local step = math.min(2, left)
            b.x = b.x + b.dir * step
            left = left - step
            if b.x < 2 or b.x > C.SCREEN_W - 2 or Level.solid(b.x, b.y) then
                dead = true
            end
        end
        if not dead then
            for _, o in ipairs(G.orbs) do
                if math.abs(o.x - b.x) < o.r + 2 and math.abs(o.y - b.y) < o.r + 2 then
                    o.t = C.ORB_LIFE -- shot orbs burst on their next update
                    dead = true
                    break
                end
            end
        end
        if not dead and c and c.health > 0
            and math.abs(b.x - c.x) < 7 and b.y > c.y - 19 and b.y < c.y + 2 then
            if Player.hurt(b.dir) then dead = true end
        end
        if dead then table.remove(G.bolts, i) end
    end
end

local function updateFruits()
    local c = G.player
    for i = #G.fruits, 1, -1 do
        local f = G.fruits[i]
        Level.fall(f, 3)
        if f.y > C.SCREEN_H + 20 then f.y = 0 end
        f.ttl = f.ttl - C.DT
        local taken = false
        if c and c.health > 0 and math.abs(f.x - c.x) < 12
            and f.y - 5 > c.y - 22 and f.y - 5 < c.y + 4 then
            taken = true
            Harness.count("fruit")
            if f.type == 4 then
                c.health = math.min(C.START_HEALTH, c.health + 1)
                Sfx.bonus()
            elseif f.type == 5 then
                G.lives = G.lives + 1
                Sfx.bonus()
            else
                G.addScore(f.type * 100)
                Sfx.score()
            end
        end
        if taken or f.ttl <= 0 then
            G.pops[#G.pops + 1] = { x = f.x, y = f.y - 6, t = 0, big = false }
            table.remove(G.fruits, i)
        end
    end
end

local function updatePops()
    for i = #G.pops, 1, -1 do
        local p = G.pops[i]
        p.t = p.t + C.DT
        if p.t > 0.4 then table.remove(G.pops, i) end
    end
end

function Orbs.update()
    updateOrbs()
    updateBolts()
    updateFruits()
    updatePops()
end

-- Street thugs and heavies. Each enemy runs a small state machine
-- (pause / approach / goto) on top of the shared Fighters behaviour, with
-- group AI that lets only C.MAX_ATTACKERS move in on the player at once.
-- The heavy doubles as the stage-end boss with a bigger health pool.

Enemies = {}

local TYPES = {
    thug = { anims = "vax", hp = 6, speedX = 1, speedY = 1, animRate = 6,
        anchorY = 128, halfW = C.HALF_HIT_W, halfH = C.HALF_HIT_H, score = 20,
        attacks = { "thugPunchL", "thugPunchR" } },
    heavy = { anims = "boss", hp = 12, speedX = 0.9, speedY = 0.8, animRate = 7,
        anchorY = 140, halfW = 15, halfH = C.HALF_HIT_H, score = 40,
        attacks = { "heavyPunch", "heavyKick" } },
}

local function attackerCount(self)
    local n = 0
    for _, e in ipairs(G.enemies) do
        if e ~= self and e.state == "approach" then
            n = n + 1
        end
    end
    return n
end

-- pick what to do next once idle: move in, flank, wander, or hang back
local function decide(e)
    local p = G.player

    if #G.enemies <= 1 then
        e.state = "approach"
        return
    end

    local r = math.random(10)
    if r <= 7 then
        if attackerCount(e) >= C.MAX_ATTACKERS then
            -- attack slots are taken: circle around to the player's far side
            local ys = Util.sign(e.y - p.y)
            if ys == 0 then ys = math.random(0, 1) * 2 - 1 end
            e.state = "goto"
            e.tx = p.x - Util.sign(e.x - p.x) * 25 + math.random(-8, 8)
            e.ty = Util.clamp(p.y + ys * 25, C.MIN_Y, C.MAX_Y)
        else
            e.state = "approach"
        end
    elseif r <= 9 then
        -- drift to a point a moderate distance away, same side
        local xs = Util.sign(e.x - p.x)
        if xs == 0 then xs = math.random(0, 1) * 2 - 1 end
        e.state = "goto"
        e.tx = p.x + xs * math.random(75, 200)
        e.ty = math.random(C.MIN_Y, C.MAX_Y)
    else
        e.state = "pause"
        e.stateT = math.random(25, 50)
    end
end

function Enemies.decideAttack(e)
    if e.state ~= "approach" then return nil end
    local p = G.player
    if p.fall or p.gone then return nil end
    if math.abs(p.y - e.y) >= 1 then return nil end
    local dist = math.abs(e.x - p.x)
    if dist > C.APPROACH_DIST * 0.9 and dist <= C.APPROACH_DIST * 1.1
        and math.random(C.ATTACK_CHANCE) == 1 then
        return Attacks[e.attacks[math.random(#e.attacks)]]
    end
    return nil
end

function Enemies.getMoveTarget(e)
    return e.tx, e.ty
end

function Enemies.getFacing(e)
    return Util.sign(G.player.x - e.x)
end

function Enemies.getOpponents(e)
    return { G.player }
end

function Enemies.spawn(spec)
    local t = TYPES[spec.type]
    local e = {
        kind = spec.type,
        anims = Assets[t.anims],
        x = spec.x, y = spec.y, h = 0,
        vx = 0, vy = 0,
        facing = -1,
        frame = 0,
        walking = false,
        attack = nil, attackT = -999,
        hitT = 0, hitFrame = 0,
        fall = nil, fallT = 0, useDie = false,
        gone = false,
        health = spec.hp or t.hp,
        score = spec.score or t.score,
        speedX = t.speedX, speedY = t.speedY,
        animRate = t.animRate,
        anchorY = t.anchorY,
        halfW = t.halfW, halfH = t.halfH,
        attacks = t.attacks,
        state = "pause", stateT = spec.delay or 20,
        tx = spec.x, ty = spec.y,
        decideAttack = Enemies.decideAttack,
        getMoveTarget = Enemies.getMoveTarget,
        getFacing = Enemies.getFacing,
        getOpponents = Enemies.getOpponents,
    }
    G.enemies[#G.enemies + 1] = e
end

local function updateOne(e)
    local p = G.player

    if e.fall then
        e.state = "downed"
    elseif e.state == "downed" then
        decide(e)
    elseif e.state == "pause" then
        e.stateT = e.stateT - 1
        e.tx, e.ty = e.x, e.y
        if e.stateT < 0 then decide(e) end
    elseif e.state == "approach" then
        -- occasionally back off from a swinging player
        if p.attackT > 0 and math.abs(e.y - p.y) < 10
            and math.abs(e.x - p.x) < 100
            and math.random(C.BACKAWAY_CHANCE) == 1 then
            e.state = "goto"
            e.tx = e.x - e.facing * 45
            e.ty = e.y
        else
            -- hover at punching range on our side of the player
            local side = Util.sign(e.x - p.x)
            if side == 0 then side = 1 end
            e.tx = p.x + C.APPROACH_DIST * side
            e.ty = p.y
        end
    elseif e.state == "goto" then
        if e.x == e.tx and e.y == e.ty then decide(e) end
    end

    -- keep active targets inside the lock-in screen so they stay reachable
    -- (paused enemies may wait offscreen before marching in)
    if e.state == "approach" or e.state == "goto" then
        e.tx = Util.clamp(e.tx, G.camX + 8, G.camX + 392)
        e.ty = Util.clamp(e.ty, C.MIN_Y, C.MAX_Y)
    end

    Fighters.update(e)
end

function Enemies.update()
    for i = #G.enemies, 1, -1 do
        local e = G.enemies[i]
        updateOne(e)
        if e.gone then
            G.addScore(e.score)
            Harness.count("kos")
            table.remove(G.enemies, i)
        end
    end
end

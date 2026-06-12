-- Enemy AI: landers that abduct, mutants that hound, baiters that spiral
-- fire, pods that burst into swarmers, and the swarmers themselves.

Enemies = {}

local PARAMS <const> = {
    lander  = { speed = 5, accel = 0.2, appearSfx = "enemy_appear_normal" },
    mutant  = { speed = 9, accel = 1.0, appearSfx = "enemy_appear_mutant" },
    baiter  = { speed = 9, accel = 0.02, appearSfx = "enemy_appear_ufo" },
    pod     = { speed = 10, accel = 0.06 },
    swarmer = { speed = 8, accel = 2.0 },
}

-- half-extents of each kind's hittable rectangle
local HIT_W <const> = { lander = 28, mutant = 28, baiter = 30, pod = 35, swarmer = 9 }
local HIT_H <const> = { lander = 19, mutant = 16, baiter = 30, pod = 35, swarmer = 9 }

-- startT below zero delays the materialise animation by that many frames
function Enemies.spawn(kind, startT, x, y, vx, vy)
    local e = {
        kind = kind,
        x = x or math.random(0, C.LEVEL_W - 1),
        y = y or math.random(16, C.LEVEL_H - 16),
        vx = vx or 0,
        vy = vy or 0,
        state = (kind == "swarmer") and "alive" or "start",
        stateT = startT or 0,
        retargetT = 0,
        human = nil,      -- the human this enemy is stalking or hauling
        carrying = false,
        bulletT = math.random(15, 45),
        fireAngle = 0,    -- baiters only: the spiral's current angle
        animT = math.random(0, 23),
        sprite = nil,
    }
    e.targetX = e.x + Util.uniform(-50, 50)
    e.targetY = e.y + Util.uniform(-50, 50)
    G.enemies[#G.enemies + 1] = e
end

function Enemies.laserHitTest(e, x, y)
    if e.state ~= "alive" then return false end
    if math.abs(x - e.x) >= HIT_W[e.kind] or math.abs(y - e.y) >= HIT_H[e.kind] then
        return false
    end
    e.state = "exploding"
    e.animT = 0
    Harness.count("kills")
    if e.human then
        if e.carrying then Humans.dropped(e.human) end
        e.human, e.carrying = nil, false
    end
    Sfx.play("enemy_explode")
    if e.kind == "pod" then
        -- pods burst into a scatter of swarmers
        for _ = 1, 3 do
            Enemies.spawn("swarmer", 0, e.x, e.y,
                Util.uniform(-25, 25), Util.uniform(-25, 25))
        end
    end
    return true
end

local function isTargeted(h)
    for _, e in ipairs(G.enemies) do
        if e.human == h then return true end
    end
    return false
end

local function pickHuman(e)
    local best, bestD = nil, nil
    for _, h in ipairs(G.humans) do
        if Humans.abductable(h) and not isTargeted(h) then
            local dx, dy = h.x - e.x, h.y - e.y
            local d = dx * dx + dy * dy
            if not best or d < bestD then best, bestD = h, d end
        end
    end
    e.human = best
end

local function updateAlive(e)
    local prm = PARAMS[e.kind]
    local maxSpeed = prm.speed

    -- let go of a human the player has shot
    if e.human and (e.human.dead or e.human.exploding) then
        e.human, e.carrying = nil, false
    end

    -- now and then a lander gets ideas about the nearest free human
    if not e.human and e.kind == "lander" and math.random() < 0.002 then
        pickHuman(e)
    end

    if e.human then
        if e.carrying then
            -- haul the catch straight up; at the top it becomes a mutant
            e.targetX, e.targetY = e.x, C.SKY_Y
            maxSpeed = 0.5
            if math.abs(e.y - C.SKY_Y) < 5 then
                Enemies.spawn("mutant", 0, e.human.x, e.human.y)
                Harness.count("mutants")
                Humans.die(e.human)
                e.human, e.carrying = nil, false
            end
        else
            local xd = math.abs(e.x - e.human.x)
            if xd < 40 then maxSpeed = 1 end -- ease in, don't overshoot
            if xd > 50 then
                -- first move to a point well above the mark
                e.targetX, e.targetY = e.human.x, e.human.y - 100
            else
                -- then drop onto them
                e.targetX, e.targetY = e.human.x, e.human.y
                if Util.dist(e.x - e.targetX, e.y - e.targetY) < 27 then
                    e.carrying = true
                    Humans.pickedUp(e.human, e)
                    Harness.count("abductions")
                end
            end
        end
    else
        e.retargetT = e.retargetT - 1
        if e.retargetT <= 0 then
            e.retargetT = 30
            local p = G.player
            -- landers only bother the player at close range; the rest
            -- will cross the whole world for them
            local chaseRange = (e.kind == "lander") and 250 or C.LEVEL_W
            if Util.dist(e.x - p.x, e.y - p.y) < chaseRange then
                e.targetX, e.targetY = p.x, p.y
            end
            local xr = (e.kind == "baiter") and 400 or 50
            local yr = (e.kind == "baiter") and 150 or 50
            e.targetX = e.targetX + Util.uniform(-xr, xr)
            e.targetY = e.targetY + Util.uniform(-yr, yr)
        end
    end

    -- steer toward the target, shying away from the world's top and bottom
    local dx, dy = e.targetX - e.x, e.targetY - e.y
    local d = Util.dist(dx, dy)
    local fx, fy = 0, 0
    if d > 0 then
        fx, fy = dx / d * prm.accel, dy / d * prm.accel
    end
    if e.y < 32 then fy = fy + 0.4 end
    if e.y > C.LEVEL_H - 32 then fy = fy - 0.4 end
    e.vx, e.vy = e.vx + fx, e.vy + fy

    local speed = Util.dist(e.vx, e.vy)
    if speed > maxSpeed then
        -- shed excess speed over a few frames rather than all at once
        local s = math.max(speed * 0.85, maxSpeed) / speed
        e.vx, e.vy = e.vx * s, e.vy * s
    end
    e.x, e.y = e.x + e.vx, e.y + e.vy

    if e.carrying then
        e.human.x, e.human.y = e.x, e.y + C.CARRY_DY
    end

    -- firing
    e.bulletT = e.bulletT - 1
    if e.bulletT <= 0 then
        if e.kind == "baiter" then
            -- baiters sweep their shots around in a slow spiral
            Projectiles.spawnBullet(e.x, e.y,
                math.cos(e.fireAngle) * 3, math.sin(e.fireAngle) * 3)
            e.fireAngle = e.fireAngle + 0.3
            e.bulletT = 4
        elseif G.player.lives > 0 then
            local px, py = G.player.x - e.x, G.player.y - e.y
            local pd = Util.dist(px, py)
            if pd > 50 and pd < 150 then
                -- a shot at the player, with some scatter
                Projectiles.spawnBullet(e.x, e.y,
                    (px / pd + Util.uniform(-0.5, 0.5)) * 6,
                    (py / pd + Util.uniform(-0.5, 0.5)) * 6)
                e.bulletT = math.random(10, (e.kind == "mutant") and 15 or 45)
            end
        end
    end

    -- animation
    e.animT = e.animT + 1
    if e.kind == "lander" then
        local f = 0
        if e.human then
            if e.carrying then
                f = 2
            elseif Util.dist(e.x - e.human.x, e.y - e.human.y) < 45 then
                f = 1
            end
        end
        e.sprite = "lander" .. f
    elseif e.kind == "mutant" then
        e.sprite = "mutant" .. ((e.animT // 3) % 4)
    elseif e.kind == "baiter" then
        e.sprite = "baiter" .. (math.floor(e.animT / 1.5) % 8)
    elseif e.kind == "pod" then
        -- frames 0-2 face left, 3-5 face right
        local f = Util.fbFrame(e.animT // 3, 3)
        if e.vx > 0 then f = f + 3 end
        e.sprite = "pod" .. f
    else
        e.sprite = "swarmer" .. ((e.animT // 3) % 8)
    end
end

function Enemies.update(e)
    local delta = Util.wrapDelta(e.x)
    if delta ~= 0 then
        e.x = e.x + delta
        e.targetX = e.targetX + delta
    end

    if e.state == "start" then
        e.stateT = e.stateT + 1
        if e.stateT == 1 and PARAMS[e.kind].appearSfx then
            Sfx.play(PARAMS[e.kind].appearSfx)
        end
        if e.stateT >= C.APPEAR_TIME then
            e.state = "alive"
        elseif e.stateT >= 0 then
            e.sprite = "appear" .. math.min(10, (e.stateT * 11) // C.APPEAR_TIME)
        end
    elseif e.state == "alive" then
        updateAlive(e)
    elseif e.state == "exploding" then
        e.animT = e.animT + 1
        e.sprite = "enemy_explode" .. math.min(9, e.animT)
        if e.animT >= 10 then e.state = "dead" end
    end
end

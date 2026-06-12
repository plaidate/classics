-- Falling powerup capsules, gun bolts, and the short-lived impact flashes.

Drops = {}

-- capsule types, matching the sprite row numbers
Drops.EXTEND, Drops.GUN, Drops.SHRINK, Drops.MAGNET, Drops.MULTI,
Drops.FAST, Drops.SLOW, Drops.PORTAL, Drops.LIFE = 0, 1, 2, 3, 4, 5, 6, 7, 8

-- Weighted pick. The portal capsule only enters the pool near the end of
-- a level, at which point it dominates it.
local function pickType()
    local weights = {
        [Drops.EXTEND] = 6, [Drops.GUN] = 6, [Drops.SHRINK] = 6,
        [Drops.MAGNET] = 6, [Drops.MULTI] = 6, [Drops.FAST] = 6,
        [Drops.SLOW] = 6, [Drops.LIFE] = 2,
        [Drops.PORTAL] = (G.bricksLeft > 20 or G.portalOpen) and 0 or 20,
    }
    local total = 0
    for _, w in pairs(weights) do total = total + w end
    local roll = math.random() * total
    for t, w in pairs(weights) do
        roll = roll - w
        if roll <= 0 then return t end
    end
    return Drops.EXTEND
end

function Drops.spawnCapsule(x, y)
    G.capsules[#G.capsules + 1] = { x = x, y = y, kind = pickType(), age = 0 }
end

function Drops.spawnBullet(x, y, side)
    G.bullets[#G.bullets + 1] = { x = x, y = y, side = side }
end

local FORM <const> = {
    [Drops.EXTEND] = Bat.EXTENDED,
    [Drops.GUN] = Bat.GUN,
    [Drops.SHRINK] = Bat.SMALL,
    [Drops.MAGNET] = Bat.MAGNET,
}

local JINGLE <const> = {
    [Drops.EXTEND] = "bat_extend",
    [Drops.GUN] = "bat_gun",
    [Drops.SHRINK] = "bat_small",
    [Drops.MAGNET] = "magnet",
    [Drops.MULTI] = "multiball",
    [Drops.FAST] = "speed_up",
    [Drops.SLOW] = "powerup",
    [Drops.LIFE] = "extra_life",
}

function Drops.apply(kind)
    Harness.count("powerups")
    if JINGLE[kind] then Sfx.play(JINGLE[kind]) end
    if FORM[kind] then
        Bat.morphTo(FORM[kind])
    elseif kind == Drops.MULTI then
        local fanned = {}
        for _, b in ipairs(G.balls) do
            for _, nb in ipairs(Ball.split(b)) do
                fanned[#fanned + 1] = nb
            end
        end
        G.balls = fanned
    elseif kind == Drops.FAST then
        Ball.nudgeSpeeds(3)
    elseif kind == Drops.SLOW then
        Ball.nudgeSpeeds(-3)
    elseif kind == Drops.PORTAL then
        Main.openPortal()
    elseif kind == Drops.LIFE then
        G.lives = G.lives + 1
    end
end

function Drops.update()
    -- capsules drift down; the bat sweeps them up
    for i = #G.capsules, 1, -1 do
        local cap = G.capsules[i]
        cap.age = cap.age + 1
        cap.y = cap.y + 1
        local caught = cap.y >= C.BAT_Y - 5 and cap.y <= C.BAT_Y + 15
            and math.abs(cap.x - G.bat.x) < Bat.halfWidth() + C.BALL_R
        if caught then
            G.addImpact(cap.x, cap.y - 5, 14)
            Drops.apply(cap.kind)
            table.remove(G.capsules, i)
        elseif cap.y > C.SCREEN_H + 6 then
            table.remove(G.capsules, i)
        end
    end

    -- bolts fly straight up until they meet something
    for i = #G.bullets, 1, -1 do
        local bolt = G.bullets[i]
        bolt.y = bolt.y - C.BULLET_SPEED
        local hx, _, _, kind = Bricks.collide(bolt.x, bolt.y, 0, -1, 1)
        if hx then
            G.addImpact(bolt.x, bolt.y, 15)
            if kind ~= "wall" then
                Sfx.play("bullet_hit", 4)
            end
            table.remove(G.bullets, i)
        end
    end

    -- impact flashes burn out after 8 frames
    for i = #G.impacts, 1, -1 do
        local im = G.impacts[i]
        im.age = im.age + 1
        if im.age >= 8 then
            table.remove(G.impacts, i)
        end
    end
end

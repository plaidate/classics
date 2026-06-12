-- The player's ship: momentum, the 16-frame flip, firing, getting hurt,
-- exploding, respawning, and ferrying caught humans back to the ground.

Player = {}

function Player.new()
    G.player = {
        x = C.LEVEL_W / 2,
        y = C.LEVEL_H / 2,
        vx = 0,
        vy = 0,
        lives = C.START_LIVES,
        shields = C.MAX_SHIELDS,
        tokens = 0,  -- three extra-life tokens become an extra life
        facing = 1,
        tilt = 0,
        frame = 0,   -- 0 faces right, 8 faces left, the rest are mid-flip
        animT = 0,
        hurtT = 0,
        fireT = 0,
        explodeT = 0,
        carried = nil, -- the human riding below the ship, if any
        sprite = "ship0",
        boostSprite = nil,
        boostX = 0,
        boostY = 0,
    }
end

-- where the laser turret sits relative to the ship's centre, per tilt
function Player.laserYOff(p)
    if p.tilt < 0 then return -1 elseif p.tilt > 0 then return 1 else return 2 end
end

-- enemy fire (and anything else) testing a point against the hull
function Player.hitTest(x, y)
    local p = G.player
    if p.lives == 0 or p.explodeT > 0 then return false end
    if math.abs(x - p.x) >= 20 or math.abs(y - p.y) >= 8 then return false end

    p.hurtT = C.HURT_TIME
    p.shields = p.shields - 1
    Sfx.play("player_hit")

    if p.shields == 0 then
        p.lives = p.lives - 1
        Harness.count("deaths")
        if p.lives == 0 then Sfx.setThrust(false) end
        Sfx.play("player_explode")
        p.explodeT = C.EXPLODE_TIME
        if p.carried then
            Humans.dropped(p.carried)
            p.carried = nil
        end
    end
    return true
end

-- try a spread of random spots and take the one whose nearest enemy
-- is furthest away on the x axis
local function respawn(p)
    p.shields = C.MAX_SHIELDS
    p.vx, p.vy = 0, 0
    local bestScore = -1
    for _ = 1, 20 do
        local x = Util.uniform(0, C.LEVEL_W - 1)
        local y = Util.uniform(75, 150)
        local nearest = math.huge
        for _, e in ipairs(G.enemies) do
            nearest = math.min(nearest, Util.wrapDist(e.x, x))
        end
        if nearest > bestScore then
            bestScore = nearest
            p.x, p.y = x, y
        end
    end
end

function Player.update(xIn, yIn, fire, reverse, crank)
    local p = G.player
    p.hurtT = p.hurtT - 1
    p.fireT = p.fireT - 1

    if p.explodeT > 0 then
        p.explodeT = p.explodeT - 1
        p.sprite = "ship_explode" .. math.min(17, (C.EXPLODE_TIME - p.explodeT) // 2)
        p.boostSprite = nil
        Sfx.setThrust(false)
        if p.explodeT == 0 and p.lives > 0 then respawn(p) end
        return
    end
    if p.lives == 0 then
        p.sprite = nil
        p.boostSprite = nil
        Sfx.setThrust(false)
        return
    end

    p.tilt = yIn
    if xIn ~= 0 then p.facing = Util.sign(xIn) end
    if reverse then p.facing = -p.facing end

    -- thrust only counts once the flip animation has fully turned the ship
    local target = (p.facing < 0) and 8 or 0
    local moveX = (p.frame == target) and xIn or 0

    p.vx = p.vx * C.DRAG_X + moveX * C.FORCE_X
    p.vy = p.vy * C.DRAG_Y + yIn * C.FORCE_Y
    p.x = p.x + p.vx
    p.y = Util.clamp(p.y + p.vy + crank * C.CRANK_Y, 0, C.LEVEL_H)

    -- catch a tumbling human, or set the one we have down on solid ground
    if not p.carried then
        for _, h in ipairs(G.humans) do
            if Humans.catchable(h)
                    and Util.dist(h.x - p.x, h.y - p.y) < C.PICKUP_RANGE then
                Humans.pickedUp(h, "player")
                p.carried = h
                break
            end
        end
    else
        p.carried.x, p.carried.y = p.x, p.y + C.CARRY_DY
        if Humans.onTerrain(p.carried) then
            Humans.dropped(p.carried)
            p.carried = nil
            Sfx.play("rescue_prisoner")
            Harness.count("rescues")
        end
    end

    if p.frame == target then
        -- the turret only works with the ship square-on
        if fire and p.fireT <= 0 then
            p.fireT = C.FIRE_COOLDOWN
            Projectiles.spawnLaser(p.x + 20 * p.facing, p.y + Player.laserYOff(p),
                p.vx + C.LASER_SPEED * p.facing)
        end
    else
        -- flip onward toward the target frame, two sprite frames every three ticks
        p.animT = p.animT + 2
        while p.animT >= 3 do
            p.animT = p.animT - 3
            p.frame = (p.frame + 1) % 16
        end
    end

    local thrusting = moveX ~= 0
    Sfx.setThrust(thrusting)
    if thrusting then
        p.boostSprite = "boost_" .. ((moveX > 0) and 0 or 1) .. "_" .. ((G.frame // 3) % 2)
        p.boostX, p.boostY = p.x - 33 * moveX, p.y - 2
    else
        p.boostSprite = nil
    end

    local base = (p.hurtT > 0) and "hurt" or "ship"
    local tiltSuffix = ""
    if p.frame % 8 == 0 and p.tilt ~= 0 then
        tiltSuffix = (p.tilt < 0) and "u" or "d"
    end
    p.sprite = base .. p.frame .. tiltSuffix
end

function Player.levelEnded(shieldRestore, humansSaved)
    local p = G.player
    p.shields = math.min(p.shields + shieldRestore, C.MAX_SHIELDS)
    if humansSaved == 10 then
        -- a full rescue earns a token; three tokens make a life
        p.tokens = p.tokens + 1
        if p.tokens >= 3 then
            p.lives = p.lives + 1
            p.tokens = p.tokens - 3
        end
    end
end

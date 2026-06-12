-- The miner: movement, orb blowing, getting hurt, and dying.

Player = {}

local clamp = Util.clamp

function Player.new()
    return {
        x = 200, y = 56, vy = 0,
        facing = 1, landed = false, moving = false,
        health = C.START_HEALTH,
        hurtT = C.KNOCK_TIME, -- spawn invulnerability
        fireT = 0,
        knockDir = 1,
        blowOrb = nil,
    }
end

function Player.reset()
    local c = G.player
    c.x, c.y, c.vy = 200, 56, 0
    c.facing, c.landed, c.moving = 1, false, false
    c.health = C.START_HEALTH
    c.hurtT = C.KNOCK_TIME
    c.fireT = 0
    c.knockDir = 1
    c.blowOrb = nil
end

function Player.hurt(dirX)
    local c = G.player
    if c.hurtT > 0 or c.health <= 0 then return false end
    c.hurtT = C.HURT_TIME
    c.health = c.health - 1
    c.vy = C.KNOCK_VY
    c.landed = false
    c.knockDir = dirX
    if c.health > 0 then Sfx.ouch() else Sfx.die() end
    return true
end

function Player.update(dir, jump, blowPress, blowHeld)
    local c = G.player
    c.fireT = c.fireT - C.DT
    c.hurtT = c.hurtT - C.DT
    c.moving = false

    if c.health > 0 then
        Level.fall(c, 4)
        if c.y > C.SCREEN_H + 20 then c.y = 0 end
    else
        -- dead: drop straight out of the level, no collision
        c.vy = math.min(c.vy + C.GRAVITY * C.DT, C.MAX_FALL)
        c.y = c.y + c.vy * C.DT
    end

    if c.landed then c.hurtT = math.min(c.hurtT, C.KNOCK_TIME) end

    if c.hurtT > C.KNOCK_TIME then
        -- knocked back; no control until we land or the timer runs down
        if c.health > 0 then
            Level.moveX(c, c.knockDir, C.KNOCK_SPEED * C.DT, 5)
        elseif c.y > C.SCREEN_H * 1.5 then
            Harness.count("deaths")
            G.lives = G.lives - 1
            Player.reset()
        end
    else
        if dir ~= 0 then
            c.facing = dir
            if c.fireT < C.ORB_COOLDOWN - 0.17 then
                c.moving = not Level.moveX(c, dir, C.RUN_SPEED * C.DT, 5)
            end
        end
        if blowPress and c.fireT <= 0 and #G.orbs < C.MAX_ORBS then
            local ox = clamp(c.x + c.facing * 18, 10, C.SCREEN_W - 10)
            c.blowOrb = Orbs.spawn(ox, c.y - 12, c.facing)
            c.fireT = C.ORB_COOLDOWN
            Harness.count("orbs")
            Sfx.blow()
        end
        if jump and c.landed then
            c.vy = C.JUMP_VY
            c.landed = false
            Sfx.jump()
        end
    end

    -- holding B keeps inflating the most recent orb
    if blowHeld and c.blowOrb then
        local o = c.blowOrb
        o.blowT = o.blowT + 4 * C.DT
        if o.blowT >= C.ORB_BLOW_MAX then c.blowOrb = nil end
    elseif not blowHeld then
        c.blowOrb = nil
    end
end

-- Shared fighter behaviour: movement in the street band, attack timing,
-- taking hits, knockdowns, KO flashing and sprite selection. The player and
-- enemies plug in their own decideAttack / getMoveTarget / getFacing /
-- getOpponents callbacks.

local gfx <const> = playdate.graphics

Fighters = {}

-- Attack timing is in 30fps frames; reach is in half-scale pixels.
-- hits is the set of animation frames (0-indexed) on which the blow lands;
-- repeat damage within one swing is gated by the target's hit-stun.
Attacks = {
    punch1 = { anim = "rpunch", dmg = 1, time = 9, ft = 3, frames = 3,
        hits = { [2] = true }, reach = 40, combo = "punch2",
        whoosh = "punch_whoosh", thud = "punch_hit" },
    punch2 = { anim = "lpunch", dmg = 1, time = 9, ft = 3, frames = 3,
        hits = { [2] = true }, reach = 40, combo = "punch3",
        whoosh = "punch_whoosh", thud = "punch_hit" },
    punch3 = { anim = "uppercut", dmg = 3, time = 9, ft = 3, frames = 3,
        hits = { [2] = true }, reach = 40, knockdown = true,
        whoosh = "punch_whoosh", thud = "punch_hit" },
    kick = { anim = "lowkick", dmg = 2, time = 8, ft = 4, frames = 2,
        hits = { [1] = true }, reach = 40, recovery = 3,
        whoosh = "kick_whoosh", thud = "kick_hit" },
    flykick = { anim = "flying_kick", dmg = 3, time = 40, ft = 3, frames = 8,
        hits = { [2] = true, [3] = true, [4] = true, [5] = true }, reach = 40,
        recovery = 4, flying = true, knockdown = true,
        whoosh = "flyingkick_whoosh", thud = "flyingkick_hit" },

    thugPunchL = { anim = "lpunch", dmg = 1, time = 9, ft = 3, frames = 3,
        hits = { [2] = true }, reach = 40, recovery = 25,
        whoosh = "punch_whoosh", thud = "punch_hit" },
    thugPunchR = { anim = "rpunch", dmg = 1, time = 9, ft = 3, frames = 3,
        hits = { [2] = true }, reach = 40, recovery = 25,
        whoosh = "punch_whoosh", thud = "punch_hit" },
    heavyPunch = { anim = "lpunch", dmg = 2, time = 14, ft = 5, frames = 3,
        hits = { [2] = true }, reach = 42, recovery = 25,
        whoosh = "boss_punch", thud = "punch_hit" },
    heavyKick = { anim = "kick", dmg = 2, time = 9, ft = 5, frames = 2,
        hits = { [1] = true }, reach = 42, recovery = 25,
        whoosh = "kick_whoosh", thud = "kick_hit" },
}

function Fighters.attackFrame(f)
    return math.min(f.frame // f.attack.ft, f.attack.frames - 1)
end

function Fighters.start(f, atk)
    f.attack = atk
    f.attackT = atk.time
    f.frame = 0
    Sfx.play(atk.whoosh)
    if f.player then
        if atk.anim == "lowkick" or atk.flying then
            Harness.count("kicks")
        else
            Harness.count("punches")
        end
    end
    if atk.flying then
        f.vx = C.FLYKICK_VX * f.facing
        f.vy = C.FLYKICK_VY
    end
end

-- keep fighters inside the current screen, but only block movement that
-- would take them further out, so off-screen spawns can walk in
function Fighters.bounds(f, dx, dy)
    if dx < 0 and f.x < G.camX + 8 then f.x = G.camX + 8 end
    if dx > 0 and f.x > G.camX + 392 then f.x = G.camX + 392 end
    if dy < 0 and f.y < C.MIN_Y then f.y = C.MIN_Y end
    if dy > 0 and f.y > C.MAX_Y then f.y = C.MAX_Y end
end

function Fighters.hit(o, hitter, atk)
    o.health = o.health - atk.dmg
    o.hitT = atk.dmg * C.STUN_PER_DMG
    o.hitFrame = math.random(0, 1)
    Sfx.play(atk.thud)
    if hitter.player then Harness.count("hits") end

    -- interrupt the victim's own attack, unless they're mid jump-kick
    if o.attackT > 0 and o.attack and not o.attack.flying then
        o.attackT = 0
    end

    -- spin to face whoever hit us
    if hitter.x ~= o.x then
        o.facing = Util.sign(hitter.x - o.x)
    end

    if atk.knockdown or o.health <= 0 then
        o.fall = "down"
        o.fallT = 0
        o.hitT = 0
        o.useDie = o.health <= 0 and math.random(0, 1) == 0
        o.vx = -o.facing * C.KNOCKBACK
    end
end

-- land the current attack on whoever is in front of us
function Fighters.strike(f)
    local atk = f.attack
    for _, o in ipairs(f:getOpponents()) do
        local dx = o.x - f.x
        local dy = o.y - f.y
        if o.fall == nil and o.hitT <= 0
            and dx * f.facing >= 0 -- at or ahead of us (a point-blank hit still lands)
            and math.abs(dy) < o.halfH
            and math.abs(dx) < atk.reach + o.halfW then
            Fighters.hit(o, f, atk)
        end
    end
    if f.player then
        Stages.hitBarrels(f, atk)
    end
end

function Fighters.update(f)
    f.attackT = f.attackT - 1

    -- airborne (jump kick or knocked-down slide that left the ground)
    if f.h > 0 or f.vy ~= 0 then
        f.x = f.x + f.vx
        Fighters.bounds(f, f.vx, 0)
        f.vy = f.vy + C.GRAVITY
        f.h = f.h - f.vy
        if f.h <= 0 then
            f.h, f.vx, f.vy = 0, 0, 0
            f.hitT = 0 -- no recoil animation after landing
        end
    end

    if f.fall == "down" then
        f.x = f.x + f.vx
        f.vx = Util.moveTowards(f.vx, 0, C.KNOCK_FRICTION)
        Fighters.bounds(f, f.vx, 0)
        f.fallT = f.fallT + 1
        if f.health > 0 then
            if f.fallT > C.DOWN_TIME then
                f.fall = "getup"
                f.fallT = 0
            end
        elseif f.fallT > C.KO_TIME then
            f.gone = true -- resolved by the owner (life loss or removal)
        end

    elseif f.fall == "getup" then
        f.fallT = f.fallT + 1
        f.x = f.x + 0.2 * f.facing
        if f.fallT > C.GETUP_TIME then
            f.fall = nil
            f.frame = 0
        end

    elseif f.hitT > 0 then
        f.hitT = f.hitT - 1

    else
        -- on our feet: maybe start an attack
        local recovery = (f.attack and f.attack.recovery) or 0
        if f.attackT <= -recovery then
            local atk = f:decideAttack()
            if atk then Fighters.start(f, atk) end
        end

        if f.attackT <= 0 then
            -- walking or standing
            local wantFacing = f:getFacing()
            if wantFacing and wantFacing ~= 0 then f.facing = wantFacing end

            local tx, ty = f:getMoveTarget()
            local nx, dx = Util.moveTowards(f.x, tx, f.speedX)
            local ny, dy = Util.moveTowards(f.y, ty, f.speedY)
            f.x, f.y = nx, ny
            f.walking = (dx ~= 0 or dy ~= 0)
            Fighters.bounds(f, dx, dy)
            f.frame = f.frame + 1
        else
            -- mid-attack
            f.frame = f.frame + 1
            if f.attack.hits[Fighters.attackFrame(f)] then
                Fighters.strike(f)
            end
        end
    end
end

-- returns image, flipped, visible for the fighter's current pose
function Fighters.sprite(f)
    local anim, idx
    if f.fall == "down" then
        -- KO'd fighters flash before they're removed
        if f.health <= 0 and f.fallT > C.DOWN_TIME // 2 and (f.fallT // 5) % 2 == 0 then
            return nil, false, false
        end
        if f.useDie then
            anim, idx = "die", math.min(f.fallT // 10, 2)
        else
            anim, idx = "knockdown", math.min(f.fallT // 5, 2)
        end
    elseif f.fall == "getup" then
        anim = "getup"
        idx = math.min(f.fallT // 4, #f.anims.getup - 1)
    elseif f.hitT > 0 then
        anim, idx = "hit", f.hitFrame
    elseif f.attackT > 0 and f.attack then
        anim, idx = f.attack.anim, Fighters.attackFrame(f)
    elseif f.walking then
        anim = "walk"
        idx = (f.frame // f.animRate) % #f.anims.walk
    else
        anim = "stand"
        idx = (f.frame // (f.animRate * 2)) % #f.anims.stand
    end
    return f.anims[anim][idx + 1], f.facing < 0, true
end

function Fighters.draw(f)
    local img, flipped, visible = Fighters.sprite(f)
    if not visible then return end
    local sx = f.x - G.camX
    if sx < -120 or sx > C.SCREEN_W + 120 then return end

    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillEllipseInRect(sx - 16, f.y - 4, 32, 7)
    gfx.setColor(gfx.kColorBlack)

    -- sprites are 160x160 cells anchored at (80, anchorY)
    img:draw(sx - 80, f.y - f.h - f.anchorY,
        flipped and gfx.kImageFlippedX or gfx.kImageUnflipped)
end

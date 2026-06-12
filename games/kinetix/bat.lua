-- The bat: crank-driven movement, powerup morphing, the gun, and the
-- portal exit at level's end.

Bat = {}

-- bat forms, matching the sprite row numbers
Bat.NORMAL, Bat.MAGNET, Bat.GUN, Bat.EXTENDED, Bat.SMALL = 0, 1, 2, 3, 4

local MORPH_STEPS <const> = 6 -- full morph animation, two frames per sprite

function Bat.reset()
    G.bat = {
        x = (C.LEFT_EDGE + C.RIGHT_EDGE) / 2,
        form = Bat.NORMAL,   -- what we are right now
        goal = Bat.NORMAL,   -- what the last capsule asked us to become
        morph = 0,           -- 0..MORPH_STEPS progress into the current form
        fireT = 0,
        flash = false,       -- gun muzzle flash, one frame
    }
end

function Bat.spriteFrame()
    return G.bat.morph // 2
end

function Bat.halfWidth()
    return Assets.batWidths[G.bat.form][Bat.spriteFrame()] / 2
end

function Bat.morphTo(form)
    G.bat.goal = form
end

function Bat.update(dx, fireDown)
    local bat = G.bat

    -- morphing: ease into a special form, or back out before switching
    if bat.goal ~= Bat.NORMAL and bat.goal == bat.form and bat.morph < MORPH_STEPS then
        bat.morph = bat.morph + 1
    end
    if bat.goal ~= bat.form and bat.morph > 0 then
        bat.morph = bat.morph - 1
    end
    if bat.morph == 0 then
        bat.form = bat.goal
    end

    -- the gun fires paired bolts while held, once fully formed
    bat.fireT = bat.fireT - 1
    bat.flash = false
    if fireDown and bat.form == Bat.GUN and bat.morph == MORPH_STEPS
        and bat.fireT <= 0 then
        bat.fireT = C.FIRE_COOLDOWN
        bat.flash = true
        Drops.spawnBullet(bat.x - 10, C.BAT_Y, 0)
        Drops.spawnBullet(bat.x + 10, C.BAT_Y, 1)
        Sfx.play("laser")
    end

    -- movement, kept inside the walls (unless the exit portal is open)
    local hw = Bat.halfWidth()
    local nx = math.max(C.BAT_MIN_X + hw, bat.x + dx)
    if not G.portalOpen then
        nx = math.min(C.BAT_MAX_X - hw, nx)
    end
    bat.x = nx
end

-- True once the bat has slid entirely out through the right wall.
function Bat.hasLeftArena()
    return G.bat.x - Bat.halfWidth() >= C.ARENA_X + C.ARENA_W
end

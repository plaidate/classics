-- Enemies: walkers patrol a platform and turn at edges; flyers sweep the
-- screen, diagonally from the third layout cycle. Both can be stomped.
-- Forest levels field triffids and flies, castle levels robots.

Enemies = {}

function Enemies.addWalker(x, footY)
    local castle = G.biome == "castle"
    G.enemies[#G.enemies + 1] = {
        kind = "walker",
        x = x, y = footY,
        dir = (math.random(2) == 1) and 1 or -1,
        speed = C.WALKER_SPEED,
        w = castle and 24 or 25,
        h = castle and 30 or 35,
        health = castle and 2 or 1,
        stompT = 0, dying = false, vy = 0,
    }
end

function Enemies.addFlyer(x, y, cycle)
    local castle = G.biome == "castle"
    G.enemies[#G.enemies + 1] = {
        kind = "flyer",
        x = x, y = y,
        dir = (math.random(2) == 1) and 1 or -1,
        dirY = (cycle >= 2) and 1 or 0,
        speed = C.FLYER_SPEED,
        w = 15,
        h = castle and 20 or 15,
        health = 1,
        stompT = 0, dying = false, vy = 0,
    }
end

local function updateWalker(e)
    local halfW = e.w // 2
    local nx = e.x + e.dir * e.speed
    local probe = nx + e.dir * (halfW + 2)
    if probe < 4 or probe > C.SCREEN_W - 4 or not Level.solid(probe, e.y + 1) then
        e.dir = -e.dir
    else
        e.x = nx
    end
end

local function updateFlyer(e)
    e.x = e.x + e.dir * e.speed
    if e.x < 16 or e.x > C.SCREEN_W - 16 then
        e.dir = -e.dir
        e.x = Util.clamp(e.x, 16, C.SCREEN_W - 16)
    end
    if e.dirY ~= 0 then
        e.y = e.y + e.dirY * e.speed
        if e.y < 24 or e.y > 216 then
            e.dirY = -e.dirY
            e.y = Util.clamp(e.y, 24, 216)
        end
    end
end

function Enemies.update()
    for i = #G.enemies, 1, -1 do
        local e = G.enemies[i]
        if e.dying then
            -- knocked out: drop off the bottom of the level
            e.vy = math.min(e.vy + C.GRAVITY, C.MAX_FALL)
            e.y = e.y + e.vy
            if e.y > C.SCREEN_H + 60 then
                table.remove(G.enemies, i)
            end
        else
            e.stompT = e.stompT - 1
            if e.kind == "walker" then
                updateWalker(e)
            else
                updateFlyer(e)
            end
        end
    end
end

-- sprite name for e's current pose; the _hit variant flashes after a stomp
function Enemies.sprite(e)
    local f = (G.frame // 3) % 8
    local hit = (e.stompT > 0 or e.dying) and "_hit" or ""
    if e.kind == "walker" then
        if G.biome == "castle" then
            local d = (e.dir < 0) and "1" or "0"
            return "robot2_" .. d .. "_" .. f .. hit
        end
        return "triffid_" .. f .. hit
    else
        if G.biome == "castle" then
            return "robot0_" .. f .. hit
        end
        local d = (e.dir < 0) and "1" or "0"
        return "fly_" .. d .. "_" .. f .. hit
    end
end

-- a stomp landed on e this frame
function Enemies.stomp(e)
    if e.stompT <= 0 then
        e.health = e.health - 1
        if e.health <= 0 then
            Enemies.destroy(e)
            G.addScore(C.STOMP_SCORE)
        else
            Sfx.play("enemy_take_damage")
        end
    end
    e.stompT = 2
end

-- kill outright (stomp finisher, or clearing the respawn area)
function Enemies.destroy(e)
    e.dying = true
    local anim = (e.kind == "flyer") and "air_explosion_" or "explosion_"
    Fx.add(anim, 12, 2, e.x, e.y - e.h // 2)
    G.gainTime(C.STOMP_TIME_BONUS, e.x, e.y - e.h // 2)
    Sfx.play("enemy_death")
end

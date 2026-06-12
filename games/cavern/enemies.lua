-- Robots: patrolling, shooting bolts, flame breath, and getting trapped.
-- Type 1 is the standard robot; type 2 is aggressive (snipes orbs, breathes
-- fire at close range, and drops better pickups when popped).

Enemies = {}

function Enemies.spawnTick()
    if G.levelFrame % C.ROBOT_DROP_FRAMES ~= 0 then return end
    if #G.pending == 0 or #G.robots >= G.maxRobots() then return end
    local kind = table.remove(G.pending)
    G.robots[#G.robots + 1] = {
        x = Level.spawnX(), y = -8, vy = 0,
        type = kind, speed = 35 + math.random(0, 2) * 20,
        facing = 1, landed = false,
        dirT = 0, fireT = 2, breathT = 1, flameT = 0,
        dead = false,
    }
end

local function updateRobot(r)
    local c = G.player
    Level.fall(r, 5)
    if r.y > C.SCREEN_H + 20 then r.y = 0 end
    r.dirT = r.dirT - C.DT
    r.breathT = r.breathT - C.DT
    local preFire = r.fireT
    r.fireT = r.fireT + C.DT

    if r.flameT > 0 then
        -- stand and breathe a jet of flame puffs
        r.flameT = r.flameT - C.DT
        local reach = 10 + (0.45 - r.flameT) * 80
        G.flames[#G.flames + 1] = {
            x = r.x + r.facing * reach, y = r.y - 8,
            dir = r.facing, life = 0.2,
        }
    else
        if Level.moveX(r, r.facing, r.speed * C.DT, 6) then r.dirT = 0 end
        if r.dirT <= 0 then
            -- two-in-three chance of heading toward the player
            local dirs = { -1, 1 }
            if c then dirs[3] = (c.x >= r.x) and 1 or -1 end
            r.facing = dirs[math.random(#dirs)]
            r.dirT = 1.7 + math.random() * 2.5
        end
    end

    -- aggressive robots snipe orbs at their own height
    if r.type == 2 and r.fireT >= 0.4 then
        for _, o in ipairs(G.orbs) do
            if o.y >= r.y - 16 and o.y < r.y and math.abs(o.x - r.x) < 100 then
                r.facing = (o.x >= r.x) and 1 or -1
                r.fireT = 0
                Sfx.laser()
                break
            end
        end
    end

    if r.fireT >= 0.2 then
        local p = G.fireChance()
        if c and c.health > 0 and c.y > r.y - 16 and c.y - 20 < r.y then
            p = p * 10 -- much keener when level with the player
        end
        if math.random() < p then
            r.fireT = 0
            Sfx.laser()
        end
    elseif preFire < 0.13 and r.fireT >= 0.13 then
        -- the bolt leaves partway through the firing animation
        G.bolts[#G.bolts + 1] = { x = r.x + r.facing * 11, y = r.y - 8, dir = r.facing }
    end

    if r.type == 2 and r.flameT <= 0 and r.breathT <= 0 and c and c.health > 0 then
        local dx = c.x - r.x
        if math.abs(dx) < C.FLAME_RANGE and math.abs(dx) > 4 and math.abs(c.y - r.y) < 10 then
            r.facing = (dx >= 0) and 1 or -1
            r.flameT = 0.45
            r.breathT = C.FLAME_COOLDOWN
            Sfx.flame()
        end
    end

    for _, o in ipairs(G.orbs) do
        if not o.trapped then
            local dx, dy = o.x - r.x, o.y - (r.y - 8)
            if dx * dx + dy * dy < (o.r + 5) ^ 2 then
                o.trapped = r.type
                o.floating = true
                r.dead = true
                Harness.count("trapped")
                Sfx.trap()
                break
            end
        end
    end
end

function Enemies.update()
    for i = #G.robots, 1, -1 do
        local r = G.robots[i]
        updateRobot(r)
        if r.dead then table.remove(G.robots, i) end
    end
end

function Enemies.updateFlames()
    local c = G.player
    for i = #G.flames, 1, -1 do
        local fl = G.flames[i]
        fl.life = fl.life - C.DT
        fl.x = fl.x + fl.dir * 40 * C.DT
        if c and c.health > 0 and math.abs(fl.x - c.x) < 7
            and fl.y > c.y - 20 and fl.y < c.y + 2 then
            Player.hurt(fl.dir)
        end
        if fl.life <= 0 then table.remove(G.flames, i) end
    end
end

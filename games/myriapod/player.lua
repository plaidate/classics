-- The ship: free movement in the lower zone, autofire, bullets, and dying.

Player = {}

local HW <const>, HH <const> = 6, 5 -- collision half-extents

function Player.reset()
    local p = G.player
    p.x, p.y = C.SCREEN_W / 2, C.SCREEN_H - 12
    p.alive = true
    p.respawnT = 0
    p.invulnT = C.INVULN_TIME
    p.fireT = 0
    G.bullets = {}
end

function Player.overlapsCell(cx, cy)
    local p = G.player
    local x, y = Grid.cellPos(cx, cy)
    return math.abs(x - p.x) < C.CELL / 2 + HW + 2
        and math.abs(y - p.y) < C.CELL / 2 + HH + 2
end

local function canStand(x, y)
    if x < HW + 2 or x > C.SCREEN_W - HW - 2 then return false end
    if y < C.ZONE_ROW * C.CELL + HH or y > C.SCREEN_H - HH - 2 then return false end
    return not Grid.blocked(x, y, HW, HH)
end

local function tryMove(dx, dy)
    local p = G.player
    if canStand(p.x + dx, p.y + dy) then
        p.x, p.y = p.x + dx, p.y + dy
    end
end

function Player.kill()
    local p = G.player
    G.burst(p.x, p.y, 14)
    G.addExplosion(p.x, p.y, 1)
    Sfx.playerDie()
    Harness.count("deaths")
    p.alive = false
    p.respawnT = C.RESPAWN_TIME
    G.lives = G.lives - 1
end

local function checkContact()
    local p = G.player
    if p.invulnT > 0 then return end
    for _, seg in ipairs(G.segs) do
        local sx, sy = Myriapod.segPos(seg)
        if math.abs(sx - p.x) < 9 and math.abs(sy - p.y) < 9 then
            Player.kill()
            return
        end
    end
    for _, kind in ipairs({ "bee", "fly", "spider" }) do
        local e = G[kind]
        if e and math.abs(e.x - p.x) < 9 and math.abs(e.y - p.y) < 9 then
            Player.kill()
            return
        end
    end
end

function Player.update(dx, dy, fire, nudge)
    local p = G.player
    if not p.alive then
        p.respawnT = p.respawnT - C.DT
        if p.respawnT <= 0 and G.lives > 0 then
            p.x, p.y = C.SCREEN_W / 2, C.SCREEN_H - 12
            Grid.clearArea(p.x, p.y, HW + 6, HH + 6)
            p.alive = true
            p.invulnT = C.INVULN_TIME
        end
        return
    end

    p.invulnT = math.max(0, p.invulnT - C.DT)

    local stride = C.PLAYER_SPEED * C.DT
    if dx ~= 0 and dy ~= 0 then stride = stride * 0.707 end
    tryMove(dx * stride, 0)
    tryMove(0, dy * stride)
    if nudge ~= 0 then
        tryMove(Util.clamp(nudge, -4, 4), 0)
    end

    p.fireT = p.fireT - C.DT
    if fire and p.fireT <= 0 then
        p.fireT = C.FIRE_COOLDOWN
        G.bullets[#G.bullets + 1] = { x = p.x, y = p.y - 8 }
        Sfx.fire()
        Harness.count("shots")
    end

    checkContact()
end

function Player.updateBullets()
    for i = #G.bullets, 1, -1 do
        local b = G.bullets[i]
        b.y = b.y - C.BULLET_SPEED * C.DT
        local cx, cy = Grid.cellAt(b.x, b.y)
        if b.y < -4 then
            table.remove(G.bullets, i)
        elseif Grid.get(cx, cy) then
            Grid.damage(cx, cy, 1, true)
            table.remove(G.bullets, i)
        elseif Myriapod.hitAt(b.x, b.y) or Flyers.hitAt(b.x, b.y) then
            table.remove(G.bullets, i)
        end
    end
end

-- Player lasers and enemy bullets.

Projectiles = {}

function Projectiles.spawnLaser(x, y, vx)
    G.lasers[#G.lasers + 1] = { x = x + vx, y = y, vx = vx, t = 0 }
    Harness.count("shots")
    Sfx.play("player_shoot")
end

function Projectiles.spawnBullet(x, y, vx, vy)
    G.bullets[#G.bullets + 1] = { x = x, y = y, vx = vx, vy = vy }
    -- distant shots are heard faintly, far-off ones not at all
    local d = Util.dist(x - G.player.x, y - G.player.y)
    Sfx.play("enemy_laser", Util.remapClamp(d, 200, 1250, 1, 0))
end

local function laserHits(x, y)
    local hit = false
    for _, e in ipairs(G.enemies) do
        if Enemies.laserHitTest(e, x, y) then hit = true end
    end
    for _, h in ipairs(G.humans) do
        if Humans.laserHitTest(h, x, y) then hit = true end
    end
    return hit
end

function Projectiles.update()
    for i = #G.lasers, 1, -1 do
        local l = G.lasers[i]
        l.x = l.x + Util.wrapDelta(l.x)
        l.x = l.x + l.vx
        l.t = l.t + 1
        -- test the midpoint of this frame's travel too, so a fast shot
        -- can't pass clean through the smaller enemies
        local kill = laserHits(l.x - l.vx / 2, l.y)
        if laserHits(l.x, l.y) then kill = true end
        if math.abs(l.x - G.player.x) > C.LASER_RANGE then kill = true end
        if kill then table.remove(G.lasers, i) end
    end

    for i = #G.bullets, 1, -1 do
        local b = G.bullets[i]
        b.x = b.x + Util.wrapDelta(b.x)
        b.x = b.x + b.vx
        b.y = b.y + b.vy
        local kill = math.abs(b.x - G.player.x) > C.BULLET_RANGE
        if Player.hitTest(b.x, b.y) then kill = true end
        if kill then table.remove(G.bullets, i) end
    end
end

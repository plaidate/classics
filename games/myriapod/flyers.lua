-- The pests: a bee that chips rocks crossing mid-screen, a fly that dives
-- down seeding fresh rocks, and a spider that prowls the player's zone.

Flyers = {}

function Flyers.reset()
    G.bee, G.fly, G.spider = nil, nil, nil
end

local function spawnBee()
    local fromLeft = math.random(2) == 1
    G.bee = {
        x = fromLeft and -10 or C.SCREEN_W + 10,
        y = 0,
        baseY = (math.random(3, 9) + 0.5) * C.CELL,
        dx = fromLeft and 1 or -1,
        t = math.random() * 4,
        lastCx = -99,
    }
    G.bee.y = G.bee.baseY
end

local function spawnFly()
    local x = (math.random(1, C.COLS - 2) + 0.5) * C.CELL
    G.fly = { x = x, baseX = x, y = -10, t = 0, lastCy = -99 }
end

local function spawnSpider()
    -- never drops in right on top of the player
    local px = G.player.x
    local fromLeft
    if px > C.SCREEN_W * 0.67 then
        fromLeft = true
    elseif px < C.SCREEN_W * 0.33 then
        fromLeft = false
    else
        fromLeft = math.random(2) == 1
    end
    G.spider = {
        x = fromLeft and -10 or C.SCREEN_W + 10,
        y = (C.ZONE_ROW + 1.5) * C.CELL,
        dx = fromLeft and 1 or -1,
        dy = math.random(2) == 1 and 1 or -1,
        movingX = 1,
    }
end

function Flyers.update()
    if not G.bee and math.random() < C.BEE_CHANCE then spawnBee() end
    if not G.fly and math.random() < C.FLY_CHANCE then spawnFly() end
    if not G.spider and math.random() < C.SPIDER_CHANCE then spawnSpider() end

    local bee = G.bee
    if bee then
        bee.t = bee.t + C.DT
        bee.x = bee.x + bee.dx * 90 * C.DT
        bee.y = bee.baseY + math.sin(bee.t * 6) * 10
        local cx, cy = Grid.cellAt(bee.x, bee.y)
        if cx ~= bee.lastCx then
            bee.lastCx = cx
            Grid.damage(cx, cy, 1)
        end
        if bee.x < -12 or bee.x > C.SCREEN_W + 12 then G.bee = nil end
    end

    local fly = G.fly
    if fly then
        fly.t = fly.t + C.DT
        fly.y = fly.y + 130 * C.DT
        fly.x = fly.baseX + math.sin(fly.t * 5) * 4
        local cx, cy = Grid.cellAt(fly.x, fly.y)
        if cy ~= fly.lastCy then
            fly.lastCy = cy
            if cy >= 1 and cy <= C.ROWS - 3 and not Grid.get(cx, cy)
                and not Player.overlapsCell(cx, cy) and math.random() < 0.3 then
                Grid.set(cx, cy, C.ROCK_HP)
                Sfx.rockDrop()
            end
        end
        if fly.y > C.SCREEN_H + 12 then G.fly = nil end
    end

    local sp = G.spider
    if sp then
        -- zigzags: sometimes drifting sideways, sometimes plunging straight
        sp.x = sp.x + sp.dx * sp.movingX * (3 - math.abs(sp.dy)) * 38 * C.DT
        sp.y = sp.y + sp.dy * (3 - math.abs(sp.dx * sp.movingX)) * 38 * C.DT
        if sp.y < C.ZONE_ROW * C.CELL + 6 or sp.y > C.SCREEN_H - 8 then
            sp.dy = -sp.dy
            sp.movingX = math.random(0, 1)
        end
        local cx, cy = Grid.cellAt(sp.x, sp.y)
        Grid.damage(cx, cy, 99) -- eats any rock it scuttles over
        if sp.x < -12 or sp.x > C.SCREEN_W + 12 then G.spider = nil end
    end
end

local POINTS <const> = { bee = 20, fly = 30, spider = 40 }

local function kill(kind, e)
    local pts = POINTS[kind]
    G[kind] = nil
    G.addScore(pts)
    G.burst(e.x, e.y, 8)
    G.addExplosion(e.x, e.y, 2)
    G.addPopup(e.x, e.y, tostring(pts))
    Sfx.flyerDie()
    Harness.count("flyersKilled")
end

function Flyers.hitAt(x, y)
    for kind in pairs(POINTS) do
        local e = G[kind]
        if e and math.abs(e.x - x) < 8 and math.abs(e.y - y) < 8 then
            kill(kind, e)
            return true
        end
    end
    return false
end

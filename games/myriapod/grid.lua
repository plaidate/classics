-- The rock field: cell math, damage, and between-wave top-ups.

Grid = {}

function Grid.cellPos(cx, cy)
    return cx * C.CELL + C.CELL / 2, cy * C.CELL + C.CELL / 2
end

function Grid.cellAt(x, y)
    return math.floor(x / C.CELL), math.floor(y / C.CELL)
end

function Grid.inBounds(cx, cy)
    return cx >= 0 and cx < C.COLS and cy >= 0 and cy < C.ROWS
end

function Grid.get(cx, cy)
    local row = G.rocks[cy]
    return row and row[cx]
end

function Grid.set(cx, cy, hp)
    G.rocks[cy] = G.rocks[cy] or {}
    G.rocks[cy][cx] = hp
end

-- returns whether a rock was there at all
function Grid.damage(cx, cy, amount, fromBullet)
    if not Grid.inBounds(cx, cy) then return false end
    local hp = Grid.get(cx, cy)
    if not hp then return false end
    if hp <= amount then
        G.rocks[cy][cx] = nil
        local x, y = Grid.cellPos(cx, cy)
        G.burst(x, y, 5)
        G.addExplosion(x, y, 0)
        Sfx.rockBreak()
        Harness.count("rocksDestroyed")
    else
        G.rocks[cy][cx] = hp - amount
        if fromBullet then
            local x, y = Grid.cellPos(cx, cy)
            G.addExplosion(x, y, 0)
            Sfx.rockHit()
        end
    end
    return true
end

function Grid.forEach(fn)
    for cy = 0, C.ROWS - 1 do
        local row = G.rocks[cy]
        if row then
            for cx = 0, C.COLS - 1 do
                if row[cx] then fn(cx, cy, row[cx]) end
            end
        end
    end
end

function Grid.count()
    local n = 0
    Grid.forEach(function() n = n + 1 end)
    return n
end

-- one rock per call, sprinkled while the next wave gathers;
-- the bottom two rows stay clear
function Grid.addRandomRock()
    for _ = 1, 20 do
        local cx = math.random(0, C.COLS - 1)
        local cy = math.random(1, C.ROWS - 3)
        if not Grid.get(cx, cy) and not Player.overlapsCell(cx, cy) then
            Grid.set(cx, cy, C.ROCK_HP)
            return
        end
    end
end

-- any rock cell overlapping the box centered at (x, y)?
function Grid.blocked(x, y, hw, hh)
    local x0, y0 = Grid.cellAt(x - hw, y - hh)
    local x1, y1 = Grid.cellAt(x + hw, y + hh)
    for cy = y0, y1 do
        for cx = x0, x1 do
            if Grid.get(cx, cy) then return true end
        end
    end
    return false
end

function Grid.clearArea(x, y, hw, hh)
    local x0, y0 = Grid.cellAt(x - hw, y - hh)
    local x1, y1 = Grid.cellAt(x + hw, y + hh)
    for cy = y0, y1 do
        for cx = x0, x1 do
            Grid.damage(cx, cy, 99)
        end
    end
end

-- The endless world: band generation, movers (cars, logs, trains),
-- hedges, and what happens when you stand somewhere.

Rows = {}

local pick = Util.pick

local function carSpeed()
    local boost = math.min(C.CAR_SPEED_CAP - C.CAR_SPEED_MAX, G.score * C.CAR_SPEED_RAMP)
    return C.CAR_SPEED_MIN + math.random() * (C.CAR_SPEED_MAX - C.CAR_SPEED_MIN) + boost
end

local function spawnInterval(row)
    return row.spacing * (1 + math.random()) / math.abs(row.dx)
end

local function populate(row, gapMin, gapVar)
    local x = -C.SPAWN_PAD + math.random(40)
    while x < C.SCREEN_W + C.SPAWN_PAD do
        local w = pick(row.widths)
        x = x + gapMin + math.random() * gapVar + w / 2
        -- art picks the car drawing variant; ignored for logs
        row.things[#row.things + 1] = {
            x = x, w = w, long = w == row.widths[2], art = math.random(0, 3),
        }
        x = x + w / 2
    end
end

-- one blocked/clear flag per column; always at least one gap, gaps 3 wide
local function hedgeMask()
    local gap = {}
    for i = 1, C.COLS do gap[i] = math.random() < 0.04 end
    gap[math.random(C.COLS)] = true
    local blocked = {}
    for i = 1, C.COLS do
        blocked[i] = not (gap[i - 1] or gap[i] or gap[i + 1])
    end
    return blocked
end

local function newRow(kind, idx, runLen, prev)
    local row = {
        kind = kind, idx = idx, runLen = runLen,
        y = prev and (prev.y - C.ROW_H) or -C.ROW_H,
        dx = 0, things = {}, splats = {},
    }
    if kind == "road" then
        row.dx = pick({ -1, 1 }) * carSpeed()
        row.widths, row.spacing = C.CAR_W, C.CAR_SPACING
        populate(row, C.CAR_GAP, C.CAR_GAP_VAR)
        row.spawnT = spawnInterval(row)
    elseif kind == "water" then
        local dir = (prev and prev.kind == "water") and (prev.dx > 0 and -1 or 1) or pick({ -1, 1 })
        row.dx = dir * (C.LOG_SPEED_MIN + math.random() * (C.LOG_SPEED_MAX - C.LOG_SPEED_MIN))
        row.widths, row.spacing = C.LOG_W, C.LOG_SPACING
        populate(row, C.LOG_GAP, C.LOG_GAP_VAR)
        row.spawnT = spawnInterval(row)
    elseif kind == "grass" and row.y < -C.SCREEN_H then
        -- hedges come in pairs of rows and never trap the starting screen
        if prev and prev.kind == "grass" and prev.hedge and prev.hedgeRow == 1 then
            row.hedge, row.hedgeRow = prev.hedge, 2
        elseif idx >= 2 and idx < runLen and not (prev and prev.hedge) and math.random() < 0.4 then
            row.hedge, row.hedgeRow = hedgeMask(), 1
        end
    end
    return row
end

local function nextRow(prev)
    if prev.idx < prev.runLen then
        return newRow(prev.kind, prev.idx + 1, prev.runLen, prev)
    end
    local k = prev.kind
    if k == "grass" or k == "dirt" then
        if math.random() < 0.5 then return newRow("road", 1, math.random(1, 5), prev) end
        return newRow("water", 1, math.random(2, 6), prev)
    elseif k == "road" then
        local r = math.random()
        if r < 0.6 then return newRow("grass", 1, math.random(2, 6), prev) end
        if r < 0.9 then return newRow("rail", 1, 3, prev) end
        return newRow("pavement", 1, 3, prev)
    elseif k == "pavement" then
        return newRow("road", 1, math.random(1, 5), prev)
    elseif k == "rail" then
        if math.random() < 0.5 then return newRow("road", 1, math.random(1, 5), prev) end
        return newRow("water", 1, math.random(2, 6), prev)
    else -- water gives way to a dirt bank
        return newRow("dirt", 1, math.random(1, 3), prev)
    end
end

function Rows.reset()
    G.rows = { newRow("grass", 1, 9, nil) }
    while G.rows[#G.rows].y > G.camY - C.ROW_H do
        G.rows[#G.rows + 1] = nextRow(G.rows[#G.rows])
    end
end

function Rows.at(y)
    for _, row in ipairs(G.rows) do
        if math.abs(row.y - y) < 1 then return row end
    end
    return nil
end

function Rows.allowMovement(row, x)
    if x < C.EDGE_PAD or x > C.SCREEN_W - C.EDGE_PAD then return false end
    if row.hedge then
        local col = Util.clamp(math.floor(x / C.CELL_W) + 1, 1, C.COLS)
        if row.hedge[col] then return false end
    end
    return true
end

function Rows.logUnder(row, x)
    for _, t in ipairs(row.things) do
        if math.abs(x - t.x) < t.w / 2 - 4 then return true end
    end
    return false
end

function Rows.standCheck(row, x)
    if row.kind == "road" or (row.kind == "rail" and row.idx == 2) then
        for _, t in ipairs(row.things) do
            if math.abs(x - t.x) < t.w / 2 + 2 then return "squash" end
        end
    elseif row.kind == "water" then
        if not Rows.logUnder(row, x) then return "drown" end
    end
    return "ok"
end

local function updateMovers(row)
    for _, t in ipairs(row.things) do
        t.x = t.x + (t.dx or row.dx) * C.DT
    end
    local pad = row.kind == "rail" and C.TRAIN_W or C.SPAWN_PAD + 40
    for i = #row.things, 1, -1 do
        local t = row.things[i]
        if t.x < -pad or t.x > C.SCREEN_W + pad then table.remove(row.things, i) end
    end
end

local function updateHorns(row)
    local p = G.player
    if not p or p.state ~= "alive" or math.abs(row.y - p.y) > 1 then return end
    if G.frame - G.lastHorn < 45 then return end
    for _, c in ipairs(row.things) do
        local d = c.x - p.x
        if not c.honked and math.abs(d) < 110 and (d > 0) ~= (row.dx > 0) then
            c.honked = true
            G.lastHorn = G.frame
            Sfx.horn()
            return
        end
    end
end

local function updateRail(row)
    if row.idx ~= 2 then return end
    updateMovers(row)
    if row.warnT then
        row.warnT = row.warnT - C.DT
        if row.warnT <= 0 then
            row.warnT = nil
            local dx = row.trainDir * C.TRAIN_SPEED
            row.things[1] = {
                x = dx > 0 and -C.TRAIN_W / 2 - 20 or C.SCREEN_W + C.TRAIN_W / 2 + 20,
                w = C.TRAIN_W, dx = dx, train = true, art = math.random(0, 2),
            }
            Sfx.train()
        end
    else
        local sy = row.y - G.camY
        if sy > -C.ROW_H and sy < C.SCREEN_H and #row.things == 0
            and math.random() < C.TRAIN_CHANCE then
            row.warnT = C.TRAIN_WARN
            row.trainDir = pick({ -1, 1 })
            Sfx.bell()
        end
    end
end

function Rows.update()
    while G.rows[1] and G.rows[1].y - G.camY > C.SCREEN_H + C.ROW_H do
        table.remove(G.rows, 1)
    end
    while G.rows[#G.rows].y > G.camY - C.ROW_H do
        G.rows[#G.rows + 1] = nextRow(G.rows[#G.rows])
    end

    for _, row in ipairs(G.rows) do
        if row.kind == "road" or row.kind == "water" then
            updateMovers(row)
            row.spawnT = row.spawnT - C.DT
            if row.spawnT <= 0 then
                local w = pick(row.widths)
                row.things[#row.things + 1] = {
                    x = row.dx > 0 and -C.SPAWN_PAD or C.SCREEN_W + C.SPAWN_PAD,
                    w = w, long = w == row.widths[2], art = math.random(0, 3),
                }
                row.spawnT = spawnInterval(row)
            end
            if row.kind == "road" then updateHorns(row) end
        elseif row.kind == "rail" then
            updateRail(row)
        end
    end
end

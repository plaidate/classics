-- Grid layouts and tile collision. The playfield is 25x14 tiles of 16px; the
-- bottom row is a copy of the top layout row, so falling off the bottom wraps
-- to the top. Row 0 is drawn but never solid (it is the wrap shadow of the
-- floor, and robots drop in through its gaps).

Level = {}

Level.LAYOUTS = {
    {
        "XXXX     XXXXXXX     XXXX",
        "", "", "",
        "  XXXXXX         XXXXXX  ",
        "", "",
        "  XXXXXXXXXXXXXXXXXXXXX  ",
        "", "",
        "XXXXXXXX         XXXXXXXX",
        "", "", "",
    },
    {
        "XXX    XXXXXXXXXXX    XXX",
        "", "", "",
        "   XXXXXXXXXXXXXXXXXXX   ",
        "", "",
        "XXXXXX             XXXXXX",
        "      X           X      ",
        "       X         X       ",
        "        X       X        ",
        "", "", "",
    },
    {
        "XXXX   XXXX   XXXX   XXXX",
        "", "", "",
        " XXXXXXX         XXXXXXX ",
        "", "",
        "XXXX     XXXXXXX     XXXX",
        "", "",
        "   XXXXXX       XXXXXX   ",
        "", "", "",
    },
    {
        "XXXXX   XXXXXXXXX   XXXXX",
        "", "", "",
        "XXXXXXXX         XXXXXXXX",
        "", "",
        "     XXXXXXXXXXXXXXX     ",
        "", "",
        "  XXXXX    XXX    XXXXX  ",
        "", "", "",
    },
}

function Level.load(idx)
    local rows = Level.LAYOUTS[idx]
    G.grid = {}
    for i = 1, 14 do
        local row = rows[i]
        assert(#row == 0 or #row == C.COLS, "bad layout row length")
        G.grid[i] = row
    end
    G.grid[15] = rows[1] -- the floor wraps to the top row
end

function Level.solid(x, y)
    local gy = math.floor(y / C.TILE)
    if gy < 1 or gy > 14 then return false end
    local gx = math.floor(x / C.TILE)
    if gx < 0 or gx >= C.COLS then return false end
    local row = G.grid[gy + 1]
    if #row == 0 then return false end
    return row:sub(gx + 1, gx + 1) ~= " "
end

-- random top-row gap where a robot can drop in
function Level.spawnX()
    local start = math.random(0, C.COLS - 1)
    local row = G.grid[1]
    for i = 0, C.COLS - 1 do
        local gx = (start + i) % C.COLS
        if #row == 0 or row:sub(gx + 1, gx + 1) == " " then
            return gx * C.TILE + 8
        end
    end
    return C.SCREEN_W / 2
end

-- horizontal movement in 1px steps; a is feet-anchored. Returns true if blocked.
function Level.moveX(a, dir, dist, halfW)
    local left = dist
    while left > 0 do
        local step = math.min(1, left)
        local nx = a.x + dir * step
        if nx < 6 or nx > C.SCREEN_W - 6 then return true end
        local lead = nx + dir * halfW
        if Level.solid(lead, a.y - 2) or Level.solid(lead, a.y - 13) then return true end
        a.x = nx
        left = left - step
    end
    return false
end

-- gravity plus one-way landing; rising never collides (jump-through platforms)
function Level.fall(a, halfW)
    a.vy = math.min(a.vy + C.GRAVITY * C.DT, C.MAX_FALL)
    local dy = a.vy * C.DT
    if dy <= 0 then
        a.y = a.y + dy
        if dy < 0 then a.landed = false end
        return
    end
    local target = a.y + dy
    local b = math.ceil(a.y / C.TILE) * C.TILE
    while b <= target do
        if Level.solid(a.x - halfW, b + 1) or Level.solid(a.x + halfW, b + 1) then
            a.y = b
            a.vy = 0
            a.landed = true
            return
        end
        b = b + C.TILE
    end
    a.y = target
    a.landed = false
end

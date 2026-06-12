-- Original single-screen layouts (25x16px columns by 15 rows) plus grid
-- collision. Cell legend:
--   X  platform (one-way: you land on its top, nothing blocks sideways)
--   H  platform cell a ladder passes through (solid top AND climbable)
--   L  ladder
-- Markers (replaced by spaces on load): P player start, D exit door,
-- g gem, e walker, E walker from cycle 2 on, f flyer, F flyer from cycle 2.
-- An entity marker's feet sit on the bottom edge of its cell, so markers go
-- in the row directly above a platform row.

Level = {}

Level.LAYOUTS = {
    {
        biome = "forest",
        rows = {
            "                         ",
            "                         ",
            "            f            ",
            "                         ",
            "         g       g       ",
            "      XXXXXXHXXXXXXX     ",
            "            L            ",
            "  g         L        g   ",
            " XXXXXHXXXXXXXXXXXXHXXXX ",
            "      L            L     ",
            "      L     D      L  E  ",
            " XXXHXXXXXXXXXXXXXXXHXXX ",
            "    L               L    ",
            " P  L      e        L    ",
            "XXXXXXXXXXXXXXXXXXXXXXXXX",
        },
    },
    {
        biome = "forest",
        rows = {
            "                         ",
            "    g               g    ",
            "  XXXXXHXX     XXHXXXXX  ",
            "       L         L       ",
            "       L    f    L       ",
            "    XXXXXXXHXXXXXXXX     ",
            "  g        L         g   ",
            "           L            F",
            " XXXXHXXXXXXXXXXXXXHXXX  ",
            "     L             L     ",
            "     L   E   D     L     ",
            "  XXXXXXHXXXXXXXXXHXXXX  ",
            "        L         L      ",
            "   P    L    e    L    g ",
            "XXXXXXXXXXXXXXXXXXXXXXXXX",
        },
    },
    {
        biome = "forest",
        rows = {
            "                         ",
            "     g          g        ",
            "   XXXHXXXXXXXXXHXXXX    ",
            "      L         L        ",
            "      L    F    L        ",
            "   XXXXXXHXXXXXXXXXX     ",
            "         L        g      ",
            "  g      L               ",
            "  XXXXXXXXXXXHXXXXXXXX   ",
            "             L      f    ",
            "   D  E      L           ",
            " XXXHXXXXXXXXXXXXXXHXXXX ",
            "    L               L    ",
            "    L     P   g     L  e ",
            "XXXXXXXXXXXXXXXXXXXXXXXXX",
        },
    },
    {
        biome = "castle",
        rows = {
            "                         ",
            "         g     g         ",
            "       XXXXHXXXXXX       ",
            "           L       f     ",
            "  g        L         g   ",
            " XXXXXHXX  L   XXHXXXXX  ",
            "      L    L     L       ",
            "      L    L  g  L       ",
            "  XXXXXHXXXXXXXXHXXXXX   ",
            "   F   L        L        ",
            "   E   L    D   L     g  ",
            "  XXXXXXXXXHXXXXXXXXXXX  ",
            "           L             ",
            "     P     L       e     ",
            "XXXXXXXXXXXXXXXXXXXXXXXXX",
        },
    },
    {
        biome = "castle",
        rows = {
            "                         ",
            "  g                   g  ",
            " XXXHXX             XXHXX",
            "    L                 L  ",
            "    L        f        L  ",
            "  XXXXXHXXXXXXXXXHXXXXX  ",
            "       L         L       ",
            "   g   L    g    L   g   ",
            " XXXXXXXXXHXXXXXXXXXXXX  ",
            "          L             F",
            "  E       L        D     ",
            " XXXHXXXXXXXXXXXXXXXHXXX ",
            "    L                L   ",
            "    L   e     P      L   ",
            "XXXXXXXXXXXXXXXXXXXXXXXXX",
        },
    },
    {
        biome = "castle",
        rows = {
            "                         ",
            "      g     D     g      ",
            "  XXXXHXXXXXXXXXXXHXXXX  ",
            "      L           L      ",
            "  g   L     F     L   g  ",
            " XXXXXXXXXHXXXXXXXXXXXX  ",
            "          L         f    ",
            "          L  g           ",
            "   XXXXXXXXXXXXXHXXXXXX  ",
            "                L        ",
            "   g    E       L        ",
            "  XXXXXXXXXXHXXXXXXXXX   ",
            "            L            ",
            "   P        L     e      ",
            "XXXXXXXXXXXXXXXXXXXXXXXXX",
        },
    },
}

local nextGemType = 1

function Level.newGame()
    nextGemType = 1
end

-- parse layout idx into G.grid plus entity lists; cycle gates E/F enemies
function Level.load(idx, cycle)
    local layout = Level.LAYOUTS[idx]
    G.biome = layout.biome
    G.grid = {}
    G.gems, G.enemies, G.fx, G.ladders = {}, {}, {}, {}
    G.door = nil
    G.exitOpen = false

    for r = 1, C.ROWS do
        local row = layout.rows[r]
        assert(#row == C.COLS, "bad layout row length: " .. idx .. "/" .. r)
        local clean = {}
        for c = 1, C.COLS do
            local ch = row:sub(c, c)
            local x = (c - 1) * C.TILE + C.TILE // 2
            local footY = r * C.TILE
            if ch == "X" or ch == "L" or ch == "H" then
                clean[c] = ch
            else
                clean[c] = " "
                if ch == "P" then
                    G.startX, G.startY = x, footY
                elseif ch == "D" then
                    G.door = { x = x, y = footY, frame = 0,
                               variant = (G.level - 1) % 5 }
                elseif ch == "g" then
                    G.gems[#G.gems + 1] = { x = x, y = footY, type = nextGemType }
                    nextGemType = nextGemType % 4 + 1
                elseif ch == "e" or (ch == "E" and cycle >= 1) then
                    Enemies.addWalker(x, footY)
                elseif ch == "f" or (ch == "F" and cycle >= 1) then
                    Enemies.addFlyer(x, footY - C.TILE // 2, cycle)
                end
            end
        end
        G.grid[r] = table.concat(clean)
    end

    Level.findLadders()
end

-- record each ladder column's top/bottom feet heights for the autopilot
function Level.findLadders()
    for c = 1, C.COLS do
        local r = 1
        while r <= C.ROWS do
            local ch = G.grid[r]:sub(c, c)
            if ch == "H" or ch == "L" then
                local top = r
                while r <= C.ROWS and (G.grid[r]:sub(c, c) == "H" or G.grid[r]:sub(c, c) == "L") do
                    r = r + 1
                end
                G.ladders[#G.ladders + 1] = {
                    x = (c - 1) * C.TILE + C.TILE // 2,
                    top = (top - 1) * C.TILE,
                    bot = (r - 1) * C.TILE,
                }
            else
                r = r + 1
            end
        end
    end
end

function Level.cell(x, y)
    local c = math.floor(x / C.TILE) + 1
    local r = math.floor(y / C.TILE) + 1
    if c < 1 or c > C.COLS or r < 1 or r > C.ROWS then return " " end
    return G.grid[r]:sub(c, c)
end

function Level.solid(x, y)
    local ch = Level.cell(x, y)
    return ch == "X" or ch == "H"
end

function Level.ladder(x, y)
    local ch = Level.cell(x, y)
    return ch == "L" or ch == "H"
end

-- find a ladder column near x at height y; returns its center x or nil
function Level.ladderGrab(x, y)
    for _, off in ipairs({ 0, -C.LADDER_GRAB_RANGE, C.LADDER_GRAB_RANGE }) do
        if Level.ladder(x + off, y) then
            local cx = math.floor((x + off) / C.TILE) * C.TILE + C.TILE // 2
            if math.abs(cx - x) <= C.LADDER_GRAB_RANGE then
                return cx
            end
        end
    end
    return nil
end

-- gravity with one-way landings: a falls from a.y by a.vy, stopping at the
-- first tile top that has support under either foot. a needs x/y/vy/landed.
function Level.fall(a, halfW)
    local dy = a.vy
    if dy < 0 then
        a.y = a.y + dy
        a.landed = false
        if a.y < 14 then
            a.y = 14
            a.vy = 0
        end
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

-- Brick layouts. Each string is the left half of a row plus its centre
-- column; the right half is mirrored from it. Hex digit = brick style,
-- "c" is armored (two hits), "d" is metal (unbreakable), space is empty.

Levels = {}

local LAYOUTS <const> = {
    { -- 1: warm-up slab
        "  111111",
        "  333333",
        "  555555",
        "  777777",
        "  999999",
    },
    { -- 2: the vault, with metal pegs below
        "   ccccc",
        "   c3333",
        "   c3113",
        "   c3333",
        "   ccccc",
        "        ",
        " d     d",
    },
    { -- 3: armored lid over a chevron
        "c c c c ",
        "        ",
        "00      ",
        " 11     ",
        "  22    ",
        "   33   ",
        "    44  ",
        "     55 ",
        "      66",
    },
    { -- 4: metal colonnade
        "  888888",
        "        ",
        " d 9 d 9",
        " d 9 d 9",
        " d 9 d 9",
        "        ",
        "  aaaaaa",
    },
    { -- 5: honeycomb weave
        " c c c c",
        "1 1 1 1 ",
        " c c c c",
        "2 2 2 2 ",
        " c c c c",
        "3 3 3 3 ",
    },
    { -- 6: the reactor core
        " dd   dd",
        "  c777c ",
        "  c777c ",
        "  c777c ",
        " dd   dd",
        "        ",
        "    bbb ",
    },
}

-- Fills G.bricks/G.rows/G.bricksLeft for level n (wraps past the last one).
function Levels.build(n)
    local layout = LAYOUTS[(n - 1) % #LAYOUTS + 1]
    G.bricks = {}
    G.rows = #layout
    G.bricksLeft = 0
    for r, half in ipairs(layout) do
        local row = {}
        for c = 1, C.GRID_COLS do
            -- columns 1..8 read straight off; 9..15 mirror columns 7..1
            local i = (c <= 8) and c or (16 - c)
            local id = tonumber(half:sub(i, i), 16)
            row[c] = id or false
            if id and id ~= 13 then
                G.bricksLeft = G.bricksLeft + 1
            end
        end
        G.bricks[r] = row
    end
end

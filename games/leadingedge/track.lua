-- The circuit. Stored as parallel arrays of per-piece X/Y offsets (how
-- the road line shifts relative to the previous piece) plus sparse
-- tables for rival speed hints, scenery and the start/finish line.
-- Built once at startup; the layout repeats for NUM_LAPS + 1 laps so
-- cars never run out of road right after the finish.

Track = {
    ox = {}, oy = {}, -- per-piece offsets from the previous piece
    maxSpd = {},      -- sparse: rivals aim below roughly this speed here
    scen = {},        -- sparse: list of scenery objects on this piece
    line = {},        -- sparse: true where the start/finish gantry sits
    count = 0,
}

local VERY_SHORT <const> = 25
local SHORT <const> = 50
local MEDIUM <const> = 100
local LONG <const> = 200

-- The gantry's image is picked at draw time from the countdown.
local gantry = {
    x = 0, dynamic = true, scale = 4,
    minD = 1, maxD = C.VIEW,
    zones = { { -1500, -1200 }, { 1200, 1500 } },
}
local gantryList = { gantry }

local lampPair = nil
local bbPairs = {}

local function billboardPair(img)
    local pair = bbPairs[img]
    if not pair then
        local w = Img.size(img)
        pair = {
            { x = C.BILLBOARD_X, img = img, scale = 2, maxD = C.VIEW // 2, zones = { { -w, w } } },
            { x = -C.BILLBOARD_X, img = img, scale = 2, maxD = C.VIEW // 2, zones = { { -w, w } } },
        }
        bbPairs[img] = pair
    end
    return pair
end

-- Returns a function mapping a piece's index within its section to its
-- scenery: billboards every `interval` pieces, lamps every 30.
local function scenery(img, interval, lamps)
    img = img or "billboard00"
    interval = interval or 40
    if lamps == nil then lamps = true end
    return function(i)
        if i % interval == 0 then
            return billboardPair(img)
        elseif lamps and i % 30 == 0 then
            return lampPair
        end
        return nil
    end
end

local function addOne(ox, oy, scen, maxSpd)
    local k = Track.count + 1
    Track.ox[k] = ox
    Track.oy[k] = oy
    if scen then Track.scen[k] = scen end
    if maxSpd then Track.maxSpd[k] = maxSpd end
    Track.count = k
end

local function add(n, ox, oy, scenFn, maxSpd)
    for i = 0, n - 1 do
        addOne(ox or 0, oy or 0, scenFn and scenFn(i) or nil, maxSpd)
    end
end

function Track.build()
    lampPair = {
        { x = C.LAMP_X, img = "left_light", scale = 2, maxD = C.VIEW // 2, zones = { { 175, 600 } } },
        { x = -C.LAMP_X, img = "right_light", scale = 2, maxD = C.VIEW // 2, zones = { { -600, -175 } } },
    }
    for _ = 1, C.NUM_LAPS + 1 do
        add(15, 0, 0, scenery("billboard02"))

        addOne(0, 0, gantryList)                            -- start/finish line
        Track.line[Track.count] = true

        add(SHORT)
        add(MEDIUM, -2, 0, scenery())                       -- gentle right
        add(SHORT, 0, 0, scenery("billboard01"))

        add(VERY_SHORT, 0, -0.5, scenery())                 -- dip...
        add(VERY_SHORT, 0, -1, scenery())
        add(VERY_SHORT, -1, -0.5, scenery())                -- ...into a right-hander
        add(VERY_SHORT, -2.5, 0, scenery("billboard03"))
        add(MEDIUM, -5, 0, scenery("billboard03"))

        add(SHORT, 0, 0, scenery())
        add(MEDIUM, 6.5, 0.5, scenery("arrow_left", 10))    -- climbing left turn
        add(MEDIUM, 0, 0, scenery("billboard02"))
        add(MEDIUM, 0, 1, scenery("billboard02"))           -- small hill
        add(LONG, -1.5, -0.5, scenery("billboard01"))       -- drifting right and down
        add(MEDIUM, 0, -2, scenery())                       -- steep drop
        add(LONG, 0, 1, scenery("billboard03"))             -- long climb

        for j = 1, 9 do                                     -- tightening climb to the left
            add(VERY_SHORT, j / 2, j / 2, scenery())
        end
        for j = 1, 9 do                                     -- rollercoaster descent
            add(VERY_SHORT, 0, -j / 2, scenery())
        end

        add(MEDIUM, 0, 0, nil, 60)                          -- rivals ease off before...
        add(SHORT, 0, 0, scenery("arrow_right", 10, false), 58)
        add(SHORT, 0, 0, scenery("arrow_right", 10, false), 58)
        add(SHORT, -7.5, 0, scenery("arrow_right", 10, false), 55) -- ...the big right
        add(SHORT, -6.5, 0, scenery("arrow_right", 10, false), 57)
        add(SHORT, -5.5, 0, scenery())
        add(SHORT, -4.5, 0, scenery())

        add(MEDIUM, 0, 0, scenery())
        local hillScen = scenery()
        for i = 0, LONG - 1 do                              -- rolling hills
            addOne(0, math.cos(i / 20) * 2.5, hillScen(i))
        end
        add(LONG, 0, 0.125, scenery("billboard03"))         -- shallow rise resets the skyline
        add(SHORT, 0, 0, scenery("billboard03"))
    end
end

-- 0-based index of the piece containing z (pieces span [-i-1, -i)).
function Track.idxForZ(z)
    local idx = math.floor(-z)
    if idx < 0 or idx >= Track.count then return nil end
    return idx
end

-- 0-based index and Z of the first piece at or ahead of z.
function Track.aheadIdx(z)
    local idx = math.ceil(-z)
    if idx >= Track.count then return nil end
    return idx, -idx
end

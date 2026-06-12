-- Real 1-bit art, converted at half scale from the original Infinite
-- Bunner assets. Everything loads once at startup; row strips are
-- composited into full-width band images sized to the 24px logic bands.

local gfx <const> = playdate.graphics

Sprites = {}

local function load(name)
    local img = gfx.image.new("images/" .. name)
    assert(img, "missing image: images/" .. name)
    return img
end

local function crop(img, x, y, w, h)
    local out = gfx.image.new(w, h)
    gfx.lockFocus(out)
    img:draw(-x, -y)
    gfx.unlockFocus()
    return out
end

-- Row strips are 240px wide (full original width at half scale) and 20px
-- tall; the caps that end a section are 30px and overlap the band above.
-- Tile each strip across the 400px screen and stretch 20 -> ROW_H so
-- adjacent bands meet without gaps; caps keep the rest as an overhang,
-- recorded in yoff and drawn above the band top.
local STRIP_H <const> = 20
local bands = {}

local function buildBand(name)
    local strip = load(name)
    local sw, sh = strip:getSize()
    local scale = C.ROW_H / STRIP_H
    local outH = math.floor(sh * scale + 0.5)
    local img = gfx.image.new(C.SCREEN_W, outH)
    gfx.lockFocus(img)
    for x = 0, C.SCREEN_W - 1, sw do
        strip:drawScaled(x, 0, 1, scale)
    end
    gfx.unlockFocus()
    bands[name] = { img = img, yoff = outH - C.ROW_H }
end

-- Map a row to the original strip variants: the first row of a section
-- carries the transition from the band below (grass0-6 leave a road,
-- dirt4-6 leave water), middle rows vary, and the 15-suffix caps close
-- a section off, overhanging the row above.
function Sprites.band(row)
    local n = math.floor(0.5 - row.y / C.ROW_H) -- stable per-row variety
    local k, idx = row.kind, row.idx
    local name
    if k == "grass" then
        if idx == row.runLen then name = "grass15"
        elseif idx == 1 then name = "grass" .. (n % 7)
        else name = "grass" .. (8 + n % 7) end
    elseif k == "dirt" then
        if idx == 1 then name = "dirt" .. (4 + n % 3)
        elseif idx == row.runLen then name = "dirt15"
        else name = "dirt" .. (8 + n % 7) end
    elseif k == "road" then
        name = "road" .. math.min(idx - 1, 5)
    elseif k == "water" then
        name = "water" .. math.min(idx - 1, 7)
    elseif k == "rail" then
        name = "rail" .. (idx >= 3 and 3 or idx - 1) -- rail3 is the cap
    else -- pavement
        name = "side" .. math.min(idx - 1, 2)
    end
    return bands[name]
end

function Sprites.build()
    for i = 0, 15 do
        buildBand("grass" .. i)
        buildBand("dirt" .. i)
    end
    for i = 0, 5 do buildBand("road" .. i) end
    for i = 0, 7 do buildBand("water" .. i) end
    for i = 0, 3 do buildBand("rail" .. i) end
    for i = 0, 2 do buildBand("side" .. i) end

    -- original direction indices: 0 up, 1 right, 2 down, 3 left
    Sprites.rabbit, Sprites.splat = {}, {}
    for i, dir in ipairs({ "up", "right", "down", "left" }) do
        local d = i - 1
        Sprites.rabbit[dir] = { sit = load("sit" .. d), hop = load("jump" .. d) }
        Sprites.splat[dir] = load("splat" .. d)
    end

    -- vehicle art suffix 0 faces left (dx < 0), suffix 1 faces right
    Sprites.cars = {}
    for t = 0, 3 do
        Sprites.cars[t + 1] = {
            left = load("car" .. t .. "0"),
            right = load("car" .. t .. "1"),
        }
    end

    -- train art is far wider than the logic hitbox; scale it to TRAIN_W
    -- so what you see is roughly what can hit you
    Sprites.trains = {}
    for t = 0, 2 do
        local l = load("train" .. t .. "0")
        local s = C.TRAIN_W / l:getSize()
        Sprites.trains[t + 1] = {
            left = l:scaledImage(s),
            right = load("train" .. t .. "1"):scaledImage(s),
        }
    end

    Sprites.logSmall = load("log0")
    Sprites.logLong = load("log1")

    -- bush tiles: x = 0 single, 1 left end, 2 right end, 3/4/5 middles;
    -- second digit 0 = lower row, 1 = upper row (taller, overhangs).
    -- Stretch vertically like the strips so the two rows meet cleanly.
    Sprites.bush = {}
    for x = 0, 5 do
        Sprites.bush[x] = {
            load("bush" .. x .. "0"):scaledImage(1, C.ROW_H / STRIP_H),
            load("bush" .. x .. "1"):scaledImage(1, C.ROW_H / STRIP_H),
        }
    end

    Sprites.splash = {}
    for i = 0, 7 do Sprites.splash[i + 1] = load("splash" .. i) end

    Sprites.eagle = load("eagle")

    -- digit images: first digit 0 = score colour, 1 = high-score colour
    Sprites.digits = { [0] = {}, [1] = {} }
    for c = 0, 1 do
        for d = 0, 9 do Sprites.digits[c][d] = load("digit" .. c .. d) end
    end

    -- the title and game-over screens are portrait 240x400 paintings;
    -- crop the artwork block out of the middle for our landscape screen
    Sprites.title = crop(load("title"), 0, 80, 240, 176)
    Sprites.gameover = crop(load("gameover"), 0, 80, 240, 240)
end

-- Real artwork: 1-bit conversions of the Cavern sprites at half scale,
-- loaded once from images/ at startup. Anchoring matches the old procedural
-- art: figures draw feet-anchored, orbs/bolts/pops draw centered, so all
-- collision geometry is untouched. Where the art has separate left/right
-- frames the tables are keyed by facing (-1 left, 1 right).

local gfx <const> = playdate.graphics

Sprites = {}

local function img(name)
    local i = gfx.image.new("images/" .. name)
    assert(i, "missing image: " .. name)
    return i
end

function Sprites.build()
    -- player: still, run (4 frames per direction), blow, recoil, fall
    Sprites.still = img("still")
    Sprites.run = { [-1] = {}, [1] = {} }
    for f = 0, 3 do
        Sprites.run[-1][f] = img("run0" .. f)
        Sprites.run[1][f] = img("run1" .. f)
    end
    Sprites.blow = { [-1] = img("blow0"), [1] = img("blow1") }
    Sprites.recoil = { [-1] = img("recoil0"), [1] = img("recoil1") }
    Sprites.fall = { [0] = img("fall0"), [1] = img("fall1") }

    -- robots: [type][facing][frame]; frames 1-4 walk, 5-7 firing
    Sprites.robot = {}
    for kind = 1, 2 do
        Sprites.robot[kind] = { [-1] = {}, [1] = {} }
        for f = 0, 7 do
            Sprites.robot[kind][-1][f] = img("robot" .. (kind - 1) .. "0" .. f)
            Sprites.robot[kind][1][f] = img("robot" .. (kind - 1) .. "1" .. f)
        end
    end

    -- orbs (0-2 growing, 3-6 idle), orbs with a trapped robot, pops, bolts
    Sprites.orb = {}
    for f = 0, 6 do
        Sprites.orb[f] = img("orb" .. f)
    end
    Sprites.trap = {}
    for kind = 1, 2 do
        Sprites.trap[kind] = {}
        for f = 0, 7 do
            Sprites.trap[kind][f] = img("trap" .. (kind - 1) .. f)
        end
    end
    Sprites.pop = { small = {}, big = {} }
    for f = 0, 5 do
        Sprites.pop.small[f] = img("pop0" .. f)
        Sprites.pop.big[f] = img("pop1" .. f)
    end
    Sprites.bolt = {
        [-1] = { [0] = img("bolt00"), [1] = img("bolt01") },
        [1] = { [0] = img("bolt10"), [1] = img("bolt11") },
    }

    -- fruit: kinds 1-3 score, 4 extra health, 5 extra life; 3 frames each
    Sprites.fruit = {}
    for kind = 1, 5 do
        Sprites.fruit[kind] = {}
        for f = 0, 2 do
            Sprites.fruit[kind][f] = img("fruit" .. (kind - 1) .. f)
        end
    end

    -- per-theme backgrounds, and block art scaled to the 16px collision grid
    Sprites.tiles, Sprites.bg = {}, {}
    for theme = 0, 3 do
        local block = img("block" .. theme)
        local bw = block:getSize()
        local tile = gfx.image.new(C.TILE, C.TILE)
        gfx.lockFocus(tile)
        block:drawScaled(0, 0, C.TILE / bw)
        gfx.unlockFocus()
        Sprites.tiles[theme + 1] = tile
        Sprites.bg[theme + 1] = img("bg" .. theme)
    end

    -- HUD icons and full-screen art
    Sprites.life, Sprites.plus, Sprites.health = img("life"), img("plus"), img("health")
    Sprites.title, Sprites.over = img("title"), img("over")
    Sprites.space = {}
    for f = 0, 9 do
        Sprites.space[f] = img("space" .. f)
    end
end

-- feet-anchored draw (x = center, y = feet)
function Sprites.drawAnchored(img, x, y, flipped)
    local w, h = img:getSize()
    img:draw(x - w / 2, y - h, flipped and gfx.kImageFlippedX or gfx.kImageUnflipped)
end

-- center-anchored draw (orbs, bolts, pops)
function Sprites.drawCentered(img, x, y)
    local w, h = img:getSize()
    img:draw(x - w / 2, y - h / 2)
end

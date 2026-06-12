-- Real 1-bit artwork, loaded once at startup from images/ (converted at
-- half the original scale, matching the 16px grid). Image-name -> state
-- mapping follows the original Myriapod asset naming:
--   seg{fast}{two-hp}{head}{direction}{legframe}  (direction in 45-degree
--     steps, 0 = up; the port's cell-to-cell march only uses 0/2/4/6)
--   rock{colour}{type}{damage}   player{facing}{fireframe}
--   meanie{type}{wingframe}      exp{type}{frame}
-- Everything is drawn centered on the same anchors the procedural art
-- used, so hitboxes are unchanged.

local gfx <const> = playdate.graphics

Sprites = {}

local function load(name)
    local img = gfx.image.new("images/" .. name)
    assert(img, "missing image: images/" .. name)
    return img
end

-- cut a window out of a larger (portrait) sheet
local function crop(name, sx, sy, w, h)
    local src = load(name)
    local img = gfx.image.new(w, h)
    gfx.lockFocus(img)
    src:draw(-sx, -sy)
    gfx.unlockFocus()
    return img
end

-- the converted backgrounds are portrait (240x400); rotate once at startup
-- so they cover the landscape 400x240 screen
local function buildBg(i)
    local src = load("bg" .. i)
    local img = gfx.image.new(C.SCREEN_W, C.SCREEN_H, gfx.kColorBlack)
    gfx.lockFocus(img)
    src:drawRotated(C.SCREEN_W / 2, C.SCREEN_H / 2, 90)
    gfx.unlockFocus()
    return img
end

function Sprites.build()
    -- myriapod segments; the seg11*** set (fast AND two-hp) has no art, and
    -- is never needed: fast waves (wave % 4 == 0) always spawn 1-hp segments
    Sprites.seg = {}
    for f = 0, 1 do
        for h = 0, 1 do
            if not (f == 1 and h == 1) then
                for c = 0, 1 do
                    for d = 0, 6, 2 do
                        for e = 0, 3 do
                            local name = ("seg%d%d%d%d%d"):format(f, h, c, d, e)
                            Sprites.seg[name:sub(4)] = load(name)
                        end
                    end
                end
            end
        end
    end

    -- rocks: colour cycles with the wave, type varies per cell,
    -- damage state 0..2 covers the port's 3 HP levels (the taller
    -- 5-hp totem state 4 is unused: the port has no totem rocks)
    Sprites.rock = {}
    for col = 0, 2 do
        Sprites.rock[col] = {}
        for t = 0, 3 do
            Sprites.rock[col][t] = {}
            for s = 0, 2 do
                Sprites.rock[col][t][s] = load("rock" .. col .. t .. s)
            end
        end
    end

    -- ship: facing 0 = up/down, 1 = NE/SW, 2 = left/right, 3 = SE/NW;
    -- frames 1-2 are the firing recoil
    Sprites.player = {}
    for d = 0, 3 do
        Sprites.player[d] = {}
        for f = 0, 2 do
            Sprites.player[d][f] = load("player" .. d .. f)
        end
    end

    -- the three meanie colour variants stand in for the port's flyers:
    -- 0 -> bee, 1 -> fly, 2 -> spider
    Sprites.meanie = {}
    for t = 0, 2 do
        Sprites.meanie[t] = {}
        for f = 0, 2 do
            Sprites.meanie[t][f] = load("meanie" .. t .. f)
        end
    end

    -- explosions: type 0 = rock puff, 1 = big player blast, 2 = segment/meanie
    Sprites.exp = {}
    for t = 0, 2 do
        Sprites.exp[t] = {}
        for f = 0, 7 do
            Sprites.exp[t][f] = load("exp" .. t .. f)
        end
    end

    Sprites.digit = {}
    for d = 0, 9 do
        Sprites.digit[d] = load("digit" .. d)
    end

    Sprites.bullet = load("bullet")
    Sprites.life = load("life")

    Sprites.bg = { [0] = buildBg(0), buildBg(1), buildBg(2) }

    -- logo band of the portrait title sheet, and the GAME OVER banner
    Sprites.title = crop("title", 0, 110, 240, 148)
    Sprites.over = crop("over", 0, 162, 240, 54)
end

-- quantize the current cell-to-cell direction (1=up 2=right 3=down 4=left)
-- to the sprite sheet's 45-degree direction index
function Sprites.segImg(fast, twoHp, head, dir, frame)
    local f = fast and 1 or 0
    local h = (twoHp and not fast) and 1 or 0
    local c = head and 1 or 0
    return Sprites.seg[("%d%d%d%d%d"):format(f, h, c, (dir - 1) * 2, frame)]
end

function Sprites.rockImg(hp, cx, cy)
    local colour = (math.max(G.wave, 1) - 1) % 3
    local t = (cx * 3 + cy * 5) % 4
    return Sprites.rock[colour][t][math.min(hp, 3) - 1]
end

function Sprites.bgImg()
    return Sprites.bg[(math.max(G.wave, 1) - 1) % 3]
end

function Sprites.drawCentered(img, x, y)
    local w, h = img:getSize()
    img:draw(x - w / 2, y - h / 2)
end

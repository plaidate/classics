-- Image cache. Everything is loaded once at startup; nothing loads mid-game.

local gfx <const> = playdate.graphics

Assets = {}

local HEX <const> = "0123456789abcdef"

-- 0-based value -> lowercase hex character (matches the sprite filenames)
function Assets.hex(n)
    return HEX:sub(n + 1, n + 1)
end

local function img(name)
    local i = gfx.image.new("images/" .. name)
    assert(i, "missing image: images/" .. name)
    return i
end

function Assets.load()
    Assets.arenas = {}
    for i = 0, 6 do Assets.arenas[i] = img("arena" .. i) end
    Assets.titleLogo = img("title")
    Assets.startAnim = {}
    for i = 0, 12 do Assets.startAnim[i] = img("start" .. i) end
    Assets.gameoverAnim = {}
    for i = 0, 14 do Assets.gameoverAnim[i] = img("gameover" .. i) end

    -- bricks: ids 0..11 break in one hit, 12 is armored, 13 is solid metal
    Assets.bricks = {}
    for i = 0, 13 do Assets.bricks[i] = img("brick" .. Assets.hex(i)) end
    Assets.brickShadow = img("bricks")

    Assets.ball = img("ball0")
    Assets.ballShadow = img("balls")

    -- bats: [form][morphFrame]; the normal form (0) has a single frame
    Assets.bats, Assets.batShadows, Assets.batWidths = {}, {}, {}
    for t = 0, 4 do
        Assets.bats[t], Assets.batShadows[t], Assets.batWidths[t] = {}, {}, {}
        for f = 0, (t == 0 and 0 or 3) do
            Assets.bats[t][f] = img("bat" .. t .. f)
            Assets.batShadows[t][f] = img("bats" .. t .. f)
            Assets.batWidths[t][f] = Assets.bats[t][f]:getSize()
        end
    end
    Assets.batGunFlash = img("bat23f")

    -- powerup capsules: [type 0..8][frame 0..9]
    Assets.capsules = {}
    for t = 0, 8 do
        Assets.capsules[t] = {}
        for f = 0, 9 do Assets.capsules[t][f] = img("barrel" .. t .. f) end
    end
    Assets.capsuleShadow = img("barrels")

    -- impact flashes: [type 0..15][frame 0..3]
    Assets.impacts = {}
    for t = 0, 15 do
        Assets.impacts[t] = {}
        for f = 0, 3 do
            Assets.impacts[t][f] = img("impact" .. Assets.hex(t) .. f)
        end
    end

    Assets.bullets = { [0] = img("bullet0"), [1] = img("bullet1") }
    Assets.life = img("life")
    Assets.portalExit = {}
    for f = 0, 3 do Assets.portalExit[f] = img("portal_exit" .. f) end
    Assets.doorLeft = img("portal_meanie00")
    Assets.doorRight = img("portal_meanie10")

    -- the big score digits, shrunk to fit along the arena's top frame
    Assets.digits = {}
    for i = 0, 9 do
        Assets.digits[i] = img("digit" .. i):scaledImage(0.5)
    end
end

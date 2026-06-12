-- Every image and bitmap-font glyph, loaded once at startup.

local gfx <const> = playdate.graphics

Assets = { img = {} }

local glyphs = { font = {}, font_status = {} }

local function load(name)
    local img = gfx.image.new("images/" .. name)
    assert(img, "missing image: " .. name)
    Assets.img[name] = img
end

local function seq(prefix, last)
    for i = 0, last do load(prefix .. i) end
end

local function loadFont(prefix, firstCode, lastCode)
    for code = firstCode, lastCode do
        local img = gfx.image.new(string.format("images/%s%03d", prefix, code))
        assert(img, "missing glyph: " .. prefix .. code)
        glyphs[prefix][string.char(code)] = img
    end
end

function Assets.glyph(font, ch)
    return glyphs[font][ch]
end

function Assets.build()
    load("background")
    load("terrain")
    load("radar")
    load("title")
    load("gameover")
    load("life")
    load("armor")
    load("dot-white")
    load("dot-red")
    load("dot-green")

    seq("appear", 10)
    seq("lander", 2)
    seq("mutant", 3)
    seq("baiter", 7)
    seq("pod", 5)
    seq("swarmer", 7)
    seq("bullet", 1)
    seq("flash", 1)
    seq("token", 7)
    seq("enemy_explode", 9)
    seq("ship_explode", 17)
    seq("human_explode", 9)
    seq("human_abducted", 3)
    seq("human_fall", 1)
    seq("human_wave", 2)
    seq("human_saved", 0)
    seq("human_stand", 0)
    seq("start", 13)
    seq("newgame", 6)

    for d = 0, 1 do
        for f = 0, 1 do
            load("boost_" .. d .. "_" .. f)
            load("laser_" .. d .. "_" .. f)
        end
    end

    for f = 0, 15 do
        load("ship" .. f)
        load("hurt" .. f)
    end
    for _, suffix in ipairs({ "0u", "0d", "8u", "8d" }) do
        load("ship" .. suffix)
        load("hurt" .. suffix)
    end

    loadFont("font", 48, 57)        -- digits
    loadFont("font", 65, 90)        -- A to Z
    loadFont("font_status", 48, 57) -- small digits for the score

    Assets.terrainW, Assets.terrainH = Assets.img.terrain:getSize()
end

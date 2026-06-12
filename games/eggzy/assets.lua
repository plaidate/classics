-- Image cache. Everything is loaded once at startup; lookups after that are
-- plain table reads. All art is the pre-converted 1-bit set in images/.

local gfx <const> = playdate.graphics

Assets = { img = {} }

local function load(name)
    local im = gfx.image.new("images/" .. name)
    assert(im, "missing image: " .. name)
    Assets.img[name] = im
end

-- load name0 .. nameN (suffix is appended without separator)
local function loadRun(prefix, lastFrame)
    for i = 0, lastFrame do
        load(prefix .. i)
    end
end

function Assets.load()
    -- player
    for _, d in ipairs({ "0", "1" }) do
        loadRun("run_" .. d .. "_", 7)
        loadRun("jump_" .. d .. "_", 5)
        loadRun("fall_" .. d .. "_", 1)
        loadRun("climb_" .. d .. "_", 1)
        load("change_dir_" .. d .. "_0")
    end
    load("stand_front")
    loadRun("die_", 5)

    -- gems and doors
    for t = 1, 4 do
        loadRun("gem" .. t .. "_", 7)
    end
    for v = 0, 4 do
        loadRun("door_forest_" .. v .. "_", 13)
    end

    -- enemies (forest: triffid + fly, castle: robot2 + robot0)
    loadRun("triffid_", 7)
    loadRun("robot0_", 7)
    for i = 0, 7 do
        load("triffid_" .. i .. "_hit")
        load("robot0_" .. i .. "_hit")
    end
    for _, d in ipairs({ "0", "1" }) do
        for i = 0, 7 do
            load("robot2_" .. d .. "_" .. i)
            load("robot2_" .. d .. "_" .. i .. "_hit")
            load("fly_" .. d .. "_" .. i)
            load("fly_" .. d .. "_" .. i .. "_hit")
        end
    end

    -- effects
    loadRun("explosion_", 11)
    loadRun("air_explosion_", 11)
    loadRun("pickup_", 7)
    loadRun("loselife_", 7)
    for _, id in ipairs({ "1", "2", "3", "half" }) do
        loadRun("timer_plus_" .. id .. "_", 13)
    end

    -- bitmap fonts: font (full set), fontbr (bright digits), fontlrg (large
    -- digits); names are the prefix plus the zero-padded ASCII code
    for code = 48, 57 do
        load(string.format("font%03d", code))
        load(string.format("fontbr%03d", code))
        load(string.format("fontlrg%03d", code))
    end
    for code = 65, 90 do
        load(string.format("font%03d", code))
    end
    load("font033") -- !
    load("font046") -- .
    load("fontbr046")
    load("fontlrg046")

    -- screens and HUD
    load("title")
    load("press_to_start")
    load("controls")
    load("over")
    load("status_back")
    load("bg_forest")
    load("bg_castle")
    loadRun("start", 10)
    loadRun("gameover", 13)
    loadRun("newrecord", 7)
end

function Assets.get(name)
    local im = Assets.img[name]
    assert(im, "image not cached: " .. name)
    return im
end

-- Sprite loading. The full asset set has 1400+ frames; we load a curated
-- subset: the hero, the vax thug, and the boss (also used as the heavy thug),
-- right-facing only ("_1_" in the filenames) and colour variant 0 for
-- enemies. Left-facing is drawn with kImageFlippedX. Per-stage background
-- tiles are lazy-loaded by Stages; win/lose screens are lazy-loaded here.

local gfx <const> = playdate.graphics

Assets = {}

local function img(name)
    local i = gfx.image.new("images/" .. name)
    assert(i, "missing image: " .. name)
    return i
end

local function seq(fmt, n)
    local t = {}
    for f = 0, n - 1 do
        t[#t + 1] = img(string.format(fmt, f))
    end
    return t
end

function Assets.build()
    Assets.hero = {
        stand = seq("hero_stand_1_%d", 4),
        walk = seq("hero_walk_1_%d", 4),
        rpunch = seq("hero_rpunch_1_%d", 3),
        lpunch = seq("hero_lpunch_1_%d", 3),
        uppercut = seq("hero_uppercut_1_%d", 3),
        lowkick = seq("hero_lowkick_1_%d", 2),
        flying_kick = seq("hero_flying_kick_1_%d", 8),
        hit = seq("hero_hit_1_%d", 2),
        knockdown = seq("hero_knockdown_1_%d", 3),
        getup = seq("hero_getup_1_%d", 2),
        die = seq("hero_die_1_%d", 3),
    }
    Assets.vax = {
        stand = seq("vax_stand_1_%d_0", 3),
        walk = seq("vax_walk_1_%d_0", 4),
        lpunch = seq("vax_lpunch_1_%d_0", 3),
        rpunch = seq("vax_rpunch_1_%d_0", 3),
        hit = seq("vax_hit_1_%d_0", 2),
        knockdown = seq("vax_knockdown_1_%d_0", 3),
        getup = seq("vax_getup_1_%d_0", 3),
        die = seq("vax_die_1_%d_0", 3),
    }
    Assets.boss = {
        stand = seq("boss_stand_1_%d_0", 2),
        walk = seq("boss_walk_1_%d_0", 4),
        lpunch = seq("boss_lpunch_1_%d_0", 3),
        kick = seq("boss_kick_1_%d_0", 2),
        hit = seq("boss_hit_1_%d_0", 2),
        knockdown = seq("boss_knockdown_1_%d_0", 3),
        getup = seq("boss_getup_1_%d_0", 3),
        die = seq("boss_die_1_%d_0", 3),
    }

    Assets.road = img("road")
    Assets.status = img("status")
    Assets.healthBar = img("health")
    Assets.arrow = img("arrow")
    Assets.life = img("life")
    Assets.barrel = img("barrel_upright")
    Assets.pickup = img("health_pickup")
    Assets.title = { img("title0"), img("title1") }

    local digits = {}
    for d = 0, 9 do
        digits[d + 1] = img("font0" .. (48 + d))
    end
    Assets.digits = digits
end

local finaleCache = {}

function Assets.finale(won)
    local name = won and "status_win" or "status_lose"
    if not finaleCache[name] then
        finaleCache[name] = img(name)
    end
    return finaleCache[name]
end

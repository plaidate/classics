-- Sound effects (sampleplayers, some with random variants) and music
-- (fileplayers). Everything is loaded once at startup.

local snd <const> = playdate.sound

Sfx = {}

local sets = {}
local current = nil

local function loadSet(name, count)
    local list = {}
    for i = 0, count - 1 do
        local p = snd.sampleplayer.new("sounds/" .. name .. i)
        assert(p, "missing sound: " .. name .. i)
        list[#list + 1] = p
    end
    sets[name] = list
end

function Sfx.load()
    loadSet("collect", 1)
    loadSet("jump", 1)
    loadSet("jump_long", 5)
    loadSet("enemy_death", 5)
    loadSet("enemy_take_damage", 5)
    loadSet("player_death", 1)
    loadSet("new_wave", 1)
    loadSet("gameover", 1)

    Sfx.titleMusic = snd.fileplayer.new("music/title_theme")
    Sfx.gameMusic = snd.fileplayer.new("music/ingame_theme")
    assert(Sfx.titleMusic and Sfx.gameMusic, "missing music")
    Sfx.titleMusic:setVolume(0.5)
    Sfx.gameMusic:setVolume(0.35)
end

-- play one of the loaded variants of a named effect
function Sfx.play(name)
    local list = sets[name]
    list[math.random(#list)]:play()
end

-- which: "title" | "game" | nil
function Sfx.music(which)
    if current == which then return end
    Sfx.titleMusic:stop()
    Sfx.gameMusic:stop()
    current = which
    if which == "title" then
        Sfx.titleMusic:play(0)
    elseif which == "game" then
        Sfx.gameMusic:play(0)
    end
end

-- Sound effects from the converted wav set, plus the looping theme.
-- Each effect name maps to a pool of numbered variants; play picks one.

local snd <const> = playdate.sound

Sfx = {}

local pools = {}
local music

local VARIANTS = {
    punch_whoosh = 4,
    punch_hit = 4,
    kick_whoosh = 4,
    kick_hit = 4,
    flyingkick_whoosh = 1,
    flyingkick_hit = 2,
    boss_punch = 2,
    barrel_hit = 1,
    health = 1,
}

function Sfx.build()
    for name, count in pairs(VARIANTS) do
        local pool = {}
        for i = 0, count - 1 do
            pool[#pool + 1] = snd.sampleplayer.new("sounds/" .. name .. i)
        end
        pools[name] = pool
    end
end

function Sfx.play(name)
    local pool = pools[name]
    if not pool then return end
    local player = pool[math.random(#pool)]
    if player then player:play() end
end

function Sfx.startMusic()
    if not music then
        music = snd.fileplayer.new("music/theme")
        if music then music:setVolume(0.3) end
    end
    if music and not music:isPlaying() then
        music:play(0)
    end
end

-- Sampled sound effects from the converted asset pack. Bat hits layer a
-- random "hit" sample with a tier sample that intensifies with ball speed;
-- wall bounces layer a random "bounce" with the bounce synth sample. The
-- win fanfare stays on a synth: no sample exists for it.

local snd <const> = playdate.sound

Sfx = {}

local function sample(name)
    local p = snd.sampleplayer.new("sounds/" .. name)
    assert(p, "missing sound " .. name)
    return p -- just the player: assert's multi-return would leak into table constructors
end

local hits <const> = {
    sample("hit0"), sample("hit1"), sample("hit2"), sample("hit3"), sample("hit4"),
}
local hitTiers <const> = {
    sample("hit_slow0"), sample("hit_medium0"), sample("hit_fast0"), sample("hit_veryfast0"),
}
local bounces <const> = {
    sample("bounce0"), sample("bounce1"), sample("bounce2"), sample("bounce3"), sample("bounce4"),
}
local bounceSynth <const> = sample("bounce_synth0")
local scoreGoal <const> = sample("score_goal0")
local menuUp <const> = sample("up")
local menuDown <const> = sample("down")

local tri = snd.synth.new(snd.kWaveTriangle)

function Sfx.hit(speed)
    hits[math.random(#hits)]:play()
    local tier = (speed <= 10) and 1 or ((speed <= 12) and 2 or ((speed <= 16) and 3 or 4))
    hitTiers[tier]:play()
end

function Sfx.wall()
    bounces[math.random(#bounces)]:play()
    bounceSynth:play()
end

function Sfx.score()
    scoreGoal:play()
end

function Sfx.win()
    local notes = { 523, 659, 784, 1047 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * 0.12, function() tri:playNote(n, 0.3, 0.11) end)
    end
end

function Sfx.menuUp()
    menuUp:play()
end

function Sfx.menuDown()
    menuDown:play()
end

-- Title-screen music, looped.
local music = snd.fileplayer.new("music/theme")

function Sfx.musicOn()
    if music and not music:isPlaying() then
        music:setVolume(0.3)
        music:play(0) -- 0 = repeat forever
    end
end

function Sfx.musicOff()
    if music and music:isPlaying() then
        music:stop()
    end
end

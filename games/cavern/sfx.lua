-- Sound effects, played from the sampled audio in sounds/ (loaded once at
-- startup). Sounds with several takes pick one at random, like the original.
-- Only the flame jet keeps a synth voice: no sample exists for it.

local snd <const> = playdate.sound

Sfx = {}

local function load(name, count)
    local set = {}
    for i = 0, count - 1 do
        local s = snd.sampleplayer.new("sounds/" .. name .. i)
        assert(s, "missing sound: " .. name .. i)
        set[i + 1] = s
    end
    return set
end

local S = {
    blow = load("blow", 4),
    pop = load("pop", 4),
    trap = load("trap", 4),
    laser = load("laser", 4),
    ouch = load("ouch", 4),
    jump = load("jump", 1),
    die = load("die", 1),
    score = load("score", 1),
    bonus = load("bonus", 1),
    level = load("level", 1),
    over = load("over", 1),
}

local function play(name)
    local set = S[name]
    set[math.random(#set)]:play()
end

function Sfx.blow() play("blow") end

function Sfx.pop() play("pop") end

function Sfx.trap() play("trap") end

function Sfx.jump() play("jump") end

function Sfx.laser() play("laser") end

function Sfx.ouch() play("ouch") end

function Sfx.die() play("die") end

function Sfx.score() play("score") end

function Sfx.bonus() play("bonus") end

function Sfx.level() play("level") end

function Sfx.over() play("over") end

-- the aggressive robot's flame breath has no source sample; keep a noise burst
local noise = snd.synth.new(snd.kWaveNoise)

function Sfx.flame()
    noise:playNote(200, 0.3, 0.35)
end

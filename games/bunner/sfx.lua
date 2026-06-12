-- Sampled sound effects from the original game, plus the looping theme.

local snd <const> = playdate.sound

Sfx = {}

local function sample(name)
    local s = snd.sampleplayer.new("sounds/" .. name)
    assert(s, "missing sound: sounds/" .. name)
    return s
end

local jump = sample("jump0")
local splash = sample("splash0")
local splat = sample("splat0")
local bell = sample("bell0")
local eagle = sample("eagle0")
local honks = { sample("honk0"), sample("honk1"), sample("honk2"), sample("honk3") }
local trains = { sample("train0"), sample("train1") }

local music = snd.fileplayer.new("music/theme")

function Sfx.music()
    if music then
        music:setVolume(1.0)
        music:play(0) -- loop forever
    end
end

function Sfx.musicVolume(v)
    if music then music:setVolume(v) end
end

function Sfx.hop() jump:play() end

function Sfx.splash() splash:play() end

function Sfx.squash() splat:play() end

function Sfx.horn() Util.pick(honks):play() end

function Sfx.bell() bell:play() end

function Sfx.train() Util.pick(trains):play() end

function Sfx.eagle() eagle:play() end

-- no start jingle in the original; it ducks the theme during play instead
function Sfx.start()
    Sfx.musicVolume(0.4)
end

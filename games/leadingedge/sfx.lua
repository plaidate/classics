-- Sound: one-shot sample banks, the looping engine and skid, and
-- streamed music. All players are created once at startup.

local snd <const> = playdate.sound

Sfx = {}

local banks = {}

local function loadBank(name, count)
    local list = {}
    for i = 0, count - 1 do
        local p = snd.sampleplayer.new("sounds/" .. name .. i)
        assert(p, "missing sound: " .. name .. i)
        list[#list + 1] = p
    end
    banks[name] = list
end

loadBank("bump", 6)
loadBank("bump_behind", 1)
loadBank("overtake", 6)
loadBank("explosion", 1)
loadBank("fastlap", 1)
loadBank("final_lap", 1)
loadBank("game_complete", 1)
loadBank("gobeep", 1)
loadBank("hit_grass", 1)
loadBank("startbeep", 1)

function Sfx.play(name)
    local bank = banks[name]
    bank[math.random(#bank)]:play()
end

-- Engine: one looping sample, pitched up with speed.
local engine = snd.sampleplayer.new("sounds/engine_short10")
assert(engine, "missing engine sample")
local engineOn = false

function Sfx.engineStart()
    if not engineOn then
        engine:setVolume(0.3)
        engine:setRate(0.5)
        engine:play(0)
        engineOn = true
    end
end

function Sfx.engineUpdate(speed)
    if engineOn then
        engine:setRate(Util.clamp(0.5 + speed * 0.02, 0.5, 2.4))
    end
end

function Sfx.engineStop()
    if engineOn then
        engine:stop()
        engineOn = false
    end
end

-- Skid: looping sample whose volume tracks grip loss.
local skid = snd.sampleplayer.new("sounds/skid_loop0")
assert(skid, "missing skid sample")
local skidOn = false

function Sfx.skid(volume)
    if volume > 0 then
        if not skidOn then
            skid:play(0)
            skidOn = true
        end
        skid:setVolume(volume)
    elseif skidOn then
        skid:stop()
        skidOn = false
    end
end

-- Music: streamed, looping.
local musicPlayers = {}
local currentMusic = nil

function Sfx.music(name)
    Sfx.stopMusic()
    local fp = musicPlayers[name]
    if not fp then
        fp = snd.fileplayer.new("music/" .. name)
        assert(fp, "missing music: " .. name)
        musicPlayers[name] = fp
    end
    currentMusic = fp
    fp:play(0)
end

function Sfx.stopMusic()
    if currentMusic then
        currentMusic:stop()
        currentMusic = nil
    end
end

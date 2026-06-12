-- Sound: sampled effects (kicks, whistle, crowd, goal) with synth fallbacks,
-- plus the menu theme via fileplayer. Triggers are unchanged from the synth
-- version; Draw drives menuScene/matchScene so no game logic had to move.

local snd <const> = playdate.sound

Sfx = {}

local function sample(name)
    return snd.sampleplayer.new("sounds/" .. name)
end

local kicks = {}
for i = 0, 3 do
    local s = sample("kick" .. i)
    if s then kicks[#kicks + 1] = s end
end
local goalShouts = {}
for i = 0, 1 do
    local s = sample("goal" .. i)
    if s then goalShouts[#goalShouts + 1] = s end
end
local crowd = sample("crowd")
local whistle = sample("start") -- the referee's whistle from the original
local move = sample("move")
local theme = snd.fileplayer.new("music/theme")
local themeFailed = false

-- synth fallbacks, kept from the procedural build
local thump = snd.synth.new(snd.kWaveNoise)
local peep = snd.synth.new(snd.kWaveSquare)
local tri = snd.synth.new(snd.kWaveTriangle)
local roar = snd.synth.new(snd.kWaveNoise)
roar:setADSR(0.25, 0.3, 0.5, 0.7) -- slow swell for the goal roar

-- ambience: theme on the menu, looping crowd everywhere else
function Sfx.menuScene()
    if crowd and crowd:isPlaying() then crowd:stop() end
    if theme and not themeFailed and not theme:isPlaying() then
        local ok, res = pcall(theme.play, theme, 0)
        if not ok or res == false then themeFailed = true end
    end
end

function Sfx.matchScene()
    if theme and theme:isPlaying() then theme:stop() end
    if crowd and not crowd:isPlaying() then
        crowd:setVolume(0.35)
        crowd:play(0)
    end
end

function Sfx.kick(power)
    local t = Util.clamp((power - C.KICK_MIN) / (C.KICK_MAX - C.KICK_MIN), 0, 1)
    if #kicks > 0 then
        local s = kicks[math.random(#kicks)]
        s:setVolume(0.55 + t * 0.45)
        s:play()
    else
        thump:playNote(110 + t * 60, 0.2 + t * 0.2, 0.06)
    end
end

function Sfx.whistle()
    if whistle then
        whistle:play()
    else
        peep:playNote(2300, 0.25, 0.16)
        Util.after(0.2, function() peep:playNote(1950, 0.25, 0.3) end)
    end
end

function Sfx.peep()
    if whistle then
        whistle:play()
    else
        peep:playNote(2300, 0.25, 0.14)
    end
end

function Sfx.fullTime()
    if whistle then
        whistle:play()
        Util.after(0.3, function() whistle:play() end)
    else
        peep:playNote(2300, 0.25, 0.12)
        Util.after(0.16, function() peep:playNote(2300, 0.25, 0.12) end)
        Util.after(0.32, function() peep:playNote(2100, 0.25, 0.45) end)
    end
end

function Sfx.goal()
    if #goalShouts > 0 then
        goalShouts[math.random(#goalShouts)]:play()
    else
        local notes = { 523, 659, 784, 1047 }
        for i, n in ipairs(notes) do
            Util.after((i - 1) * 0.12, function() tri:playNote(n, 0.3, 0.14) end)
        end
        roar:playNote(380, 0.12, 0.5)
        Util.after(0.35, function() roar:playNote(500, 0.3, 1.0) end)
        Util.after(1.3, function() roar:playNote(440, 0.15, 0.7) end)
    end
end

function Sfx.switch()
    peep:playNote(880, 0.12, 0.04)
end

function Sfx.menu()
    if move then
        move:play()
    else
        tri:playNote(660, 0.2, 0.05)
    end
end

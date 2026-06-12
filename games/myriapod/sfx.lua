-- Sound effects: real samples via sampleplayer where the converted asset
-- exists, with the old synth one-shots as fallback. Sample mapping:
--   laser0 -> fire        hit0-3 -> non-fatal rock/segment hits
--   segment_explode0 -> segment death     rock_destroy0 -> rock break
--   rock_create0 -> fly seeding a rock    meanie_explode0 -> flyer death
--   player_explode0 -> player death       wave0 -> new wave
--   level_clear -> extra life             gameover -> game over
--   music/theme loops via fileplayer
-- (player_move*, segment_turn0, totem_create0, totem_destroy0 are unused:
-- the port has no move-step sounds or totem rocks.)

local snd <const> = playdate.sound

Sfx = {}

local sq = snd.synth.new(snd.kWaveSquare)
local tri = snd.synth.new(snd.kWaveTriangle)
local saw = snd.synth.new(snd.kWaveSawtooth)
local noise = snd.synth.new(snd.kWaveNoise)

local samples = {}
for _, name in ipairs({
    "laser0", "hit0", "hit1", "hit2", "hit3",
    "segment_explode0", "rock_destroy0", "rock_create0",
    "meanie_explode0", "player_explode0",
    "wave0", "level_clear", "gameover",
}) do
    samples[name] = snd.sampleplayer.new("sounds/" .. name)
end

-- returns true when the real sample exists and was played
local function play(name)
    local p = samples[name]
    if not p then return false end
    p:play(1)
    return true
end

local function playHit()
    return play("hit" .. math.random(0, 3))
end

function Sfx.fire()
    if play("laser0") then return end
    tri:playNote(880, 0.12, 0.04)
end

function Sfx.segHit()
    if playHit() then return end
    sq:playNote(330, 0.2, 0.04)
end

function Sfx.segDie()
    if play("segment_explode0") then return end
    noise:playNote(400, 0.25, 0.06)
    sq:playNote(180, 0.2, 0.08)
end

function Sfx.rockHit()
    if playHit() then return end
    sq:playNote(140, 0.15, 0.03)
end

function Sfx.rockBreak()
    if play("rock_destroy0") then return end
    noise:playNote(150, 0.25, 0.1)
end

function Sfx.rockDrop()
    if play("rock_create0") then return end
    sq:playNote(100, 0.2, 0.05)
end

function Sfx.flyerDie()
    if play("meanie_explode0") then return end
    saw:playNote(700, 0.25, 0.06)
    Util.after(0.07, function() saw:playNote(350, 0.25, 0.08) end)
end

function Sfx.playerDie()
    if play("player_explode0") then return end
    noise:playNote(120, 0.4, 0.4)
    saw:playNote(300, 0.3, 0.15)
    Util.after(0.16, function() saw:playNote(180, 0.3, 0.2) end)
end

function Sfx.wave()
    if play("wave0") then return end
    local notes = { 262, 330, 392, 523 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * 0.08, function() tri:playNote(n, 0.25, 0.07) end)
    end
end

function Sfx.extraLife()
    if play("level_clear") then return end
    tri:playNote(1047, 0.3, 0.08)
    Util.after(0.09, function() tri:playNote(1319, 0.3, 0.1) end)
end

function Sfx.gameover()
    if play("gameover") then return end
    local notes = { 392, 330, 262, 196 }
    for i, n in ipairs(notes) do
        Util.after((i - 1) * 0.18, function() saw:playNote(n, 0.3, 0.15) end)
    end
end

-- looping theme, as in the original (volume 0.4)
local music = snd.fileplayer.new("music/theme")
if music then
    music:setVolume(0.4)
    music:play(0)
end

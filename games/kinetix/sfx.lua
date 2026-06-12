-- Sound effects: sampleplayers over the converted WAVs, plus the title music.

local snd <const> = playdate.sound

Sfx = {}

local players = {}

local NAMES <const> = {
    "ball_stick0", "bat_extend0", "bat_gun0", "bat_small0",
    "bullet_hit0", "bullet_hit1", "bullet_hit2", "bullet_hit3",
    "extra_life0", "game_over0", "hit_brick0", "hit_fast0",
    "hit_veryfast0", "hit_wall0", "laser0", "lose_life0",
    "magnet0", "multiball0", "portal_exit0", "powerup0",
    "speed_up0", "start_game0",
}

function Sfx.load()
    for _, n in ipairs(NAMES) do
        players[n] = snd.sampleplayer.new("sounds/" .. n)
    end
    Sfx.music = snd.fileplayer.new("music/title_theme")
    if Sfx.music then Sfx.music:setVolume(0.3) end
end

-- Plays "name0", or a random one of "name0".."name<variants-1>".
function Sfx.play(name, variants)
    local n = variants and (name .. math.random(0, variants - 1)) or (name .. "0")
    local p = players[n]
    if p then p:play() end
end

function Sfx.startMusic()
    if Sfx.music and not Sfx.music:isPlaying() then
        Sfx.music:play(0)
    end
end

function Sfx.stopMusic()
    if Sfx.music then Sfx.music:stop() end
end

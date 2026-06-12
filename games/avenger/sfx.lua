-- Sampled sound effects and streamed music, all loaded once at startup.

local snd <const> = playdate.sound

Sfx = {}

-- name -> number of recorded variants (a random one is picked when > 1)
local SOUNDS <const> = {
    enemy_appear_mutant = 1,
    enemy_appear_normal = 1,
    enemy_appear_ufo = 1,
    enemy_explode = 6,
    enemy_laser = 1,
    new_wave = 1,
    player_explode = 1,
    player_hit = 1,
    player_shoot = 1,
    prisoner_die = 1,
    rescue_prisoner = 1,
    wave_complete = 1,
}

local players = {}
local variants = {}
local musics = {}
local currentMusic = nil
local thrustPlayer = nil
local thrustOn = false

function Sfx.build()
    for name, count in pairs(SOUNDS) do
        variants[name] = count
        for i = 0, count - 1 do
            players[name .. i] = snd.sampleplayer.new("sounds/" .. name .. i)
        end
    end
    thrustPlayer = snd.sampleplayer.new("sounds/thrust0")
    thrustPlayer:setVolume(0.3)
    musics.ambience = snd.fileplayer.new("music/ambience")
    musics.menu_theme = snd.fileplayer.new("music/menu_theme")
end

function Sfx.play(name, volume)
    volume = volume or 1
    if volume <= 0.02 then return end
    -- once the wreck has cooled on the game over screen, let the field go quiet
    local p = G.player
    if p and p.lives == 0 and p.hurtT < -500 then return end
    local sp = players[name .. math.random(0, variants[name] - 1)]
    if sp then
        sp:setVolume(volume)
        sp:play()
    end
end

function Sfx.setThrust(on)
    if on and not thrustOn then thrustPlayer:play(0) end
    if not on and thrustOn then thrustPlayer:stop() end
    thrustOn = on
end

function Sfx.music(name)
    if currentMusic then currentMusic:stop() end
    currentMusic = musics[name]
    if currentMusic then currentMusic:play(0) end
end

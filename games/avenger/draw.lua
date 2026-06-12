-- All rendering: the parallax backdrop, wrapping terrain, every actor,
-- the radar strip, HUD, bitmap-font text, and the title/game-over cards.

local gfx <const> = playdate.graphics

Draw = {}

local function img(name) return Assets.img[name] end

-- bitmap-font text; the glyph sheets carry digits and capital letters only
local function textWidth(font, text)
    local w = 0
    for i = 1, #text do
        local ch = text:sub(i, i)
        if ch == " " then
            w = w + 11
        else
            w = w + Assets.glyph(font, ch):getSize()
        end
    end
    return w
end

function Draw.text(text, x, y, centre, font)
    font = font or "font"
    if centre then x = x - textWidth(font, text) // 2 end
    for i = 1, #text do
        local ch = text:sub(i, i)
        if ch == " " then
            x = x + 11
        else
            local g = Assets.glyph(font, ch)
            g:draw(x, y)
            x = x + g:getSize()
        end
    end
end

-- ease the camera offset toward a point a third in from the trailing edge,
-- led further out by the ship's speed
local function updateCamera()
    local p = G.player
    local target = (p.facing > 0) and C.CAM_NEAR or C.CAM_FAR
    target = target - p.vx * C.CAM_LEAD
    local delta = Util.clamp((target - G.camOffX) / C.CAM_EASE,
        -C.CAM_MAX_STEP, C.CAM_MAX_STEP)
    G.camOffX = math.floor(G.camOffX + delta)
end

local function radarPos(x, y)
    return C.RADAR_X + ((math.floor(x) % C.LEVEL_W) * C.RADAR_W) // C.LEVEL_W,
        C.RADAR_Y + (math.floor(y) * C.RADAR_H) // C.LEVEL_H
end

local function plural(n)
    return (n == 1) and "" or "S"
end

-- the wave-complete card reveals one line at a time as the timer runs
local function waveEndText()
    local saved = G.humansSaved()
    local i = (G.waveTimer + C.WAVE_COMPLETE_TIME) // (C.WAVE_COMPLETE_TIME // 4)
    local lines = { "WAVE " .. G.wave .. " COMPLETE" }
    if i >= 1 then
        lines[#lines + 1] = saved .. " HUMAN" .. plural(saved) .. " SAVED"
    end
    if i >= 2 then
        local r = G.shieldRestore()
        lines[#lines + 1] = r .. " SHIELD" .. plural(r) .. " RESTORED"
    end
    if i >= 3 and saved == 10 then
        -- if the tokens just rolled over to zero, that full rescue paid out a life
        lines[#lines + 1] = (G.player.tokens == 0) and "EXTRA LIFE" or "LIFE TOKEN GAINED"
    end
    return lines
end

local function drawHud()
    local p = G.player

    img("radar"):draw(C.RADAR_X, C.RADAR_Y)
    gfx.setClipRect(C.RADAR_X, C.RADAR_Y, C.RADAR_W, C.RADAR_H)
    for _, e in ipairs(G.enemies) do
        if e.state == "alive" then
            local x, y = radarPos(e.x, e.y)
            img("dot-red"):drawCentered(x, y)
        end
    end
    for _, h in ipairs(G.humans) do
        local x, y = radarPos(h.x, h.y)
        img("dot-green"):drawCentered(x, y)
    end
    local px, py = radarPos(p.x, p.y)
    img("dot-white"):drawCentered(px, py)
    gfx.clearClipRect()

    for i = 1, p.lives do
        img("life"):draw(10 + 10 * (i - 1), 10)
    end
    for i = 1, p.shields do
        img("armor"):draw(10 + 10 * (i - 1), 27)
    end
    for i = 1, p.tokens do
        img("token" .. ((G.frame // 3 + i - 1) % 8)):draw(10 + 10 * (i - 1), 44)
    end

    local score = tostring(G.score)
    Draw.text(score, C.SCREEN_W - 10 - textWidth("font_status", score), 14,
        false, "font_status")

    if G.waveTimer < 0 then
        local y = 50
        for _, line in ipairs(waveEndText()) do
            Draw.text(line, C.SCREEN_W // 2, y, true)
            y = y + 32
        end
    end
end

function Draw.play()
    updateCamera()
    local p = G.player

    -- where the world's left seam lands on screen, and the vertical scroll
    local left = -(math.floor(p.x - G.camOffX) % C.LEVEL_W)
    local top = math.max(-math.floor(p.y * 0.4), -80)

    -- the backdrop scrolls at half speed: four tiles span the level,
    -- plus one more to cover the seam
    local bg = img("background")
    local bgW = bg:getSize()
    for i = 0, 4 do
        bg:draw(left // 2 + bgW * i, top // 2)
    end

    -- terrain twice, the second copy covering the wrap seam
    local terrain = img("terrain")
    terrain:draw(left, top + C.TERRAIN_Y)
    terrain:draw(left + C.LEVEL_W, top + C.TERRAIN_Y)

    local offX = -(p.x - G.camOffX)
    local function at(name, x, y)
        img(name):drawCentered(x + offX, y + top)
    end

    local bulletSprite = "bullet" .. ((G.frame // 2) % 2)
    for _, b in ipairs(G.bullets) do
        at(bulletSprite, b.x, b.y)
    end

    for _, h in ipairs(G.humans) do
        if h.exploding then
            at("human_explode" .. h.explodeFrame, h.x, h.y)
        else
            at(h.sprite, h.x, h.y)
        end
    end

    for _, e in ipairs(G.enemies) do
        local sx = e.x + offX
        if e.sprite and sx > -100 and sx < C.SCREEN_W + 100 then
            at(e.sprite, e.x, e.y)
        end
    end

    local function drawLasers()
        for _, l in ipairs(G.lasers) do
            local fi = (l.vx > 0) and 0 or 1
            at("laser_" .. fi .. "_" .. math.min(1, l.t // 4), l.x, l.y)
        end
    end
    local function drawFlash()
        -- the muzzle flash lingers for a couple of frames after a shot
        if p.frame % 8 == 0 and p.fireT > 2 then
            at("flash" .. (p.frame // 8), p.x, p.y + Player.laserYOff(p))
        end
    end
    local function drawPlayer()
        -- the turret is on the underside: when tilting down the flash
        -- must go behind the hull, otherwise in front of it
        if p.tilt == 1 then drawFlash() end
        if p.sprite then at(p.sprite, p.x, p.y) end
        if p.boostSprite then at(p.boostSprite, p.boostX, p.boostY) end
        if p.tilt ~= 1 then drawFlash() end
    end
    if p.tilt == 1 then
        drawLasers()
        drawPlayer()
    else
        drawPlayer()
        drawLasers()
    end

    drawHud()
end

function Draw.title()
    gfx.clear(gfx.kColorBlack)
    -- the title card is 480x270; centre it and let the edges crop
    img("title"):drawCentered(C.SCREEN_W // 2, C.SCREEN_H // 2)
    img("start" .. ((G.stateT // 2) % 14)):drawCentered(C.SCREEN_W // 2, 180)

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(0, 204, C.SCREEN_W, 36)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("d-pad move/thrust   A fire   B reverse   crank altitude",
        C.SCREEN_W // 2, 207, kTextAlignment.center)
    gfx.drawTextAligned("press A to start    high score " .. G.highScore,
        C.SCREEN_W // 2, 223, kTextAlignment.center)
end

function Draw.gameoverText()
    Draw.text("GAME OVER", C.SCREEN_W // 2, 70, true)
end

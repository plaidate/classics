-- Rendering: the rock field, the myriapod, pests, ship, HUD, and menus.
-- Real artwork drawn over the wave-coloured background.

local gfx <const> = playdate.graphics

Draw = {}

local function whiteText(fn)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    fn()
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function centerText(s, y)
    gfx.drawTextAligned(s, C.SCREEN_W / 2, y, kTextAlignment.center)
end

local WING_SEQ <const> = { 0, 2, 1, 2 } -- meanie wing-beat order

local function drawField()
    Grid.forEach(function(cx, cy, hp)
        local x, y = Grid.cellPos(cx, cy)
        Sprites.drawCentered(Sprites.rockImg(hp, cx, cy), x, y)
    end)
end

local function drawMyriapod()
    -- leg frame follows progress through the current cell step
    local frame = math.floor(G.stepT * 4) % 4
    local fast = G.wave > 0 and G.wave % 4 == 0
    for _, seg in ipairs(G.segs) do
        local x, y = Myriapod.segPos(seg)
        Sprites.drawCentered(
            Sprites.segImg(fast, seg.hp >= 2, seg.head, seg.dir, frame), x, y)
    end
end

local function drawPests()
    local wing = WING_SEQ[(G.frame // 2) % 4 + 1]
    if G.bee then Sprites.drawCentered(Sprites.meanie[0][wing], G.bee.x, G.bee.y) end
    if G.fly then Sprites.drawCentered(Sprites.meanie[1][wing], G.fly.x, G.fly.y) end
    if G.spider then Sprites.drawCentered(Sprites.meanie[2][wing], G.spider.x, G.spider.y) end
end

local shipDir = 0 -- last facing, kept while no d-pad input (visual only)

local function drawShip()
    local p = G.player
    if not p.alive then return end
    if p.invulnT > 0 and G.frame % 2 == 0 then return end
    local dx, dy = Input.lastDx or 0, Input.lastDy or 0
    if dx ~= 0 or dy ~= 0 then
        if dx == 0 then
            shipDir = 0
        elseif dy == 0 then
            shipDir = 2
        elseif dx * dy < 0 then
            shipDir = 1
        else
            shipDir = 3
        end
    end
    local f = 0 -- firing recoil frames keyed off the existing cooldown timer
    if p.fireT > C.FIRE_COOLDOWN * 0.5 then
        f = 1
    elseif p.fireT > 0 then
        f = 2
    end
    Sprites.drawCentered(Sprites.player[shipDir][f], p.x, p.y)
end

local function drawFx()
    for _, b in ipairs(G.bullets) do
        Sprites.drawCentered(Sprites.bullet, b.x, b.y)
    end
    gfx.setColor(gfx.kColorWhite)
    for _, p in ipairs(G.particles) do
        gfx.fillRect(p.x - 1, p.y - 1, 2, 2)
    end
    for _, e in ipairs(G.explosions) do
        local f = math.min(math.floor(e.t * 15), 7)
        Sprites.drawCentered(Sprites.exp[e.type][f], e.x, e.y)
    end
    whiteText(function()
        for _, p in ipairs(G.popups) do
            gfx.drawTextAligned(p.text, p.x, p.y - 20, kTextAlignment.center)
        end
    end)
end

local function drawHud()
    whiteText(function()
        centerText("WAVE " .. math.max(G.wave, 1), 2)
    end)
    for i = 1, math.min(G.lives, 6) do
        Sprites.life:draw((i - 1) * 20 + 4, 2)
    end
    local score = tostring(G.score)
    for i = 1, #score do
        Sprites.digit[tonumber(score:sub(-i, -i))]:draw(C.SCREEN_W - 4 - i * 12, 2)
    end
end

function Draw.play()
    gfx.clear(gfx.kColorBlack)
    Sprites.bgImg():draw(0, 0)
    drawField()
    drawMyriapod()
    drawPests()
    drawShip()
    drawFx()
    drawHud()
end

function Draw.title()
    gfx.clear(gfx.kColorBlack)
    Sprites.title:draw((C.SCREEN_W - 240) / 2, 0)
    whiteText(function()
        centerText("d-pad: fly    hold A or B: fire    crank: nudge", 156)
        centerText("split the myriapod - mind the spider", 174)
        if G.frame % 30 < 20 then
            centerText("*PRESS A TO START*", 196)
        end
        centerText("HIGH SCORE " .. G.highScore, 218)
    end)
end

function Draw.gameover()
    gfx.clear(gfx.kColorBlack)
    Sprites.over:draw((C.SCREEN_W - 240) / 2, 38)
    whiteText(function()
        centerText("SCORE " .. G.score, 112)
        centerText("WAVE " .. math.max(G.wave, 1), 130)
        if G.score >= G.highScore and G.score > 0 then
            centerText("*NEW HIGH SCORE!*", 152)
        else
            centerText("HIGH SCORE " .. G.highScore, 152)
        end
        if G.frame % 30 < 20 then
            centerText("PRESS A TO PLAY AGAIN", 184)
        end
    end)
end

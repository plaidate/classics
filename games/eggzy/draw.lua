-- Rendering: the cached level image, entities, HUD, and the menu screens.
-- Text uses the per-character font images (prefix plus zero-padded ASCII
-- code), like the bitmap fonts in the reference game.

local gfx <const> = playdate.graphics

Draw = {}

local SPACE_W = 11

local function charImage(ch, font)
    if ch == " " then return nil end
    return Assets.get(string.format("%s%03d", font, string.byte(ch)))
end

function Draw.textWidth(text, font)
    local w = 0
    for i = 1, #text do
        local im = charImage(text:sub(i, i), font)
        w = w + (im and im:getSize() or SPACE_W)
    end
    return w
end

-- align: "left" | "center" | "right"
function Draw.text(text, x, y, align, font)
    font = font or "font"
    if align == "center" then
        x = x - Draw.textWidth(text, font) // 2
    elseif align == "right" then
        x = x - Draw.textWidth(text, font)
    end
    for i = 1, #text do
        local im = charImage(text:sub(i, i), font)
        if im then
            im:draw(x, y)
            x = x + im:getSize()
        else
            x = x + SPACE_W
        end
    end
end

-- bake the backdrop, platforms and ladders into one image per level
function Draw.prepLevel()
    local img = gfx.image.new(C.SCREEN_W, C.SCREEN_H, gfx.kColorBlack)
    gfx.pushContext(img)

    if C.DRAW_BG then
        local bg = Assets.get("bg_" .. G.biome)
        local bw, bh = bg:getSize()
        bg:draw((C.SCREEN_W - bw) // 2, C.SCREEN_H - bh)
    end

    local T = C.TILE
    for r = 1, C.ROWS do
        for c = 1, C.COLS do
            local ch = G.grid[r]:sub(c, c)
            local x, y = (c - 1) * T, (r - 1) * T
            if ch == "X" or ch == "H" then
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(x, y, T, T)
                gfx.setColor(gfx.kColorWhite)
                gfx.drawRect(x, y, T, T)
                gfx.fillRect(x, y, T, 3) -- bright walkable top
            end
            if ch == "L" or ch == "H" then
                gfx.setColor(gfx.kColorBlack)
                gfx.fillRect(x + 2, y, T - 4, T)
                gfx.setColor(gfx.kColorWhite)
                gfx.fillRect(x + 3, y, 2, T)  -- rails
                gfx.fillRect(x + T - 5, y, 2, T)
                for ry = y + 2, y + T - 2, 5 do -- rungs
                    gfx.fillRect(x + 3, ry, T - 6, 2)
                end
            end
        end
    end

    gfx.popContext()
    Draw.levelImg = img
end

local function drawBottomCentered(im, x, y)
    local w, h = im:getSize()
    im:draw(x - w // 2, y - h)
end

local function hud()
    Assets.get("status_back"):draw(C.SCREEN_W // 2 - 74, 0)
    local secs = math.max(G.timeLeft, 0) / 30
    local font = (G.gainedT > 0) and "fontbr" or "font"
    Draw.text(string.format("%.1f", secs), C.SCREEN_W // 2, 6, "center", font)

    Draw.text(tostring(G.score), 8, 4, "left")
    Draw.text("LIVES " .. math.max(G.lives, 0), C.SCREEN_W - 8, 4, "right")

    if G.introT > 0 then
        Draw.text("LEVEL " .. G.level, C.SCREEN_W // 2, 104, "center")
    end
end

function Draw.play()
    Draw.levelImg:draw(0, 0)

    local d = G.door
    if d then
        local im = Assets.get("door_forest_" .. d.variant .. "_" .. d.frame)
        drawBottomCentered(im, d.x, d.y)
    end

    for _, g in ipairs(G.gems) do
        local im = Assets.get("gem" .. g.type .. "_" .. (G.frame // 4) % 8)
        drawBottomCentered(im, g.x, g.y)
    end

    local p = G.player
    if p then
        Assets.get(Player.sprite(p)):draw(p.x - 17, p.y - 35)
    end

    for _, e in ipairs(G.enemies) do
        drawBottomCentered(Assets.get(Enemies.sprite(e)), e.x, e.y)
    end

    Fx.draw()
    hud()
end

function Draw.title()
    gfx.clear(gfx.kColorBlack)
    Assets.get("title"):draw(-6, -24)
    Assets.get("press_to_start"):draw(-6, -5)
    Assets.get("start" .. (G.frame // 6) % 11):draw(C.SCREEN_W // 2 - 75, 190)
    if G.highScore > 0 then
        Draw.text("HI " .. G.highScore, C.SCREEN_W // 2, 166, "center")
    end
end

function Draw.controls()
    gfx.clear(gfx.kColorBlack)
    Assets.get("controls"):draw(-6, -5)
end

function Draw.gameover()
    Assets.get("over"):draw(0, 0)
    Assets.get("gameover" .. (G.frame // 5) % 14):draw(C.SCREEN_W // 2 - 156, 42)

    Draw.text("SCORE", C.SCREEN_W // 2, 102, "center")
    Draw.text(tostring(G.score), C.SCREEN_W // 2, 122, "center", "fontlrg")

    if G.newHigh then
        local im = Assets.get("newrecord" .. (G.frame // 5) % 8)
        im:draw(C.SCREEN_W // 2 - 143, 180)
    else
        Draw.text("HI " .. G.highScore, C.SCREEN_W // 2, 190, "center")
    end
end

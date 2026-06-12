-- Rendering: arena, layered shadows, sprites, HUD margins, menus.

local gfx <const> = playdate.graphics

Draw = {}

local function whiteText(s, x, y, align)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    if align then
        gfx.drawTextAligned(s, x, y, align)
    else
        gfx.drawText(s, x, y)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function drawBat()
    local bat = G.bat
    local f = Bat.spriteFrame()
    local w = Assets.batWidths[bat.form][f]
    local left = math.floor(bat.x - w / 2)
    local top = C.BAT_Y - C.BAT_ART_LIFT
    Assets.batShadows[bat.form][f]:draw(left + C.BIG_SHADOW, top + C.BIG_SHADOW)
    local img = bat.flash and Assets.batGunFlash or Assets.bats[bat.form][f]
    img:draw(left, top)
end

local function drawScore()
    -- the big digits run along the arena's top frame, original-style
    local s = tostring(G.score)
    local x = C.ARENA_X + 8
    for i = 1, #s do
        Assets.digits[tonumber(s:sub(i, i))]:draw(x, 3)
        x = x + 15
    end
end

local function drawHud()
    drawScore()
    whiteText("HIGH", 2, 30)
    whiteText(tostring(G.highScore), 2, 46)
    whiteText("LEVEL", 364, 30)
    whiteText(tostring(G.level), 364, 46)
    for i = 1, math.min(G.lives, 9) do
        Assets.life:draw(6, C.SCREEN_H - 4 - i * 14)
    end
end

function Draw.play()
    gfx.clear(gfx.kColorBlack)
    Assets.arenas[(G.level - 1) % 7]:draw(C.ARENA_X, 0)

    -- the exit portal sits low in the right wall; doors are set dressing
    Util.drawCentered(Assets.portalExit[G.portalFrame], C.PORTAL_X, C.PORTAL_Y)
    Assets.doorLeft:draw(95, 18)
    Assets.doorRight:draw(260, 18)

    -- shadows and sprites stay inside the walls
    gfx.setClipRect(C.ARENA_X + 10, C.TOP_EDGE - 4,
        C.ARENA_W - 20, C.SCREEN_H - C.TOP_EDGE + 4)

    Bricks.drawShadowLayer()
    for _, cap in ipairs(G.capsules) do
        Assets.capsuleShadow:draw(cap.x - 14 + C.SHADOW, cap.y - 5 + C.SHADOW)
    end
    for _, b in ipairs(G.balls) do
        Assets.ballShadow:draw(b.x - 5 + C.BIG_SHADOW, b.y - 5 + C.BIG_SHADOW)
    end

    Bricks.drawBrickLayer()
    for _, b in ipairs(G.balls) do
        Assets.ball:draw(b.x - 5, b.y - 5)
    end
    drawBat()
    for _, cap in ipairs(G.capsules) do
        Assets.capsules[cap.kind][(cap.age // 5) % 10]:draw(cap.x - 14, cap.y - 5)
    end
    for _, bolt in ipairs(G.bullets) do
        Assets.bullets[bolt.side]:draw(bolt.x - 15, bolt.y - 10)
    end

    gfx.clearClipRect()

    for _, im in ipairs(G.impacts) do
        Util.drawCentered(Assets.impacts[im.kind][math.min(im.age // 2, 3)],
            im.x, im.y)
    end

    drawHud()
end

function Draw.title()
    gfx.clear(gfx.kColorBlack)
    -- the logo lives in the top half of the 320x320 title art
    Assets.titleLogo:draw(C.ARENA_X, -30)
    Util.drawCentered(Assets.startAnim[(G.frame // 2) % 13], 200, 148)
    whiteText("crank moves the bat - A serves", 200, 178, kTextAlignment.center)
    whiteText("HIGH SCORE " .. G.highScore, 200, 204, kTextAlignment.center)
end

function Draw.gameover()
    Util.drawCentered(Assets.gameoverAnim[(G.frame // 2) % 15], 200, 130)
    whiteText("press A", 200, 158, kTextAlignment.center)
end

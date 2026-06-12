-- Rendering: the depth-sorted street scene, the status-bar HUD with the
-- converted digit font, the flashing GO arrow, and the menu screens.

local gfx <const> = playdate.graphics

Draw = {}

local function banner(s, y)
    local w, h = gfx.getTextSize(s)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(C.SCREEN_W / 2 - w / 2 - 6, y - 4, w + 12, h + 8, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned(s, C.SCREEN_W / 2, y, kTextAlignment.center)
end

-- zero-padded score in the converted arcade digits, centred in the status bar
local function drawScore()
    local s = string.format("%04d", math.min(G.score, 9999))
    local w = 0
    for i = 1, #s do
        w = w + Assets.digits[s:byte(i) - 47]:getSize() + 1
    end
    local x = C.SCREEN_W / 2 - w / 2
    for i = 1, #s do
        local img = Assets.digits[s:byte(i) - 47]
        img:draw(x, 7)
        x = x + img:getSize() + 1
    end
end

function Draw.hud()
    local p = G.player
    local w = math.max(0, math.floor(p.health / p.maxHealth * C.HEALTH_BAR_W))
    if w > 0 then
        gfx.setClipRect(24, 6, w, C.HEALTH_BAR_H)
        Assets.healthBar:draw(24, 6)
        gfx.clearClipRect()
    end
    Assets.status:draw(0, 0)
    -- lives live in the status bar's right-hand slot (stamina in the original)
    for i = 1, p.lives do
        Assets.life:draw(262 + (i - 1) * 24, 9)
    end
    drawScore()
end

function Draw.play()
    Stages.drawBackground()

    -- depth sort: lowest on screen drawn last; the player edges in front of
    -- enemies at the same depth, barrels in front of everyone
    local order = {}
    for _, pk in ipairs(G.pickups) do
        order[#order + 1] = { pk.y - 0.5, Stages.drawPickup, pk }
    end
    for _, b in ipairs(G.barrels) do
        order[#order + 1] = { b.y + 0.5, Stages.drawBarrel, b }
    end
    for _, e in ipairs(G.enemies) do
        order[#order + 1] = { e.y, Fighters.draw, e }
    end
    order[#order + 1] = { G.player.y + 0.25, Fighters.draw, G.player }
    table.sort(order, function(a, b) return a[1] < b[1] end)
    for _, it in ipairs(order) do
        it[2](it[3])
    end

    -- flashing GO arrow while the street is open to scroll
    if G.camX < G.maxScroll and (G.frame // 15) % 2 == 0 then
        Assets.arrow:draw(175, 60)
    end

    Draw.hud()
end

function Draw.stageBanner()
    banner("*STAGE " .. G.stage .. "*", 108)
end

function Draw.title()
    Assets.title[(G.frame // 15) % 2 + 1]:draw(0, 0)
    banner("d-pad move   A punch   B kick", 186)
    if G.frame % 30 < 20 then
        banner("*PRESS A TO START*", 212)
    end
end

function Draw.gameover()
    Assets.finale(false):draw(0, 0)
    banner("SCORE " .. G.score, 168)
    if G.score >= G.highScore and G.score > 0 then
        banner("*NEW HIGH SCORE!*", 190)
    else
        banner("HIGH SCORE " .. G.highScore, 190)
    end
    if G.frame % 30 < 20 then
        banner("PRESS A TO PLAY AGAIN", 214)
    end
end

function Draw.win()
    Assets.finale(true):draw(0, 0)
    banner("*YOU CLEANED UP THE STREETS!*", 146)
    banner("SCORE " .. G.score, 168)
    if G.score >= G.highScore and G.score > 0 then
        banner("*NEW HIGH SCORE!*", 190)
    else
        banner("HIGH SCORE " .. G.highScore, 190)
    end
    if G.frame % 30 < 20 then
        banner("PRESS A TO PLAY AGAIN", 214)
    end
end

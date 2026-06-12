-- All rendering: backgrounds, tiles, entities, HUD, and menu screens.
-- Animation frame selection mirrors the original Cavern's indexing (which
-- ran at 60fps) adapted to this game's 30fps timers. Game logic, anchors,
-- and collision geometry are untouched: only the artwork changed.

local gfx <const> = playdate.graphics

Draw = {}

local drawAnchored = function(...) return Sprites.drawAnchored(...) end
local drawCentered = function(...) return Sprites.drawCentered(...) end

function Draw.grid()
    Sprites.bg[G.theme + 1]:draw(0, 0)
    local tile = Sprites.tiles[G.theme + 1]
    for gy = 0, 14 do
        local row = G.grid[gy + 1]
        if #row > 0 then
            for gx = 0, C.COLS - 1 do
                if row:sub(gx + 1, gx + 1) ~= " " then
                    tile:draw(gx * C.TILE, gy * C.TILE)
                end
            end
        end
    end
end

local function playerImage(c)
    if c.health <= 0 then return Sprites.fall[(G.frame // 2) % 2] end
    if c.hurtT > C.KNOCK_TIME then return Sprites.recoil[c.facing] end
    if c.fireT > 0 then return Sprites.blow[c.facing] end
    if c.moving then return Sprites.run[c.facing][(G.frame // 4) % 4] end
    return Sprites.still
end

local function fruitFrame()
    return ({ 0, 1, 2, 1 })[(G.frame // 3) % 4 + 1]
end

local function drawEntities()
    for _, f in ipairs(G.fruits) do
        drawAnchored(Sprites.fruit[f.type][fruitFrame()], f.x, f.y)
    end

    for _, r in ipairs(G.robots) do
        local frame
        if r.flameT > 0 then
            frame = 7
        elseif r.fireT < 0.25 then
            frame = 5 + math.min(2, math.floor(r.fireT * 15))
        else
            frame = 1 + (G.frame // 2) % 4
        end
        drawAnchored(Sprites.robot[r.type][r.facing][frame], r.x, r.y)
    end

    local c = G.player
    if c and G.state == "play" and not (c.hurtT > 0 and G.frame % 2 == 0) then
        drawAnchored(playerImage(c), c.x, c.y)
    end

    for _, b in ipairs(G.bolts) do
        drawCentered(Sprites.bolt[b.dir][(G.frame // 2) % 2], b.x, b.y)
    end

    for _, fl in ipairs(G.flames) do
        gfx.setColor(gfx.kColorXOR)
        gfx.fillCircleAtPoint(fl.x, fl.y, 2 + (0.2 - fl.life) * 12)
        gfx.setColor(gfx.kColorWhite)
        gfx.drawPixel(fl.x + math.random(-2, 2), fl.y + math.random(-2, 2))
        gfx.setColor(gfx.kColorBlack)
    end

    for _, o in ipairs(G.orbs) do
        local tf = math.floor(o.t * 30) -- orb age in frames
        local img
        if o.trapped then
            img = Sprites.trap[o.trapped][(tf // 2) % 8]
        elseif tf < 5 then
            img = Sprites.orb[math.min(2, math.floor(tf / 1.5))]
        else
            img = Sprites.orb[3 + ((tf - 5) // 4) % 4]
        end
        drawCentered(img, o.x, o.y)
    end

    for _, p in ipairs(G.pops) do
        local frame = math.min(5, math.floor(p.t * 15))
        drawCentered((p.big and Sprites.pop.big or Sprites.pop.small)[frame], p.x, p.y)
    end
end

local function drawHud()
    local x = 2
    for _ = 1, math.min(G.lives, 3) do
        Sprites.life:draw(x, 18)
        x = x + 24
    end
    if G.lives > 3 then
        Sprites.plus:draw(x, 18)
        x = x + 24
    end
    local c = G.player
    for _ = 1, (c and c.health or 0) do
        Sprites.health:draw(x, 18)
        x = x + 24
    end
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("LEVEL " .. G.level, C.SCREEN_W / 2, 18, kTextAlignment.center)
    gfx.drawTextAligned("*" .. G.score .. "*", C.SCREEN_W - 4, 18, kTextAlignment.right)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Draw.play()
    Draw.grid()
    drawEntities()
    drawHud()
end

function Draw.title()
    Draw.grid()
    Sprites.title:draw(0, 0)
    -- "PRESS SPACE" banner: 10 frames, parked on the last one most of the time
    local f = math.min(((G.frame + 20) % 80) // 2, 9)
    Sprites.space[f]:draw(65, 140)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("d-pad move   A jump   B blow an orb (hold to inflate)",
        C.SCREEN_W / 2, 196, kTextAlignment.center)
    if G.frame % 30 < 20 then
        gfx.drawTextAligned("*PRESS A TO START*", C.SCREEN_W / 2, 214, kTextAlignment.center)
    end
    gfx.drawTextAligned("HIGH SCORE " .. G.highScore, C.SCREEN_W - 4, 224, kTextAlignment.right)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Draw.gameover()
    Sprites.over:draw(0, 0)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("SCORE " .. G.score, C.SCREEN_W / 2, 186, kTextAlignment.center)
    if G.score >= G.highScore and G.score > 0 then
        gfx.drawTextAligned("*NEW HIGH SCORE!*", C.SCREEN_W / 2, 204, kTextAlignment.center)
    else
        gfx.drawTextAligned("HIGH SCORE " .. G.highScore, C.SCREEN_W / 2, 204, kTextAlignment.center)
    end
    if G.frame % 30 < 20 then
        gfx.drawTextAligned("PRESS A", C.SCREEN_W / 2, 222, kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

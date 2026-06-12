-- Rendering: terrain bands, movers, the rabbit, HUD, and menu screens.

local gfx <const> = playdate.graphics

Draw = {}

-- Which bush tile fits each blocked column, mirroring the original
-- tiling rules: 0 single, 1 left end, 2 right end, 3/4 alternating
-- middles, 5 a middle piece that precedes a right end. Off-screen
-- neighbours count the same as the edge column, as in the original.
local function hedgeArt(mask)
    local function blockedAt(i)
        return mask[Util.clamp(i, 1, C.COLS)]
    end
    local art, prevMid = {}, nil
    for i = 1, C.COLS do
        if mask[i] then
            local sx = 3
            if not blockedAt(i - 1) then sx = sx - 2 end
            if not blockedAt(i + 1) then sx = sx - 1 end
            if sx == 3 then
                if prevMid == 4 and not blockedAt(i + 2) then
                    sx, prevMid = 5, nil
                else
                    sx = prevMid == 3 and 4 or 3
                    prevMid = sx
                end
            else
                prevMid = nil
            end
            art[i] = sx
        else
            prevMid = nil
        end
    end
    return art
end

local function drawRow(row)
    local sy = math.floor(row.y - G.camY + 0.5)
    if sy - 12 > C.SCREEN_H or sy + C.ROW_H < 0 then return end
    local k = row.kind

    local band = Sprites.band(row)
    band.img:draw(0, sy - band.yoff)

    if row.hedge then
        row.hedgeArt = row.hedgeArt or hedgeArt(row.hedge)
        for i, sx in pairs(row.hedgeArt) do
            local img = Sprites.bush[sx][row.hedgeRow]
            local _, h = img:getSize()
            img:draw((i - 1) * C.CELL_W, sy + C.ROW_H - h)
        end
    end

    for _, s in ipairs(row.splats) do
        Sprites.splat[s.dir]:draw(s.x - 15, sy - 3)
    end

    local p = G.player
    for _, t in ipairs(row.things) do
        local img
        local side = (t.dx or row.dx) < 0 and "left" or "right"
        if t.train then
            img = Sprites.trains[(t.art or 0) + 1][side]
        elseif k == "road" then
            img = Sprites.cars[(t.art or 0) + 1][side]
        else
            img = t.long and Sprites.logLong or Sprites.logSmall
        end
        local dip = 0
        if k == "water" and p and p.state == "alive" and p.hopT == 0
            and math.abs(p.y - row.y) < 1 and math.abs(p.x - t.x) < t.w / 2 - 4 then
            dip = 2
        end
        local w, h = img:getSize()
        img:draw(t.x - w / 2, sy + (C.ROW_H - h) // 2 + dip)
    end

    if row.warnT and math.floor(G.frame / 4) % 2 == 0 then
        local wx = row.trainDir > 0 and 12 or C.SCREEN_W - 12
        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(wx, sy + 12, 9)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("!", wx, sy + 5, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

function Draw.world()
    gfx.clear(gfx.kColorWhite)
    -- top rows first so section caps and tall bushes overhang the band above
    for i = #G.rows, 1, -1 do
        drawRow(G.rows[i])
    end
end

local function drawPlayer()
    local p = G.player
    if not p or p.state ~= "alive" then return end
    local set = Sprites.rabbit[p.dir]
    local img = p.hopT > 0 and set.hop or set.sit
    local lift = 0
    if p.hopT > 0 then
        lift = math.sin((1 - p.hopT / C.HOP_TIME) * math.pi) * 5
    end
    local w, h = img:getSize()
    img:draw(p.x - w / 2, p.y - G.camY + C.ROW_H / 2 - h / 2 - lift)
end

-- score as digit sprites, like the original: colour 0 top left for the
-- score, colour 1 top right for the high score; align 0 = left, 1 = right
local function drawNumber(n, colour, x, align)
    local s = tostring(math.floor(n))
    for i = 1, #s do
        Sprites.digits[colour][tonumber(s:sub(i, i))]:draw(x + (i - 1 - #s * align) * 13, 2)
    end
end

function Draw.play()
    Draw.world()

    for _, f in ipairs(G.fx) do
        -- 8 splash frames spread across the 0.54s ripple lifetime
        local img = Sprites.splash[math.min(8, math.floor(f.t / 0.0675) + 1)]
        img:draw(f.x - 30, f.y - G.camY + C.ROW_H / 2 - 21)
    end
    drawPlayer()
    if G.eagle then
        Sprites.eagle:draw(G.eagle.x - 41, G.eagle.y - G.camY - 18)
    end

    drawNumber(G.score, 0, 2, 0)
    drawNumber(G.highScore, 1, C.SCREEN_W - 4, 1)
end

local function pill(text, y)
    local w, h = gfx.getTextSize(text)
    local x = (C.SCREEN_W - w) / 2
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(x - 6, y - 2, w + 12, h + 3, 4)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawText(text, x, y)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Draw.title()
    Draw.world()
    Sprites.title:draw((C.SCREEN_W - 240) // 2, 0)
    pill("d-pad hops - crank forward to bound ahead", 180)
    if G.frame % 30 < 20 then
        pill("*PRESS A TO START*", 200)
    end
    pill("HIGH SCORE " .. G.highScore, 221)
end

function Draw.gameover()
    Draw.world()
    Sprites.gameover:draw((C.SCREEN_W - 240) // 2, 0)

    if G.score >= G.highScore and G.score > 0 then
        pill("SCORE " .. G.score .. " - *NEW HIGH SCORE!*", 200)
    else
        pill("SCORE " .. G.score .. " - HIGH " .. G.highScore, 200)
    end
    if G.frame % 30 < 20 then
        pill("PRESS A TO HOP AGAIN", 221)
    end
end

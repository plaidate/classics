-- Rendering. The road is projected once per frame into horizontal rows
-- (one per visible track piece, all points on a piece share a screen Y),
-- then drawn far-to-near as full-width trackside bands (fillRect) with
-- road / rumble / stripe quads (fillPolygon) on top, interleaving car
-- and scenery sprites so near road occludes far sprites. Also the
-- bitmap-font text, HUD, title and results screens.

local gfx <const> = playdate.graphics

Draw = {}

-- 1-bit shades for a night race (1 bits = white)
local PAT_ROAD <const> = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 } -- 50%
local PAT_SIDE1 <const> = { 0x88, 0x00, 0x22, 0x00, 0x88, 0x00, 0x22, 0x00 } -- 12.5%
local PAT_SIDE2 <const> = { 0x44, 0x00, 0x11, 0x00, 0x44, 0x00, 0x11, 0x00 } -- 12.5%, offset
local PAT_RUMBLE2 <const> = { 0xAA, 0x00, 0x55, 0x00, 0xAA, 0x00, 0x55, 0x00 } -- 25%
-- fade-to-black steps: all-black bitmap rows + a coverage mask
local FADES <const> = {
    { 0, 0, 0, 0, 0, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0xEE, 0xBB, 0xEE, 0xBB, 0xEE, 0xBB, 0xEE, 0xBB },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22, 0x88, 0x22 },
}

-- Bitmap font -------------------------------------------------------

local GAP <const> = { font = -3, status1b_ = 0, status2_ = 0 }
local SPACE_W <const> = 15

local function charImage(c, font)
    if c == "%" then return Img.get("xb_a") end -- the A-button glyph
    return Img.get(font .. "0" .. string.byte(c))
end

local function textWidth(text, font)
    local w = 0
    for i = 1, #text do
        local c = text:sub(i, i)
        w = w + (c == " " and SPACE_W or (charImage(c, font):getSize()))
    end
    return w + GAP[font] * (#text - 1)
end

function Draw.text(text, x, y, centre, font)
    font = font or "font"
    if centre then x = x - textWidth(text, font) // 2 end
    for i = 1, #text do
        local c = text:sub(i, i)
        if c == " " then
            x = x + SPACE_W + GAP[font]
        else
            local img = charImage(c, font)
            img:draw(x, y)
            x = x + img:getSize() + GAP[font]
        end
    end
end

-- Road rows ---------------------------------------------------------
-- Parallel arrays, reused every frame to keep the GC quiet.

local rN = 0
local rIdx, rZ, rY = {}, {}, {}
local rLX, rRX = {}, {} -- road edges
local rSL, rSR = {}, {} -- centre stripe
local rRL, rRR = {}, {} -- rumble strip outer edges
local rOX, rOY = {}, {} -- accumulated world offset at this piece
local rDX, rDY = {}, {} -- offset delta at this piece
local rVis = {}

local carTmp = {}

local function gantryImage(R)
    local index
    if R.startTimer > 0 then
        index = math.floor(Util.remap(R.startTimer, 4, 0, 0, 4))
    else
        index = (math.floor(R.timer * 2) % 2 == 0) and 4 or 5
    end
    return "start" .. index
end

local function buildRows(R)
    local camX, camY, camZ = R.camX, R.camY, R.camZ
    rN = 0
    local firstIdx, firstZ = Track.aheadIdx(camZ)
    if not firstIdx then return end

    local pieceZ = firstZ + 1
    local offX, offY, odX, odY = 0, 0, 0, 0

    for k = 0, C.VIEW - 1 do
        local i = firstIdx + k
        if i >= Track.count then break end
        pieceZ = pieceZ - 1

        -- the first row interpolates its offset by how far the camera
        -- is through the piece behind it, so corners don't judder
        local ox, oy = Track.ox[i + 1], Track.oy[i + 1]
        if k == 0 then
            local fraction = Util.clamp(camZ - pieceZ, 0, 1)
            odX, odY = fraction * ox, fraction * oy
        else
            odX, odY = odX + ox, odY + oy
        end
        offX, offY = offX + odX, offY + odY

        local n = rN + 1
        rN = n
        rIdx[n], rZ[n] = i, pieceZ
        rOX[n], rOY[n], rDX[n], rDY[n] = offX, offY, odX, odY

        local nz = pieceZ - camZ
        if nz <= C.CLIP then
            local inv = 1 / nz
            local cx = offX - camX
            rVis[n] = true
            rY[n] = (offY - camY) * inv + C.HALF_H
            rLX[n] = (cx + 750) * inv + C.HALF_W
            rRX[n] = (cx - 750) * inv + C.HALF_W
            rSL[n] = (cx + C.HALF_STRIPE_W) * inv + C.HALF_W
            rSR[n] = (cx - C.HALF_STRIPE_W) * inv + C.HALF_W
            rRL[n] = (cx + 750 + C.HALF_RUMBLE_W) * inv + C.HALF_W
            rRR[n] = (cx - 750 - C.HALF_RUMBLE_W) * inv + C.HALF_W
        else
            rVis[n] = false
        end
    end
end

-- Sprites -----------------------------------------------------------

local function drawSceneryAt(R, k)
    local scen = Track.scen[rIdx[k] + 1]
    if not scen then return end
    local pieceZ = rZ[k]
    local nz = pieceZ - R.camZ
    if nz > C.CLIP then return end
    for s = 1, #scen do
        local obj = scen[s]
        if k <= (obj.maxD or C.VIEW) and (R.camZ - pieceZ) > (obj.minD or 0) then
            local name = obj.dynamic and gantryImage(R) or obj.img
            local w = Img.size(name)
            local sw = w * obj.scale / -nz
            if sw < C.MAX_SCENERY_W then
                local sx = (obj.x + rOX[k] - R.camX) / nz + C.HALF_W
                local sy = (rOY[k] - R.camY) / nz + C.HALF_H
                Img.drawSprite(name, sx, sy, sw)
            end
        end
    end
end

local function drawCarsAt(R, k)
    -- gather cars on this piece, sorted far-to-near
    local i = rIdx[k]
    local cnt = 0
    for ci = 1, #R.cars do
        local car = R.cars[ci]
        if car.pieceIdx == i then
            cnt = cnt + 1
            local j = cnt
            while j > 1 and carTmp[j - 1].z > car.z do
                carTmp[j] = carTmp[j - 1]
                j = j - 1
            end
            carTmp[j] = car
        end
    end
    if cnt == 0 then return end

    local pieceZ = rZ[k]
    for ci = 1, cnt do
        local car = carTmp[ci]
        local fraction = Util.clamp(pieceZ - car.z, 0, 1)
        local cox, coy = 0, 0
        if car ~= R.camFollow then
            -- ease the car into the next piece's offset so it leans
            -- into corners before the camera reaches them
            local nox = Track.ox[i + 2] or 0
            local noy = Track.oy[i + 2] or 0
            cox = rOX[k] + (nox + rDX[k]) * fraction
            coy = rOY[k] + (noy + rDY[k]) * fraction
        end
        local nz = pieceZ - fraction - R.camZ
        if nz <= C.CLIP_CARS then
            if car.isCPU then
                -- pick an angled sprite from how the car sits in view
                local off = (car.x + cox - R.camX) / math.max(1, -nz)
                    - car.steering * 10
                local a = Util.remapClamp(off, -100, 100, -4, 4)
                a = a >= 0 and math.floor(a) or math.ceil(a)
                if car == R.camFollow then a = Util.clamp(a, -1, 1) end
                Cars.spriteFrame(car, a, false)
            end
            local w = Img.size(car.img)
            local sw = w * 2 / -nz
            if sw < C.MAX_CAR_W then
                local sx = (car.x + cox - R.camX) / nz + C.HALF_W
                local sy = (coy - R.camY) / nz + C.HALF_H
                Img.drawSprite(car.img, sx, sy, sw)
            end
        end
    end
end

-- The scene ---------------------------------------------------------

function Draw.scene(R)
    gfx.clear(gfx.kColorBlack)

    -- skyline, scrolled by the accumulated corner/hill offsets
    local bg = Img.get("background")
    bg:draw(R.bgX, R.bgY)
    if R.bgX > 0 then bg:draw(R.bgX - 1600, R.bgY) end
    if R.bgX + 1600 < C.SCREEN_W then bg:draw(R.bgX + 1600, R.bgY) end

    for ci = 1, #R.cars do
        R.cars[ci].pieceIdx = math.floor(-R.cars[ci].z)
    end

    buildRows(R)

    -- far to near: sprites on a piece first, then the nearer band that
    -- connects it back toward the camera, so hills hide what's beyond
    for k = rN, 1, -1 do
        drawSceneryAt(R, k)
        drawCarsAt(R, k)

        if k > 1 and rVis[k] and rVis[k - 1] then
            local i = rIdx[k]
            local y0, y1 = rY[k - 1], rY[k]
            local top = math.min(y0, y1)
            local bandH = math.abs(y0 - y1)
            if top < C.SCREEN_H then
                -- trackside: one full-width band
                gfx.setPattern((i // 5) % 2 == 0 and PAT_SIDE1 or PAT_SIDE2)
                gfx.fillRect(0, top, C.SCREEN_W, math.max(bandH, 1))

                -- road
                if Track.line[i + 1] then
                    gfx.setColor(gfx.kColorWhite) -- the start line
                else
                    gfx.setPattern(PAT_ROAD)
                end
                gfx.fillPolygon(rLX[k - 1], y0, rLX[k], y1, rRX[k], y1, rRX[k - 1], y0)

                if bandH >= 2 then
                    -- rumble strips, alternating shades
                    if (i // 2) % 2 == 0 then
                        gfx.setColor(gfx.kColorWhite)
                    else
                        gfx.setPattern(PAT_RUMBLE2)
                    end
                    gfx.fillPolygon(rRL[k - 1], y0, rRL[k], y1, rLX[k], y1, rLX[k - 1], y0)
                    gfx.fillPolygon(rRR[k - 1], y0, rRR[k], y1, rRX[k], y1, rRX[k - 1], y0)

                    -- centre stripe, 3 pieces on / 3 off
                    if (i // 3) % 2 == 0 then
                        gfx.setColor(gfx.kColorWhite)
                        gfx.fillPolygon(rSL[k - 1], y0, rSL[k], y1, rSR[k], y1, rSR[k - 1], y0)
                    end
                end
            end
        end
    end
end

-- HUD and screens ---------------------------------------------------

function Draw.hud(R)
    local p = R.player
    if not p then return end

    if R.timeUp then
        Draw.text("TIME UP!", C.HALF_W, 96, true)
        return
    end

    if R.raceComplete then
        local pos = Util.indexOf(R.cars, p)
        Draw.text("RACE COMPLETE!", C.HALF_W, 28, true)
        Draw.text("POSITION", C.HALF_W, 64, true)
        Draw.text(tostring(pos), C.HALF_W, 96, true)
        Draw.text("FASTEST LAP", 100, 136, true)
        Draw.text(Util.formatTime(p.fastestLap or 0), 100, 168, true)
        Draw.text("RACE TIME", 300, 136, true)
        Draw.text(Util.formatTime(p.raceTime), 300, 168, true)
        if (G.newLapRecord or G.newRaceRecord) and G.frame % 30 < 20 then
            local what = G.newRaceRecord and "RACE" or "LAP"
            Draw.text("NEW " .. what .. " RECORD!", C.HALF_W, 204, true)
        end
        return
    end

    -- the status bar
    local sx = C.HALF_W - 141
    Img.get("status"):draw(sx, 0)
    local pos = Util.indexOf(R.cars, p)
    Draw.text(string.format("%02d", p.lap), sx + 15, 18, false, "status1b_")
    Draw.text(string.format("%02d", pos), sx + 58, 18, false, "status1b_")
    Draw.text(string.format("%03d", math.floor(p.speed)), sx + 98, 18, false, "status1b_")
    Draw.text(Util.formatTime(p.lapTime), sx + 149, 18, false, "status2_")

    -- fastest lap banner, then the final-lap call
    if p.lastLapFastest and p.lapTime < 4 then
        Draw.text("FASTEST LAP!", C.HALF_W, 96, true)
        Draw.text(Util.formatTime(p.fastestLap), C.HALF_W, 128, true)
    end
    local beginT, endT = 0, 4
    if p.lastLapFastest then beginT, endT = 4, 8 end
    if p.lap == C.NUM_LAPS and p.lapTime > beginT and p.lapTime < endT then
        Draw.text("FINAL LAP!", C.HALF_W, 96, true)
    end
end

function Draw.title()
    local logo = Img.get("logo")
    logo:draw(C.HALF_W - 152, 16)
    if G.bestLap then
        Draw.text("BEST LAP " .. Util.formatTime(G.bestLap), C.HALF_W, 156, true)
    end
    Draw.text("PRESS %", C.HALF_W, 199, true)

    -- fade the demo race out before a reset and in after one
    local v = math.min(G.demoT, C.DEMO_RESET - G.demoT)
    if v < 1 then
        gfx.setPattern(FADES[math.max(1, math.ceil(v * 4))])
        gfx.fillRect(0, 0, C.SCREEN_W, C.SCREEN_H)
    end
end

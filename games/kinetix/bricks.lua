-- The brick field: offscreen layers redrawn only when a cell changes,
-- plus the shared wall/brick collision test used by balls and bullets.

local gfx <const> = playdate.graphics

Bricks = {}

local brickLayer, shadowLayer

local function cellX(col) return C.GRID_X + (col - 1) * C.BRICK_W end
local function cellY(row) return C.GRID_Y + (row - 1) * C.BRICK_H end

-- Repaints one grid cell on both layers (brick art, drop shadow).
function Bricks.repaint(row, col)
    local x, y = cellX(col), cellY(row)
    local id = G.bricks[row][col]

    gfx.pushContext(brickLayer)
    gfx.setColor(gfx.kColorClear)
    gfx.fillRect(x, y, C.BRICK_W, C.BRICK_H)
    if id then Assets.bricks[id]:draw(x, y) end
    gfx.popContext()

    gfx.pushContext(shadowLayer)
    gfx.setColor(gfx.kColorClear)
    gfx.fillRect(x + C.SHADOW, y + C.SHADOW, C.BRICK_W, C.BRICK_H)
    if id then Assets.brickShadow:draw(x + C.SHADOW, y + C.SHADOW) end
    gfx.popContext()
end

function Bricks.rebuildLayers()
    brickLayer = gfx.image.new(C.SCREEN_W, C.SCREEN_H, gfx.kColorClear)
    shadowLayer = gfx.image.new(C.SCREEN_W, C.SCREEN_H, gfx.kColorClear)
    for r = 1, G.rows do
        for c = 1, C.GRID_COLS do
            Bricks.repaint(r, c)
        end
    end
end

function Bricks.drawShadowLayer() shadowLayer:draw(0, 0) end
function Bricks.drawBrickLayer() brickLayer:draw(0, 0) end

-- Circle (x, y, rad) versus one grid cell. Returns the contact point or nil.
local function circleVsCell(x, y, row, col, rad)
    local x0, y0 = cellX(col), cellY(row)
    local x1, y1 = x0 + C.BRICK_W, y0 + C.BRICK_H

    -- flat contact with the left/right faces
    if x + rad > x0 and x - rad < x1 and y > y0 and y < y1 then
        return (x < (x0 + x1) / 2) and x0 or x1, y
    end
    -- flat contact with the top/bottom faces
    if x > x0 and x < x1 and y + rad > y0 and y - rad < y1 then
        return x, (y < (y0 + y1) / 2) and y0 or y1
    end
    -- otherwise the nearest corner decides
    local cx = (x < (x0 + x1) / 2) and x0 or x1
    local cy = (y < (y0 + y1) / 2) and y0 or y1
    local dx, dy = x - cx, y - cy
    if dx * dx + dy * dy < rad * rad then
        return cx, cy
    end
    return nil
end

-- Tests a circle moving along (dx, dy) against the walls and the brick
-- grid, damaging whatever destructible brick it touches.
-- Returns hitX, hitY, showRing, kind ("wall" | "brick" | "metal"), or nil.
function Bricks.collide(x, y, dx, dy, rad)
    if dx < 0 and x < C.LEFT_EDGE + rad then return C.LEFT_EDGE, y, true, "wall" end
    if dx > 0 and x > C.RIGHT_EDGE - rad then return C.RIGHT_EDGE, y, true, "wall" end
    if dy < 0 and y < C.TOP_EDGE + rad then return x, C.TOP_EDGE, true, "wall" end

    -- only the cells the circle's box overlaps need testing
    local c0 = math.max(1, math.floor((x - rad - C.GRID_X) / C.BRICK_W) + 1)
    local c1 = math.min(C.GRID_COLS, math.floor((x + rad - C.GRID_X) / C.BRICK_W) + 1)
    local r0 = math.max(1, math.floor((y - rad - C.GRID_Y) / C.BRICK_H) + 1)
    local r1 = math.min(G.rows, math.floor((y + rad - C.GRID_Y) / C.BRICK_H) + 1)

    for row = r0, r1 do
        for col = c0, c1 do
            local id = G.bricks[row][col]
            if id then
                local hx, hy = circleVsCell(x, y, row, col, rad)
                if hx then
                    local midX = cellX(col) + C.BRICK_W / 2
                    local midY = cellY(row) + C.BRICK_H / 2
                    local kind = "brick"
                    Harness.count("brickHits")
                    if id >= 12 then
                        -- armored dents down to a plain brick; metal shrugs
                        G.addImpact(midX, midY, 13)
                        if id == 13 then
                            kind = "metal"
                        else
                            G.bricks[row][col] = 11
                            Bricks.repaint(row, col)
                        end
                    else
                        G.addImpact(midX, midY, id)
                        if math.random() < C.DROP_CHANCE then
                            Drops.spawnCapsule(midX, midY)
                        end
                        G.bricks[row][col] = false
                        Bricks.repaint(row, col)
                        G.addScore(C.BRICK_SCORE)
                        G.bricksLeft = G.bricksLeft - 1
                        Harness.count("bricksDestroyed")
                        if G.bricksLeft == 0 then
                            Main.openPortal()
                        end
                    end
                    return hx, hy, false, kind
                end
            end
        end
    end
    return nil
end

-- Failsafe: turns every metal brick armored (called when balls get stuck
-- ricocheting forever between unbreakables). Returns true if any changed.
function Bricks.softenMetal()
    local changed = false
    for r = 1, G.rows do
        for c = 1, C.GRID_COLS do
            if G.bricks[r][c] == 13 then
                G.bricks[r][c] = 12
                Bricks.repaint(r, c)
                changed = true
            end
        end
    end
    return changed
end

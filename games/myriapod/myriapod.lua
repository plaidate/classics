-- The myriapod: independent segments that march cell to cell, each picking
-- the least-bad exit every step. Chains hold together because every segment
-- claims its target cell before anyone moves; shooting a middle segment
-- simply leaves two shorter chains, the trailing one led by a new head.

Myriapod = {}

local UP <const>, RIGHT <const>, DOWN <const>, LEFT <const> = 1, 2, 3, 4
local DX <const> = { 0, 1, 0, -1 }
local DY <const> = { -1, 0, 1, 0 }

local function inverse(d)
    return (d + 1) % 4 + 1
end

local function isHoriz(d)
    return d == RIGHT or d == LEFT
end

function Myriapod.pace()
    local p = math.min(C.BASE_PACE + (G.wave - 1) * C.PACE_PER_WAVE, C.MAX_PACE)
    if G.wave % 4 == 0 then p = p * C.FAST_WAVE_MULT end
    return p
end

function Myriapod.spawnWave()
    G.wave = G.wave + 1
    G.stepT = 0
    local hpPair = ({ { 1, 1 }, { 1, 2 }, { 2, 2 }, { 1, 1 } })[(G.wave - 1) % 4 + 1]
    local count = 8 + (G.wave - 1) // 4 * 2
    for i = 1, count do
        G.segs[i] = {
            cx = -i, cy = 0, -- marches in from beyond the left edge
            px = -i, py = 0,
            dir = RIGHT, inEdge = LEFT,
            disallow = UP, prevX = RIGHT,
            hp = hpPair[(i - 1) % 2 + 1],
            head = i == 1,
        }
    end
    Sfx.wave()
    Harness.count("waves")
end

-- lower is better; factor weights mirror their priority order
local function rank(seg, d, occ)
    local nx, ny = seg.cx + DX[d], seg.cy + DY[d]
    local score = 0
    if nx < 0 or nx >= C.COLS or ny < 0 or ny >= C.ROWS then
        score = score + 64 -- off the grid
    end
    if d == seg.inEdge then score = score + 32 end    -- doubling back
    if d == seg.disallow then score = score + 16 end
    if occ[nx .. "," .. ny] or occ[seg.cx .. "," .. seg.cy .. "," .. d] then
        score = score + 8 -- claimed, or head-on with another segment
    end
    local rock = Grid.get(nx, ny) ~= nil
    if rock then score = score + 4 end
    -- prefer sidling, unless a rock blocks the way sideways
    if rock == isHoriz(d) then score = score + 2 end
    if d == seg.prevX then score = score + 1 end      -- snake, don't shuttle
    return score
end

local function step()
    local occ = {}
    for _, seg in ipairs(G.segs) do
        local best, bestScore = UP, math.huge
        for d = 1, 4 do
            local s = rank(seg, d, occ)
            if s < bestScore then best, bestScore = d, s end
        end
        seg.dir = best
        if isHoriz(best) then seg.prevX = best end
        local nx, ny = seg.cx + DX[best], seg.cy + DY[best]
        Grid.damage(nx, ny, 99) -- chew through whatever is in the way
        occ[nx .. "," .. ny] = true
        occ[nx .. "," .. ny .. "," .. inverse(best)] = true
    end
    -- everyone moves together
    for _, seg in ipairs(G.segs) do
        seg.px, seg.py = seg.cx, seg.cy
        seg.cx = seg.cx + DX[seg.dir]
        seg.cy = seg.cy + DY[seg.dir]
        seg.inEdge = inverse(seg.dir)
        -- once down in the zone, bounce between its top and the floor
        if seg.cy == C.ZONE_ROW then seg.disallow = UP end
        if seg.cy == C.ROWS - 1 then seg.disallow = DOWN end
    end
end

function Myriapod.update()
    if #G.segs == 0 then return end
    G.stepT = G.stepT + Myriapod.pace() * C.DT
    while G.stepT >= 1 do
        G.stepT = G.stepT - 1
        step()
    end
end

function Myriapod.segPos(seg)
    local x0, y0 = Grid.cellPos(seg.px, seg.py)
    local x1, y1 = Grid.cellPos(seg.cx, seg.cy)
    return x0 + (x1 - x0) * G.stepT, y0 + (y1 - y0) * G.stepT
end

local function killSegment(i, sx, sy)
    local seg = table.remove(G.segs, i)
    G.addScore(10)
    G.burst(sx, sy, 8)
    G.addExplosion(sx, sy, 2)
    Sfx.segDie()
    Harness.count("segmentsKilled")
    -- the chain breaks here: whoever followed leads their own chain now
    local follower = G.segs[i]
    if follower and not follower.head then
        follower.head = true
        Harness.count("splits")
    end
    -- the husk hardens into a fresh rock
    if Grid.inBounds(seg.cx, seg.cy) and not Grid.get(seg.cx, seg.cy)
        and not Player.overlapsCell(seg.cx, seg.cy) then
        Grid.set(seg.cx, seg.cy, C.ROCK_HP)
    end
end

function Myriapod.hitAt(x, y)
    for i, seg in ipairs(G.segs) do
        local sx, sy = Myriapod.segPos(seg)
        if math.abs(sx - x) < 8 and math.abs(sy - y) < 8 then
            seg.hp = seg.hp - 1
            if seg.hp <= 0 then
                killSegment(i, sx, sy)
            else
                G.burst(sx, sy, 3)
                G.addExplosion(sx, sy, 2)
                Sfx.segHit()
            end
            return true
        end
    end
    return false
end

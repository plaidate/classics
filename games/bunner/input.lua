-- D-pad hops, crank-forward hops, and the smoke-test autopilot.

Input = {}

local crankAcc = 0
local auto = { t = 0 }

local function moverAt(row, x, t, margin)
    for _, m in ipairs(row.things) do
        local mx = m.x + (m.dx or row.dx) * t
        if math.abs(x - mx) < m.w / 2 + margin then return m end
    end
    return nil
end

-- would this cell be survivable t seconds from now?
local function cellSafe(row, x, t)
    if not row or not Rows.allowMovement(row, x) then return false end
    if row.kind == "road" then
        if moverAt(row, x, t, 12 + math.abs(row.dx) * 0.5) then return false end
    elseif row.kind == "rail" and row.idx == 2 then
        if row.warnT then return false end
        if moverAt(row, x, t, 30 + C.TRAIN_SPEED * 0.4) then return false end
    elseif row.kind == "water" then
        if not moverAt(row, x, t, -10) then return false end
    end
    return true
end

local function autoDir()
    local p = G.player
    local t = C.HOP_TIME
    if cellSafe(Rows.at(p.y - C.ROW_H), p.x, t) and math.random() < 0.95 then
        return "up"
    end
    local here = Rows.at(p.y)
    local first = math.random() < 0.5 and "left" or "right"
    for _, d in ipairs({ first, first == "left" and "right" or "left" }) do
        local nx = p.x + (d == "left" and -C.CELL_W or C.CELL_W)
        if here and cellSafe(here, nx, t) and cellSafe(here, nx, t + 0.4) then
            -- sidestep if it opens the row above, or sometimes just to wander
            if cellSafe(Rows.at(p.y - C.ROW_H), nx, t + 0.3) or math.random() < 0.3 then
                return d
            end
        end
    end
    if math.random() < 0.1 and p.y - G.camY < 120 then
        local down = Rows.at(p.y + C.ROW_H)
        if cellSafe(down, p.x, t) then return "down" end
    end
    return nil
end

-- returns: hop direction (or nil), start
function Input.gather()
    if Harness.enabled then
        local p = G.player
        if not p or p.state ~= "alive" or p.hopT > 0 then return nil, true end
        auto.t = auto.t - C.DT
        if auto.t > 0 then return nil, true end
        auto.t = 0.12 + math.random() * 0.18
        return autoDir(), true
    end

    local dir
    if playdate.buttonJustPressed(playdate.kButtonUp) then dir = "up"
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then dir = "down"
    elseif playdate.buttonJustPressed(playdate.kButtonLeft) then dir = "left"
    elseif playdate.buttonJustPressed(playdate.kButtonRight) then dir = "right"
    end

    -- cranking forward is an alternative way to press up
    crankAcc = math.max(0, crankAcc + playdate.getCrankChange())
    if not dir and crankAcc >= C.CRANK_HOP then
        crankAcc = crankAcc - C.CRANK_HOP
        dir = "up"
    end

    return dir, playdate.buttonJustPressed(playdate.kButtonA)
end

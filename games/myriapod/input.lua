-- D-pad flying, held-button autofire, crank nudge, and the smoke-test autopilot.

Input = {}

local auto = { dodgeT = 0, dy = 0 }

-- last movement input, recorded for the ship's facing sprite (visual only)
Input.lastDx, Input.lastDy = 0, 0

-- returns: dx, dy, fire, start, nudge (crank pixels of fine strafe)
function Input.gather()
    if Harness.enabled then
        -- strafe under the nearest segment, dodge vertically at random
        local dx, bestX, bestD = 0, nil, nil
        for _, seg in ipairs(G.segs) do
            local sx = Myriapod.segPos(seg)
            local d = math.abs(sx - G.player.x)
            if not bestD or d < bestD then bestD, bestX = d, sx end
        end
        if bestX then
            if bestX < G.player.x - 4 then
                dx = -1
            elseif bestX > G.player.x + 4 then
                dx = 1
            end
        end
        auto.dodgeT = auto.dodgeT - C.DT
        if auto.dodgeT <= 0 then
            auto.dodgeT = 0.3 + math.random() * 0.5
            auto.dy = math.random(-1, 1)
        end
        Input.lastDx, Input.lastDy = dx, auto.dy
        return dx, auto.dy, true, true, 0
    end

    local dx, dy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        dx = -1
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        dx = 1
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        dy = -1
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        dy = 1
    end

    local fire = playdate.buttonIsPressed(playdate.kButtonA)
        or playdate.buttonIsPressed(playdate.kButtonB)
    local start = playdate.buttonJustPressed(playdate.kButtonA)
        or playdate.buttonJustPressed(playdate.kButtonB)
    local nudge = playdate.getCrankChange() * C.CRANK_NUDGE
    Input.lastDx, Input.lastDy = dx, dy
    return dx, dy, fire, start, nudge
end

-- Input gathering: d-pad/buttons/crank, plus the smoke-test autopilot.

Input = {}

local function autopilot()
    local p = G.player
    if not p then return 0, 0, false, false, true, 0 end

    local auto = G.auto
    auto.t = auto.t - 1
    if auto.t <= 0 then
        auto.t = 10 + math.random(20)

        -- chase the nearest live enemy's column and altitude...
        local tx, ty = nil, nil
        local bestD = math.huge
        for _, e in ipairs(G.enemies) do
            if e.state == "alive" then
                local dx = Util.wrapSigned(e.x - p.x)
                if math.abs(dx) < bestD then
                    bestD = math.abs(dx)
                    tx, ty = dx, e.y
                end
            end
        end
        -- ...unless a human is tumbling nearby, in which case go catch them
        for _, h in ipairs(G.humans) do
            if h.falling and not h.carrier
                    and math.abs(Util.wrapSigned(h.x - p.x)) < 250 then
                tx, ty = Util.wrapSigned(h.x - p.x), h.y
            end
        end
        -- with a passenger aboard, skim the deck to set them down
        if p.carried then ty = C.LEVEL_H - 30 end

        if tx and tx ~= 0 then
            auto.x = Util.sign(tx)
        else
            auto.x = (math.random() < 0.5) and 1 or -1
        end
        if ty then
            auto.y = (ty < p.y - 8) and -1 or ((ty > p.y + 8) and 1 or 0)
        else
            auto.y = math.random(-1, 1)
        end
    end
    return auto.x, auto.y, true, math.random() < 0.01, true, 0
end

-- returns: xIn, yIn, fire (held), reverse (pressed), start (pressed), crank degrees
function Input.gather()
    if Harness.enabled then return autopilot() end

    local x, y = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then x = -1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then x = 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then y = -1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then y = 1 end

    local fire = playdate.buttonIsPressed(playdate.kButtonA)
    local reverse = playdate.buttonJustPressed(playdate.kButtonB)
    local start = playdate.buttonJustPressed(playdate.kButtonA)
        or playdate.buttonJustPressed(playdate.kButtonB)
    local crank = playdate.getCrankChange()

    return x, y, fire, reverse, start, crank
end

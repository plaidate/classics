-- Input gathering: d-pad/buttons and the autopilot used by the smoke-test
-- harness.

Input = {}

-- returns: dir, jump, blowPress, blowHeld, start
function Input.gather()
    if Harness.enabled then
        local auto = G.auto
        auto.t = auto.t - C.DT
        local c = G.player
        if auto.t <= 0 then
            auto.t = 0.25 + math.random() * 0.45
            local target, best = nil, 1e9
            if c then
                for _, r in ipairs(G.robots) do
                    local d = math.abs(r.x - c.x)
                    if d < best then best, target = d, r end
                end
            end
            local roll = math.random()
            if target and roll < 0.7 then
                auto.dir = (target.x >= c.x) and 1 or -1
            elseif roll < 0.85 then
                auto.dir = (math.random(2) == 1) and 1 or -1
            else
                auto.dir = 0
            end
        end
        local blowPress = false
        if auto.holdT > 0 then
            auto.holdT = auto.holdT - C.DT
        elseif math.random() < 0.12 then
            blowPress = true
            auto.holdT = math.random() * 0.7
        end
        return auto.dir, math.random() < 0.06, blowPress, auto.holdT > 0, true
    end

    local dir = 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then dir = -1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then dir = 1 end
    local jump = playdate.buttonJustPressed(playdate.kButtonA)
    local blowPress = playdate.buttonJustPressed(playdate.kButtonB)
    local blowHeld = playdate.buttonIsPressed(playdate.kButtonB)
    return dir, jump, blowPress, blowHeld, jump
end

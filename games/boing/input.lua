-- Controls. 1P: crank or d-pad drives the left bat. 2P on one device:
-- player 1 takes the d-pad (left bat), player 2 takes the crank (right bat).

Input = {}

local auto = { t = 0, jitter = 0 }

-- returns: p1dy, p2dy, confirm, up, down
function Input.gather()
    if Harness.enabled then
        -- the left bat chases the ball, imperfectly
        local dy = 0
        if G.ball and G.bats then
            auto.t = auto.t - C.DT
            if auto.t <= 0 then
                auto.t = 0.4
                auto.jitter = math.random(-20, 20)
            end
            dy = Util.clamp((G.ball.y + auto.jitter) - G.bats[1].y,
                -C.PLAYER_SPEED, C.PLAYER_SPEED)
        end
        return dy, 0, true, false, false
    end

    local p1dy = 0
    if playdate.buttonIsPressed(playdate.kButtonUp) then p1dy = -C.PLAYER_SPEED end
    if playdate.buttonIsPressed(playdate.kButtonDown) then p1dy = C.PLAYER_SPEED end

    local crankDy = playdate.getCrankChange() * C.CRANK_RATIO

    if not G.twoPlayer and p1dy == 0 then
        p1dy = crankDy -- 1P: crank also drives the left bat
    end

    local p2dy = G.twoPlayer and crankDy or 0

    local confirm = playdate.buttonJustPressed(playdate.kButtonA)
    local up = playdate.buttonJustPressed(playdate.kButtonUp)
    local down = playdate.buttonJustPressed(playdate.kButtonDown)
    return p1dy, p2dy, confirm, up, down
end

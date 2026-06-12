-- Input gathering: d-pad runs, A charges kicks, B switches, plus the autopilot.

Input = {}

local auto = { holdT = 0, switchT = 0 }

local function autopilot()
    local i = { dx = 0, dy = 0, kickHeld = false, kickUp = false,
        switch = false, start = true, menuUp = false, menuDown = false }
    local p, ball = G.ctl, G.ball
    if not (p and ball) or G.state ~= "play" then return i end
    local tx, ty
    if ball.owner == p then
        tx, ty = C.CENTER_X, C.PITCH_T -- straight at the open goal
        auto.holdT = auto.holdT + C.DT
        local pressured = false
        for _, q in ipairs(G.players) do
            if q.team ~= p.team and Util.dist(p.x, p.y, q.x, q.y) < 28 then
                pressured = true
            end
        end
        if auto.holdT > 0.3
            and (Util.dist(p.x, p.y, tx, ty) < C.SHOOT_RANGE or pressured) then
            i.kickUp = true
            auto.holdT = 0
        else
            i.kickHeld = true
        end
    else
        auto.holdT = 0
        tx, ty = ball.x, ball.y
        auto.switchT = auto.switchT + C.DT
        if auto.switchT > 4 then
            i.switch = true
            auto.switchT = 0
        end
    end
    local dx, dy = tx - p.x, ty - p.y
    if math.abs(dx) > 3 then i.dx = (dx > 0) and 1 or -1 end
    if math.abs(dy) > 3 then i.dy = (dy > 0) and 1 or -1 end
    return i
end

function Input.gather()
    if Harness.enabled then return autopilot() end
    local i = { dx = 0, dy = 0 }
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        i.dx = -1
    elseif playdate.buttonIsPressed(playdate.kButtonRight) then
        i.dx = 1
    end
    if playdate.buttonIsPressed(playdate.kButtonUp) then
        i.dy = -1
    elseif playdate.buttonIsPressed(playdate.kButtonDown) then
        i.dy = 1
    end
    i.kickHeld = playdate.buttonIsPressed(playdate.kButtonA)
    i.kickUp = playdate.buttonJustReleased(playdate.kButtonA)
    i.switch = playdate.buttonJustPressed(playdate.kButtonB)
    i.start = playdate.buttonJustPressed(playdate.kButtonA)
    i.menuUp = playdate.buttonJustPressed(playdate.kButtonUp)
    i.menuDown = playdate.buttonJustPressed(playdate.kButtonDown)
    return i
end

-- The ball: dribbling, kick physics, possession changes, goal detection.

Ball = {}

function Ball.reset()
    G.ball = { x = C.CENTER_X, y = C.CENTER_Y, vx = 0, vy = 0, owner = nil, wait = 0 }
end

function Ball.kick(dirx, diry, power, kicker)
    local ball = G.ball
    ball.vx, ball.vy = dirx * power, diry * power
    ball.owner = nil
    kicker.holdoff = C.KICK_HOLDOFF
    Harness.count("kicks")
    Sfx.kick(power)
end

-- a teammate roughly along our facing line, close enough to reach
local function passTarget(p)
    local best, bd
    for _, q in ipairs(G.players) do
        if q.team == p.team and q ~= p then
            local nx, ny, d = Util.norm(q.x - p.x, q.y - p.y)
            if d > 0 and d < C.PASS_RANGE and nx * p.fx + ny * p.fy > 0.8 then
                if not best or d < bd then best, bd = q, d end
            end
        end
    end
    return best, bd
end

local function humanKick(p, charge)
    local power = Util.clamp(C.KICK_MIN + charge * C.CHARGE_RATE, C.KICK_MIN, C.KICK_MAX)
    local ball = G.ball
    local dirx, diry = p.fx, p.fy
    local tgt, td = passTarget(p)
    if tgt then
        -- lead the receiver a little so the pass lands in stride
        local nx, ny, d = Util.norm(tgt.x + p.fx * td * 0.3 - ball.x,
            tgt.y + p.fy * td * 0.3 - ball.y)
        if d > 0 then dirx, diry = nx, ny end
        G.ctl = tgt
        Harness.count("passes")
    else
        G.ctl = Players.nearestTo(1, ball.x + dirx * 130, ball.y + diry * 130)
    end
    Ball.kick(dirx, diry, power, p)
end

local function axis(pos, vel, lo, hi)
    pos = pos + vel * C.DT
    if pos < lo then
        pos, vel = 2 * lo - pos, -vel
    elseif pos > hi then
        pos, vel = 2 * hi - pos, -vel
    end
    return pos, vel * C.FRICTION
end

function Ball.update(inp)
    local ball = G.ball
    ball.wait = math.max(0, ball.wait - C.DT)

    if ball.owner then
        local o = ball.owner
        local tx = o.x + o.fx * C.DRIBBLE_LEAD
        local ty = o.y + o.fy * C.DRIBBLE_LEAD
        local nx = ball.x + (tx - ball.x) * 0.45
        local ny = ball.y + (ty - ball.y) * 0.45
        if Pitch.onPitch(nx, ny) then
            ball.x, ball.y = nx, ny
        else
            -- ran out of room: the ball squirts loose
            o.holdoff = 1
            ball.vx, ball.vy = o.fx * 60, o.fy * 60
            ball.owner = nil
        end
    else
        local lx, hx = Pitch.ballBoundsX(ball.y)
        local ly, hy = Pitch.ballBoundsY(ball.x)
        ball.x, ball.vx = axis(ball.x, ball.vx, lx, hx)
        ball.y, ball.vy = axis(ball.y, ball.vy, ly, hy)
    end

    -- possession: running into the ball takes it (that's the tackle, too)
    for _, p in ipairs(G.players) do
        if p.holdoff <= 0 and (not ball.owner or ball.owner.team ~= p.team)
            and Util.dist(p.x, p.y, ball.x, ball.y) <= C.CONTROL_DIST then
            if ball.owner then
                ball.owner.holdoff = C.STEAL_HOLDOFF
                Harness.count("tackles")
            end
            ball.owner = p
            ball.vx, ball.vy = 0, 0
            ball.wait = G.diff().patience
            if p.team == 1 then G.ctl = p end
            G.prekick, G.kickPlayer = false, nil
        end
    end

    if ball.y < C.PITCH_T - 2 and math.abs(ball.x - C.CENTER_X) < C.GOAL_HALF_W then
        Main.goalScored(1)
        return
    elseif ball.y > C.PITCH_B + 2 and math.abs(ball.x - C.CENTER_X) < C.GOAL_HALF_W then
        Main.goalScored(2)
        return
    end

    local o = ball.owner
    if o and o == G.ctl then
        if inp.kickHeld then
            G.charge = (G.charge or 0) + C.DT
        end
        if inp.kickUp then
            humanKick(o, G.charge or 0)
            G.charge = nil
        end
    else
        G.charge = nil
        if o and o.team == 2 and ball.wait <= 0 then
            AI.cpuKick(o)
        end
    end
end

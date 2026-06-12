-- AI brains: formation positioning, chasing, marking, and CPU kicking.

AI = {}

-- a player joins the play when the ball is near his patch of the pitch
function AI.active(p)
    return math.abs(G.ball.y - p.hy) < 250
end

-- lower is better: keep away from our goal and from opponents,
-- favour the middle of the pitch, and push toward the goal we attack
function AI.cost(x, y, team)
    local ownGoalY = (team == 1) and C.PITCH_B or C.PITCH_T
    local v = 1400 / math.max(20, Util.dist(x, y, C.CENTER_X, ownGoalY))
    for _, q in ipairs(G.players) do
        if q.team ~= team then
            v = v + 1600 / math.max(12, Util.dist(x, y, q.x, q.y))
        end
    end
    v = v + (x - C.CENTER_X) ^ 2 / 80
    v = v + ((team == 1) and y or -y) * 2
    return v
end

-- pick one or two opponents to hound the carrier, aiming ahead of him
function AI.assign()
    for _, p in ipairs(G.players) do p.chase = nil end
    local o = G.ball.owner
    if not o or G.prekick then return end
    local cands = {}
    for _, p in ipairs(G.players) do
        if p.team ~= o.team and p ~= G.ctl and p.holdoff <= 0 then
            cands[#cands + 1] = p
        end
    end
    table.sort(cands, function(a, b)
        return Util.dist(a.x, a.y, o.x, o.y) < Util.dist(b.x, b.y, o.x, o.y)
    end)
    local leads = { 6, 30 }
    for i = 1, math.min(G.diff().chasers, #cands) do
        cands[i].chase = leads[i]
    end
end

local function carrierTarget(p)
    local best, bx, by
    for i = -2, 2 do
        local a = i * 0.7854
        local ca, sa = math.cos(a), math.sin(a)
        local dx = p.fx * ca - p.fy * sa
        local dy = p.fx * sa + p.fy * ca
        local x, y = p.x + dx * 12, p.y + dy * 12
        local v = AI.cost(x, y, p.team) + math.abs(i) * 4
        if not best or v < best then best, bx, by = v, x, y end
    end
    return bx, by, C.CARRY_SPEED + ((p.team == 2) and G.diff().boost or 0)
end

-- chase the ball along its rolling path instead of trailing behind it
local function intercept(p)
    local ball = G.ball
    local tx, ty = ball.x, ball.y
    local vx, vy = ball.vx, ball.vy
    for frames = 0, 50 do
        local reach = C.INTERCEPT_SPEED * C.DT * frames + C.CONTROL_DIST
        if Util.dist(p.x, p.y, tx, ty) <= reach then break end
        if vx * vx + vy * vy < 100 then break end
        tx, ty = tx + vx * C.DT, ty + vy * C.DT
        vx, vy = vx * C.FRICTION, vy * C.FRICTION
    end
    return tx, ty
end

function AI.target(p)
    local ball = G.ball
    if G.prekick then
        if p == G.kickPlayer then
            return ball.x, ball.y, C.INTERCEPT_SPEED
        end
        return p.kx, p.ky, C.RUN_SPEED
    end
    local owner = ball.owner
    if owner == p then
        return carrierTarget(p)
    end
    if owner and owner.team == p.team then
        if AI.active(p) then
            -- support the attack: drift between home and a spot beyond the ball
            local ad = Pitch.attackDir(p.team)
            return (ball.x + p.hx) / 2, (ball.y + ad * 220 + p.hy) / 2, C.RUN_SPEED
        end
        return p.hx, p.hy, C.RUN_SPEED
    end
    if owner then
        if p.chase then
            local tx = Util.clamp(owner.x + owner.fx * p.chase, 30, C.WORLD_W - 30)
            local ty = Util.clamp(owner.y + owner.fy * p.chase, 40, C.WORLD_H - 40)
            return tx, ty, C.CHASE_SPEED + ((p.team == 2) and G.diff().boost or 0)
        end
        if AI.active(p.mark) then
            if p.team == 1 then
                return ball.x, ball.y, C.RUN_SPEED
            end
            -- get between the ball and the man we mark
            return (ball.x + p.mark.x) / 2, (ball.y + p.mark.y) / 2,
                C.RUN_SPEED + G.diff().boost
        end
        return p.hx, p.hy, C.RUN_SPEED
    end
    if AI.active(p) then
        local tx, ty = intercept(p)
        return tx, ty, C.INTERCEPT_SPEED + ((p.team == 2) and G.diff().boost * 0.5 or 0)
    end
    return p.hx, p.hy, C.RUN_SPEED
end

-- is an opponent parked on the line between the ball and (tx, ty)?
local function laneBlocked(p, tx, ty)
    local ball = G.ball
    local vx, vy, d0 = Util.norm(tx - ball.x, ty - ball.y)
    for _, q in ipairs(G.players) do
        if q.team ~= p.team then
            local wx, wy, d1 = Util.norm(q.x - ball.x, q.y - ball.y)
            if d1 > 0 and d1 < d0 and vx * wx + vy * wy > 0.8 then
                return true
            end
        end
    end
    return false
end

-- CPU carrier: shoot when the goal is on, otherwise pass to a better-placed mate
function AI.cpuKick(p)
    local ball = G.ball
    local gx = C.CENTER_X + math.random(-C.GOAL_HALF_W + 8, C.GOAL_HALF_W - 8)
    local gy = Pitch.goalY(p.team)
    local sx, sy, gd = Util.norm(gx - ball.x, gy - ball.y)
    if gd > 0 and gd < C.SHOOT_RANGE and sx * p.fx + sy * p.fy > 0.4
        and not laneBlocked(p, gx, gy) then
        Ball.kick(sx, sy, C.KICK_MAX, p)
        return
    end
    local here = AI.cost(p.x, p.y, p.team)
    local tgt, td
    for _, q in ipairs(G.players) do
        if q.team == p.team and q ~= p then
            local nx, ny, d = Util.norm(q.x - p.x, q.y - p.y)
            if d > 20 and d < C.PASS_RANGE and nx * p.fx + ny * p.fy > 0.5
                and AI.cost(q.x, q.y, p.team) + 25 < here
                and not laneBlocked(p, q.x, q.y) then
                if not tgt or d < td then tgt, td = q, d end
            end
        end
    end
    if tgt then
        local nx, ny = Util.norm(tgt.x - ball.x, tgt.y - ball.y)
        local power = Util.clamp(160 + td * 0.9, C.KICK_MIN, C.KICK_MAX)
        Ball.kick(nx, ny, power, p)
        Harness.count("passes")
    end
end

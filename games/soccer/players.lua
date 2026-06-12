-- The fourteen players: formations, kickoffs, control switching, movement.

Players = {}

-- team 1 homes (defends the bottom goal); team 2 is the mirror image
local FORMATION = {
    { 140, 314 }, { 260, 257 }, { 80, 486 }, { 200, 428 },
    { 320, 543 }, { 140, 714 }, { 260, 657 },
}

local function newPlayer(hx, hy, team)
    return {
        x = hx, y = hy, hx = hx, hy = hy, kx = hx, ky = hy,
        team = team, fx = 0, fy = (team == 1) and -1 or 1,
        holdoff = 0, chase = nil, mark = nil,
        animT = 0, moving = false,
    }
end

function Players.build()
    G.players = {}
    for _, f in ipairs(FORMATION) do
        G.players[#G.players + 1] = newPlayer(f[1], f[2], 1)
        G.players[#G.players + 1] = newPlayer(C.WORLD_W - f[1], C.WORLD_H - f[2], 2)
    end
    -- mirrored marking pairs: each forward picks up the far team's defender
    local n = #G.players
    for i, p in ipairs(G.players) do
        p.mark = G.players[n + 1 - i]
    end
end

function Players.toKickoff(kickTeam)
    for _, p in ipairs(G.players) do
        -- everyone retreats into their own half, loosely on station
        p.kx = Util.clamp(p.hx + math.random(-12, 12), 24, C.WORLD_W - 24)
        p.ky = p.hy / 2 + ((p.team == 1) and 314 or 86) + math.random(-8, 8)
        p.x, p.y = p.kx, p.ky
        p.fx, p.fy = 0, (p.team == 1) and -1 or 1
        p.holdoff, p.chase = 0, nil
        p.animT, p.moving = 0, false
    end
    local kp = Players.nearestTo(kickTeam, C.CENTER_X, C.CENTER_Y)
    kp.x = C.CENTER_X + ((kickTeam == 1) and -16 or 16)
    kp.y = C.CENTER_Y
    kp.kx, kp.ky = kp.x, kp.y
    G.kickPlayer = kp
    G.prekick = true
    G.ctl = (kickTeam == 1) and kp or Players.nearestTo(1, C.CENTER_X, C.CENTER_Y)
end

function Players.nearestTo(team, x, y)
    local best, bd
    for _, p in ipairs(G.players) do
        if p.team == team then
            local d = Util.dist(p.x, p.y, x, y)
            if not best or d < bd then best, bd = p, d end
        end
    end
    return best
end

-- B button: jump to the nearest teammate, favouring anyone goalside
function Players.switchControl()
    local ball = G.ball
    local best, bd
    for _, p in ipairs(G.players) do
        if p.team == 1 then
            local d = Util.dist(p.x, p.y, ball.x, ball.y)
            if ball.owner and ball.owner.team == 2 and p.y > ball.y then
                d = d / 2
            end
            if not best or d < bd then best, bd = p, d end
        end
    end
    if best ~= G.ctl then
        G.ctl = best
        Sfx.switch()
    end
end

local function stepTo(p, nx, ny, step)
    if Pitch.canWalk(p.x + nx * step, p.y) then p.x = p.x + nx * step end
    if Pitch.canWalk(p.x, p.y + ny * step) then p.y = p.y + ny * step end
    p.fx, p.fy = nx, ny
    p.animT = p.animT + step
    p.moving = true
end

local function faceBall(p)
    p.moving = false
    local fx, fy, d = Util.norm(G.ball.x - p.x, G.ball.y - p.y)
    if d > 0 then p.fx, p.fy = fx, fy end
end

local function steer(p, inp)
    if inp.dx ~= 0 or inp.dy ~= 0 then
        local nx, ny = Util.norm(inp.dx, inp.dy)
        local speed = (G.ball.owner == p) and C.CTL_CARRY_SPEED or C.CTL_SPEED
        stepTo(p, nx, ny, speed * C.DT)
    else
        p.moving = false -- keep facing as-is so a standing kick can be aimed
    end
end

function Players.update(inp)
    AI.assign()
    for _, p in ipairs(G.players) do
        p.holdoff = math.max(0, p.holdoff - C.DT)
        if p == G.ctl and (not G.prekick or p == G.kickPlayer) then
            steer(p, inp)
        else
            local tx, ty, speed = AI.target(p)
            local nx, ny, d = Util.norm(tx - p.x, ty - p.y)
            if d > 1 then
                stepTo(p, nx, ny, math.min(d, speed * C.DT))
            else
                faceBall(p)
            end
        end
    end
end

-- Ball flight: whole-pixel sub-steps, axis-by-axis bounces, bat physics,
-- the creeping speed-up, and the multiball split.

Ball = {}

function Ball.newServing()
    return {
        x = 0, y = 0,
        dx = 0, dy = 0,        -- unit direction
        stuck = true,
        offset = C.SERVE_OFFSET, -- x offset from bat centre while stuck
        speed = C.BALL_START_SPEED,
        speedT = 0,            -- frames accrued toward the next speed-up
        sinceBat = 0,          -- frames since last bat contact
        sinceBrick = 0,        -- frames since last brick damaged
    }
end

-- Where would the bat send this ball? Returns onBat, dirX, dirY.
local function batDeflection(b)
    local off = b.x - G.bat.x
    local reach = Bat.halfWidth() + C.BALL_R
    if math.abs(off) < reach then
        local nx, ny = Util.normalize(off / reach, -0.5)
        return true, nx, ny
    end
    return false, 0, -1
end

local function bounceSound(kind)
    if kind == "wall" then
        Sfx.play("hit_wall")
    else
        Sfx.play("hit_brick")
    end
end

function Ball.update(b, serve)
    b.sinceBrick = b.sinceBrick + 1

    if b.stuck then
        b.x = G.bat.x + b.offset
        b.y = C.BAT_Y - C.BALL_R
        if serve then
            b.stuck = false
            Harness.count("serves")
            local _, nx, ny = batDeflection(b)
            b.dx, b.dy = nx, ny
        end
        return
    end

    b.sinceBat = b.sinceBat + 1

    -- the ball creeps faster over time; faster still when it hasn't seen
    -- the bat in a while, and on a longer cycle once it's already quick
    b.speedT = b.speedT + ((b.sinceBat > C.NEGLECT_SECS * 30) and 2 or 1)
    local cycle = 30 * (b.speed < C.FAST_THRESHOLD
        and C.SPEED_UP_SECS or C.SPEED_UP_SECS_FAST)
    if b.speedT > cycle
        or (b.speedT > cycle * 0.75 and b.sinceBat > cycle * 0.75) then
        b.speed = math.min(b.speed + 1, C.BALL_MAX_SPEED)
        b.speedT = 0
    end

    for _ = 1, b.speed do
        -- x axis step
        b.x = b.x + b.dx
        local hx, hy, ring, kind = Bricks.collide(b.x, b.y, b.dx, b.dy, C.BALL_R)
        if hx then
            b.dx = -b.dx
            b.x = b.x + b.dx
            if ring then G.addImpact(hx, hy, 12) end
            if kind == "brick" then b.sinceBrick = 0 end
            bounceSound(kind)
        end

        -- y axis step
        local prevY = b.y
        b.y = b.y + b.dy
        hx, hy, ring, kind = Bricks.collide(b.x, b.y, b.dx, b.dy, C.BALL_R)
        if hx then
            b.dy = -b.dy
            b.y = b.y + b.dy
            if ring then G.addImpact(hx, hy, 12) end
            if kind == "brick" then b.sinceBrick = 0 end
            bounceSound(kind)
        elseif b.dy > 0 then
            -- falling: maybe the bat catches it
            local crossedTop = prevY + C.BALL_R <= C.BAT_Y
                and b.y + C.BALL_R > C.BAT_Y
            if crossedTop then
                local onBat, nx, ny = batDeflection(b)
                if onBat then
                    if G.bat.form == Bat.MAGNET then
                        b.stuck = true
                        b.offset = b.x - G.bat.x
                        b.dx, b.dy = 0, 0
                        Sfx.play("ball_stick")
                    else
                        b.dx, b.dy = nx, ny
                        Sfx.play("hit_fast")
                    end
                    b.sinceBat = 0
                    G.addImpact(b.x, b.y, 12)
                    if b.stuck then break end
                end
            elseif b.y + C.BALL_R > C.BAT_Y and b.y < C.BAT_Y + 7 then
                -- clipped the bat's end: a violent sideways deflection
                local onBat = batDeflection(b)
                if onBat then
                    local sign = (b.x > G.bat.x) and 1 or -1
                    b.dx, b.dy = Util.normalize(sign, -0.1 - math.random() * 0.2)
                    b.sinceBat = 0
                    b.speed = math.min(b.speed + 4, C.BALL_MAX_SPEED)
                    G.addImpact(b.x, C.BAT_Y, 12)
                    Sfx.play("hit_veryfast")
                end
            end
        end
    end
end

-- Multiball: one ball becomes three, fanned out at 120-degree turns.
function Ball.split(b)
    local out = {}
    for i = 0, 2 do
        local dx, dy = Util.rotate(b.dx, b.dy, i * 120)
        if math.abs(dy) < 0.15 then
            -- too horizontal (or a stuck ball's zero vector): kick it upward
            dx, dy = Util.normalize(math.random() * 2 - 1, -1)
        end
        local nb = Ball.newServing()
        nb.x, nb.y, nb.dx, nb.dy = b.x, b.y, dx, dy
        nb.stuck = false
        nb.speed = b.speed
        out[#out + 1] = nb
    end
    return out
end

function Ball.nudgeSpeeds(delta)
    for _, b in ipairs(G.balls) do
        b.speed = Util.clamp(b.speed + delta, C.BALL_MIN_SPEED, C.BALL_MAX_SPEED)
    end
end

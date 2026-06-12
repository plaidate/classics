-- The hero: running, jumping (with coyote time, a buffered jump input, and a
-- shorter hop when A is released early), ladder climbing, stomping, dying.
-- (x, y) is the feet position; the collision box is 10x20 above the feet.

Player = {}

local clamp = Util.clamp
local sign = Util.sign

function Player.new()
    local p = {}
    Player.resetTo(p)
    return p
end

function Player.resetTo(p)
    p.x, p.y = G.startX, G.startY
    p.vx, p.vy = 0, 0
    p.facing = 1
    p.landed = false
    p.climbing = false
    p.hurt = false
    p.moving = false
    p.coyote = 0
    p.buffer = 0
    p.lowGravT = 0
    p.stompT = 0
    p.stompedLast = false
    p.changeDirT = 0
    p.fallT = 0
    p.climbT = 0
    p.jumping = false
end

-- respawn at the level start, blasting any enemy camped nearby
function Player.respawn()
    local p = G.player
    Player.resetTo(p)
    G.timeLeft = C.LEVEL_TIME * 30
    for _, e in ipairs(G.enemies) do
        if not e.dying then
            local dx, dy = e.x - p.x, e.y - p.y
            if dx * dx + dy * dy < C.SPAWN_CLEAR_RADIUS * C.SPAWN_CLEAR_RADIUS then
                Enemies.destroy(e)
            end
        end
    end
end

local function startJump(p)
    p.vy = C.JUMP_VY
    p.landed = false
    p.climbing = false
    p.jumping = true
    p.coyote = 0
    p.buffer = 0
    p.lowGravT = C.LOW_GRAV_FRAMES
    p.fallT = 0
    Sfx.play("jump")
end

local function die(p)
    p.hurt = true
    p.climbing = false
    p.vy = C.HURT_VY
    p.fallT = 0
    Fx.add("loselife_", 8, 2, p.x, p.y - 17)
    Sfx.play("player_death")
end

-- kill from outside the module (the clock running out)
function Player.kill()
    local p = G.player
    if p and not p.hurt then die(p) end
end

local function overlapsEnemy(p, e)
    return math.abs(p.x - e.x) < C.PLAYER_HALF_W + e.w / 2
        and p.y - C.PLAYER_H < e.y
        and p.y > e.y - e.h
end

local function checkEnemies(p)
    local stompedAny = false
    for _, e in ipairs(G.enemies) do
        if not e.dying and overlapsEnemy(p, e) then
            -- land on the head, or get hurt: the head zone is the top 20%
            -- of the enemy box, opened up to 50% while moving downward
            local threshold = (e.y - e.h) + e.h * (p.vy > 0 and 0.5 or 0.2)
            if p.y < threshold or p.stompedLast then
                Enemies.stomp(e)
                stompedAny = true
                p.vy = C.STOMP_BOUNCE_VY
                p.landed = false
                p.climbing = false
                p.stompT = 2
            else
                die(p)
                break
            end
        end
    end
    p.stompedLast = stompedAny
end

local function updateClimb(p, inp)
    p.fallT = 0
    if p.buffer > 0 then
        startJump(p)
        return
    end
    local dy = (inp.up and -1 or 0) + (inp.down and 1 or 0)
    if dy < 0 then
        for _ = 1, C.CLIMB_SPEED do
            if Level.ladder(p.x, p.y - 1) then
                p.y = p.y - 1
            else
                -- topped out: stand on the ladder cap
                p.climbing = false
                p.landed = true
                p.y = math.floor(p.y)
                break
            end
        end
        p.climbT = p.climbT + 1
    elseif dy > 0 then
        for _ = 1, C.CLIMB_SPEED do
            if Level.ladder(p.x, p.y + 1) then
                p.y = p.y + 1
            elseif Level.solid(p.x, p.y + 1) then
                p.climbing = false
                p.landed = true
                p.y = math.floor(p.y)
                break
            else
                -- ladder ended in the air: let go
                p.climbing = false
                break
            end
        end
        p.climbT = p.climbT + 1
    end
end

local function updateRun(p, inp)
    local dx = inp.dir
    if dx == 0 then
        p.vx = Util.moveTowards(p.vx, 0, C.RUN_ACCEL)
    else
        p.facing = dx
        p.vx = Util.moveTowards(p.vx, C.RUN_SPEED * dx, C.RUN_ACCEL)
    end
    p.moving = dx ~= 0
    if p.vx ~= 0 then
        p.x = clamp(p.x + p.vx, 8, C.SCREEN_W - 8)
    end

    -- direction-change skid frames
    if dx ~= 0 and sign(p.vx) ~= dx then
        p.changeDirT = 3
    end

    -- gravity, with a soft first few frames after takeoff
    local wasLanded = p.landed
    p.vy = math.min(p.vy + (p.lowGravT > 0 and C.LOW_GRAVITY or C.GRAVITY), C.MAX_FALL)
    Level.fall(p, C.PLAYER_HALF_W)
    if wasLanded and not p.landed and p.vy >= 0 then
        -- walked off an edge: open the coyote window
        p.coyote = C.COYOTE_FRAMES
        p.fallT = 0
        p.jumping = false
    end
    if p.landed then
        p.jumping = false
    end

    -- a released mid-rise cuts the jump short (not after a stomp bounce)
    if not p.landed and p.vy < 0 and not inp.jumpHeld and p.stompT <= 0 then
        p.vy = math.min(p.vy + C.JUMP_CUT, 0)
    end

    -- grab a ladder
    if inp.up then
        local cx = Level.ladderGrab(p.x, p.y - 4)
        if cx then
            p.x = cx
            p.climbing = true
            p.vx, p.vy = 0, 0
            p.landed = false
            p.climbT = 0
            return
        end
    elseif inp.down and p.landed then
        local cx = Level.ladderGrab(p.x, p.y + 4)
        if cx then
            p.x = cx
            p.climbing = true
            p.vx, p.vy = 0, 0
            p.landed = false
            p.climbT = 0
            return
        end
    end

    -- jump, honoring the buffered input and the coyote window
    if p.buffer > 0 and (p.landed or p.coyote > 0) then
        startJump(p)
    end
end

function Player.update(inp)
    local p = G.player
    p.coyote = p.coyote - 1
    p.buffer = p.buffer - 1
    p.lowGravT = p.lowGravT - 1
    p.stompT = p.stompT - 1
    p.changeDirT = p.changeDirT - 1

    if inp.jump then
        p.buffer = C.JUMP_BUFFER_FRAMES
    end

    if p.hurt then
        -- tumble out of the level, then pay for it
        p.vy = math.min(p.vy + C.GRAVITY, C.MAX_FALL + 5)
        p.y = p.y + p.vy
        p.fallT = p.fallT + 1
        if p.y > C.SCREEN_H + 50 then
            Harness.count("deaths")
            G.lives = G.lives - 1
            if G.lives < 0 then
                Main.gameOver()
            else
                Player.respawn()
            end
        end
        return
    end

    if p.climbing then
        updateClimb(p, inp)
    else
        updateRun(p, inp)
    end

    -- fell out of the level somehow: back to the start
    if p.y > C.SCREEN_H + 30 then
        Player.respawn()
    end

    checkEnemies(p)

    if not p.landed and not p.climbing then
        p.fallT = p.fallT + 1
    end
end

-- pick the sprite name for the current pose
function Player.sprite(p)
    local d = (p.facing < 0) and "1" or "0"
    if p.hurt then
        return "die_" .. math.min(p.fallT // 4, 5)
    elseif p.climbing then
        return "climb_" .. d .. "_" .. (p.climbT // 4) % 2
    elseif not p.landed then
        if p.jumping and p.vy < 0 then
            return "jump_" .. d .. "_" .. math.min(p.fallT // 2, 5)
        else
            return "fall_" .. d .. "_" .. math.min(p.fallT // 4, 1)
        end
    elseif p.changeDirT > 0 then
        return "change_dir_" .. d .. "_0"
    elseif p.moving then
        return "run_" .. d .. "_" .. (G.frame // 2) % 8
    else
        return "stand_front"
    end
end

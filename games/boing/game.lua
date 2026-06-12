-- Core simulation: bats, ball, AI, scoring. All my own implementation of
-- the classic table-tennis design (half-scale field, stepwise ball motion).

Game = {}

local clamp = Util.clamp

local CX <const> = C.SCREEN_W / 2
local CY <const> = C.SCREEN_H / 2

function Game.reset(twoPlayer)
    G.twoPlayer = twoPlayer
    G.bats = {
        { x = C.BAT_X, y = CY, score = 0, glow = 0, isAI = false },
        { x = C.SCREEN_W - C.BAT_X, y = CY, score = 0, glow = 0, isAI = not twoPlayer },
    }
    G.impacts = {}
    G.aiOffset = 0
    G.winner = nil
    Game.serve(math.random() < 0.5 and 1 or -1)
end

function Game.serve(dirX)
    G.ball = { x = CX, y = CY, dx = dirX, dy = 0, speed = C.BALL_START_SPEED }
    G.serveT = 0.7 -- brief pause before the ball moves
end

local function addImpact(x, y)
    G.impacts[#G.impacts + 1] = { x = x, y = y, t = 0 }
end

function Game.moveBat(i, dy)
    local bat = G.bats[i]
    bat.y = clamp(bat.y + dy, C.BAT_HALF_H, C.SCREEN_H - C.BAT_HALF_H)
end

local function updateAI(i)
    local bat = G.bats[i]
    local ball = G.ball
    -- drift to center when the ball is heading away; track it (imperfectly,
    -- via the per-hit random offset) when it approaches
    local incoming = (ball.dx > 0) == (i == 2)
    local targetY = CY
    if incoming and math.abs(ball.x - bat.x) < 260 then
        targetY = ball.y + G.aiOffset
    end
    local dy = clamp(targetY - bat.y, -C.MAX_AI_SPEED, C.MAX_AI_SPEED)
    Game.moveBat(i, dy)
end

local function batCollide(ball, bat, dirX)
    -- vertical deflection from where the bat was struck
    local diff = ball.y - bat.y
    if math.abs(diff) > C.BAT_HALF_H + 4 then
        return false -- whiffed: the ball sails past
    end
    ball.dx = dirX
    ball.dy = clamp(ball.dy + diff / 48, -1, 1)
    -- renormalize so speed stays consistent in any direction
    local len = math.sqrt(ball.dx * ball.dx + ball.dy * ball.dy)
    ball.dx, ball.dy = ball.dx / len, ball.dy / len
    ball.speed = ball.speed + 1
    G.aiOffset = math.random(-12, 12)
    bat.glow = 10
    Harness.count("hits")
    addImpact(ball.x, ball.y)
    Sfx.hit(ball.speed)
    return true
end

local function stepBall()
    local ball = G.ball
    local prevX = ball.x
    ball.x = ball.x + ball.dx
    ball.y = ball.y + ball.dy

    -- bat faces
    if math.abs(ball.x - CX) >= C.BAT_HIT_X and math.abs(prevX - CX) < C.BAT_HIT_X then
        if ball.x < CX then
            batCollide(ball, G.bats[1], 1)
        else
            batCollide(ball, G.bats[2], -1)
        end
    end

    -- walls
    if math.abs(ball.y - CY) > C.WALL_HALF_H then
        ball.dy = -ball.dy
        ball.y = ball.y + ball.dy
        Harness.count("walls")
        addImpact(ball.x, ball.y)
        Sfx.wall()
    end
end

function Game.update()
    for i = 1, 2 do
        local bat = G.bats[i]
        if bat.glow > 0 then bat.glow = bat.glow - 1 end
        if bat.isAI then updateAI(i) end
    end

    if G.serveT > 0 then
        G.serveT = G.serveT - C.DT
    else
        for _ = 1, G.ball.speed do
            stepBall()
            if G.ball.x < -10 or G.ball.x > C.SCREEN_W + 10 then
                break
            end
        end
    end

    -- out past a wall: point to the other side
    local ball = G.ball
    if ball.x < -10 or ball.x > C.SCREEN_W + 10 then
        local scorer = ball.x < 0 and 2 or 1
        Harness.count("points")
        G.bats[scorer].score = G.bats[scorer].score + 1
        Sfx.score()
        if G.bats[scorer].score >= C.WIN_SCORE then
            Harness.count("games")
            G.winner = scorer
            G.state = "over"
            G.overT = 0
        else
            -- serve toward the player who just conceded
            Game.serve(scorer == 1 and 1 or -1)
        end
    end

    for i = #G.impacts, 1, -1 do
        local im = G.impacts[i]
        im.t = im.t + 1
        if im.t > 10 then table.remove(G.impacts, i) end
    end
end

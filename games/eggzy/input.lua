-- Input gathering: d-pad/A, plus the autopilot used by the smoke-test
-- harness (seeks the nearest gem, rides ladders, hops gaps and enemies).

Input = {}

local function pad()
    local inp = {
        dir = 0,
        up = playdate.buttonIsPressed(playdate.kButtonUp),
        down = playdate.buttonIsPressed(playdate.kButtonDown),
        jump = playdate.buttonJustPressed(playdate.kButtonA),
        jumpHeld = playdate.buttonIsPressed(playdate.kButtonA),
        start = playdate.buttonJustPressed(playdate.kButtonA),
    }
    if playdate.buttonIsPressed(playdate.kButtonLeft) then inp.dir = -1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then inp.dir = 1 end
    return inp
end

-- what the autopilot is running toward: nearest gem, else the door
local function autoTarget(p)
    local best, bx, by = 1e9, nil, nil
    for _, g in ipairs(G.gems) do
        local d = math.abs(g.x - p.x) + math.abs(g.y - p.y) * 2
        if d < best then best, bx, by = d, g.x, g.y end
    end
    if not bx and G.door then
        bx, by = G.door.x, G.door.y
    end
    return bx, by
end

-- nearest ladder column that leaves the player's floor in the wanted direction
local function autoLadder(p, up)
    local best, lx = 1e9, nil
    for _, l in ipairs(G.ladders) do
        local ok
        if up then
            ok = l.bot >= p.y - 2 and l.top < p.y - 2
        else
            ok = l.top <= p.y + 2 and l.bot > p.y + 2
        end
        if ok then
            local d = math.abs(l.x - p.x)
            if d < best then best, lx = d, l.x end
        end
    end
    return lx
end

function Input.gather()
    if not Harness.enabled then return pad() end

    local inp = { dir = 0, up = false, down = false,
                  jump = false, jumpHeld = false, start = true }
    local p = G.player
    if not p or p.hurt or G.state ~= "play" then return inp end

    local tx, ty = autoTarget(p)
    if not tx then return inp end

    local auto = G.auto
    auto.t = auto.t - 1

    if p.climbing then
        -- ride the ladder toward the target's floor
        if ty < p.y - 4 then
            inp.up = true
        elseif ty > p.y + 4 then
            inp.down = true
        else
            inp.up = true -- top out onto the platform
        end
        return inp
    end

    local wantX = tx
    if math.abs(ty - p.y) > 8 then
        -- target is on another floor: head for a connecting ladder
        local lx = autoLadder(p, ty < p.y)
        if lx then
            wantX = lx
            if p.landed and math.abs(p.x - lx) <= 4 then
                if ty < p.y then inp.up = true else inp.down = true end
                return inp
            end
        end
    end

    local dx = wantX - p.x
    if math.abs(dx) > 3 then
        inp.dir = (dx > 0) and 1 or -1
    end

    if p.landed then
        -- hop gaps ahead and enemies closing in
        local gap = inp.dir ~= 0
            and not Level.solid(p.x + inp.dir * 20, p.y + 1)
        local danger = false
        for _, e in ipairs(G.enemies) do
            if not e.dying and math.abs(e.y - p.y) < 24
                and math.abs(e.x - p.x) < 40 then
                danger = true
            end
        end
        if gap or danger or (auto.t <= 0 and math.random() < 0.03) then
            inp.jump = true
            inp.jumpHeld = true
            auto.t = 12
        end
    else
        inp.jumpHeld = true -- hold A in the air for full-height jumps
    end

    return inp
end

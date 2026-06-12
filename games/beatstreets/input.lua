-- Input gathering: d-pad walks the street, A punches, B kicks, plus the
-- smoke-test autopilot (walk right, match the nearest enemy's depth,
-- mash punch, kick when surrounded).

Input = {}

local function nearest(list, p)
    local best, bd
    for _, o in ipairs(list) do
        local d = math.abs(o.x - p.x) + math.abs(o.y - p.y)
        if not bd or d < bd then best, bd = o, d end
    end
    return best
end

local function autopilot()
    local i = G.input
    i.dx, i.dy, i.punch, i.kick, i.start = 0, 0, false, false, true

    local p = G.player
    if not p or G.state ~= "play" then return end

    -- hemmed in on both sides: kick our way out
    local left, right = false, false
    for _, e in ipairs(G.enemies) do
        if not e.fall and math.abs(e.y - p.y) < 15 and math.abs(e.x - p.x) < 70 then
            if e.x < p.x then left = true else right = true end
        end
    end
    if left and right then
        i.kick = true
        return
    end

    local target = nearest(G.enemies, p) or nearest(G.pickups, p)
        or nearest(G.barrels, p)
    if not target then
        -- nothing to fight: push right to pull the GO scroll along
        i.dx = 1
        if p.y > 210 then i.dy = -1 elseif p.y < 165 then i.dy = 1 end
        return
    end

    local dx, dy = target.x - p.x, target.y - p.y
    if math.abs(dy) > 3 then i.dy = Util.sign(dy) end
    if math.abs(dx) > 32 or (dx ~= 0 and Util.sign(dx) ~= p.facing) then
        i.dx = Util.sign(dx)
    end
    if math.abs(dx) < 50 and math.abs(dy) < 9 then
        i.punch = G.frame % 2 == 0
    end
end

function Input.gather()
    if Harness.enabled then
        autopilot()
        return
    end

    local i = G.input
    i.dx, i.dy = 0, 0
    if playdate.buttonIsPressed(playdate.kButtonLeft) then i.dx = -1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then i.dx = 1 end
    if playdate.buttonIsPressed(playdate.kButtonUp) then i.dy = -1 end
    if playdate.buttonIsPressed(playdate.kButtonDown) then i.dy = 1 end
    i.punch = playdate.buttonJustPressed(playdate.kButtonA)
    i.kick = playdate.buttonJustPressed(playdate.kButtonB)
    i.start = i.punch or i.kick
end

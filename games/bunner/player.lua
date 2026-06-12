-- The rabbit: hop-based grid movement, log riding, and the ways it all ends.

Player = {}

local DIRS = {
    up = { 0, -1 },
    down = { 0, 1 },
    left = { -1, 0 },
    right = { 1, 0 },
}

function Player.spawn()
    local row = G.rows[3]
    G.player = {
        x = C.SCREEN_W / 2 - C.CELL_W / 2, -- a cell center
        y = row.y,
        dir = "up",
        hopT = 0,
        fromX = 0, fromY = 0, toX = 0, toY = 0,
        state = "alive", -- "alive" | "squash" | "drown" | "eagle"
        deathT = 0,
        queue = {},
        startY = row.y,
        minY = row.y,
    }
end

function Player.queueHop(dir)
    local p = G.player
    if p and p.state == "alive" and #p.queue < C.HOP_QUEUE then
        p.queue[#p.queue + 1] = dir
    end
end

local function tryHop(p, dir)
    local d = DIRS[dir]
    local tx = p.x + d[1] * C.CELL_W
    local ty = p.y + d[2] * C.ROW_H
    local row = Rows.at(ty)
    if row and Rows.allowMovement(row, tx) then
        p.dir = dir
        p.fromX, p.fromY, p.toX, p.toY = p.x, p.y, tx, ty
        p.hopT = C.HOP_TIME
        Sfx.hop()
        Harness.count("hops")
    end
end

local function die(p, state, pause)
    p.state = state
    p.deathT = pause
    p.queue = {}
end

function Player.update()
    local p = G.player

    if p.state ~= "alive" then
        p.deathT = p.deathT - C.DT
        if p.deathT <= 0 then Main.gameOver() end
        return
    end

    if p.hopT > 0 then
        p.hopT = p.hopT - C.DT
        if p.hopT <= 0 then
            p.hopT = 0
            p.x, p.y = p.toX, p.toY
        else
            local t = 1 - p.hopT / C.HOP_TIME
            p.x = p.fromX + (p.toX - p.fromX) * t
            p.y = p.fromY + (p.toY - p.fromY) * t
        end
    end

    -- collisions only count with feet on the ground, like any honest frog
    if p.hopT == 0 then
        local row = Rows.at(p.y)
        if row then
            local fate = Rows.standCheck(row, p.x)
            if fate == "squash" then
                die(p, "squash", C.DEATH_PAUSE)
                row.splats[#row.splats + 1] = { x = p.x, dir = p.dir }
                Sfx.squash()
                Harness.count("squashed")
            elseif fate == "drown" then
                die(p, "drown", C.DEATH_PAUSE)
                G.addSplash(p.x, p.y)
                Sfx.splash()
                Harness.count("drowned")
            else
                if row.kind == "water" then
                    p.x = p.x + row.dx * C.DT
                end
                if #p.queue > 0 then
                    tryHop(p, table.remove(p.queue, 1))
                end
            end
        end
    end

    p.x = Util.clamp(p.x, C.EDGE_PAD, C.SCREEN_W - C.EDGE_PAD)

    if p.state == "alive" and p.y - G.camY > C.SCREEN_H + C.OFF_BOTTOM then
        die(p, "eagle", C.EAGLE_PAUSE)
        G.eagle = { x = p.x, y = G.camY - 30 }
        Sfx.eagle()
        Harness.count("eagle")
    end

    if p.y < p.minY then
        p.minY = p.y
        G.score = math.floor((p.startY - p.minY) / C.ROW_H + 0.5)
        Harness.set("maxRow", math.max(Harness.counters.maxRow or 0, G.score))
    end
end

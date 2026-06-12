-- Stage data and flow: GO-arrow lock-in waves, the scrolling camera,
-- breakable barrels with health pickups, and per-stage background tiles
-- (lazy-loaded on stage start so only one stage's scenery is in memory).

local gfx <const> = playdate.graphics

Stages = {}

-- background tile names per stage; each tile is 208x195 drawn on a 145 pitch
local TILES = {
    { "wall_end1", "wall_fill1", "wall_fill5", "wall_fill2", "alley1",
        "wall_end6", "wall_fill7", "wall_fill5", "alley2", "wall_end3" },
    { "con_start2", "con_end1a", "con_fill1", "con_end2a", "steps_end1",
        "steps_fill1", "steps_end2", "flats_alley1", "set_pc_b1",
        "set_pc_b2", "set_pc_b3" },
}

-- Each wave: a camera scroll target plus the enemies (and props) that spawn
-- once the GO scroll begins. The last wave of each stage is the boss: a
-- heavy with a bigger health pool. Coordinates are half the Python ones.
local WAVES = {
    -- stage 1: the high street
    {
        { scroll = 0, enemies = {
            { type = "thug", x = 500, y = 200 } } },
        { scroll = 150, enemies = {
            { type = "thug", x = 700, y = 180 },
            { type = "thug", x = 620, y = 215, delay = 45 } },
            barrels = { { x = 480, y = 195 } } },
        { scroll = 300, enemies = {
            { type = "thug", x = 800, y = 170 },
            { type = "thug", x = 860, y = 200, delay = 40 },
            { type = "thug", x = 820, y = 230, delay = 80 } },
            pickups = { { x = 640, y = 165 } } },
        { scroll = 450, enemies = {
            { type = "heavy", x = 950, y = 190 },
            { type = "thug", x = 1000, y = 220, delay = 50 } } },
        { scroll = 700, enemies = {
            { type = "heavy", x = 1180, y = 190, hp = 24, score = 75 },
            { type = "thug", x = 1240, y = 225, delay = 60 } },
            barrels = { { x = 920, y = 185 } } },
    },
    -- stage 2: the warehouse blocks
    {
        { scroll = 0, enemies = {
            { type = "thug", x = 520, y = 185 },
            { type = "thug", x = 560, y = 220, delay = 40 } } },
        { scroll = 200, enemies = {
            { type = "heavy", x = 720, y = 200 },
            { type = "thug", x = 680, y = 170, delay = 45 } },
            barrels = { { x = 520, y = 200 } } },
        { scroll = 420, enemies = {
            { type = "thug", x = 950, y = 170 },
            { type = "thug", x = 1000, y = 200, delay = 40 },
            { type = "thug", x = 960, y = 230, delay = 80 },
            { type = "heavy", x = 1040, y = 190, delay = 120 } },
            pickups = { { x = 880, y = 165 } } },
        { scroll = 620, enemies = {
            { type = "heavy", x = 1120, y = 180 },
            { type = "heavy", x = 1170, y = 220, delay = 60 } } },
        { scroll = 850, enemies = {
            { type = "heavy", x = 1380, y = 195, hp = 30, score = 100 },
            { type = "thug", x = 1340, y = 165, delay = 50 },
            { type = "thug", x = 1420, y = 230, delay = 100 } },
            barrels = { { x = 1160, y = 190 } },
            pickups = { { x = 1100, y = 160 } } },
    },
}

local tiles = {} -- the current stage's loaded background images
local waveSpawned = false

local function spawnWave()
    waveSpawned = true
    local wave = WAVES[G.stage][G.waveIdx]
    for _, spec in ipairs(wave.enemies) do
        Enemies.spawn(spec)
    end
    for _, b in ipairs(wave.barrels or {}) do
        G.barrels[#G.barrels + 1] = { x = b.x, y = b.y, hp = C.BARREL_HP, hitT = 0 }
    end
    for _, pk in ipairs(wave.pickups or {}) do
        G.pickups[#G.pickups + 1] = { x = pk.x, y = pk.y }
    end
end

function Stages.nextWave()
    G.waveIdx = G.waveIdx + 1
    local wave = WAVES[G.stage][G.waveIdx]
    if not wave then
        if G.stage < #WAVES then
            Stages.load(G.stage + 1)
            G.player.x, G.player.y = 60, 200
            G.state = "stageintro"
            G.stateT = 0
        else
            G.state = "win"
            G.stateT = 0
            G.saveHigh()
        end
        return
    end
    G.maxScroll = wave.scroll
    waveSpawned = false
    if G.maxScroll <= G.camX then
        spawnWave()
    end
end

function Stages.load(n)
    G.stage = n
    Harness.count("stages")
    G.waveIdx = 0
    G.camX = 0
    G.maxScroll = 0
    G.scrolling = false
    G.enemies, G.barrels, G.pickups = {}, {}, {}

    tiles = {} -- drop the previous stage's scenery before loading the next
    for i, name in ipairs(TILES[n]) do
        tiles[i] = gfx.image.new("images/" .. name)
        assert(tiles[i], "missing tile: " .. name)
    end

    Stages.nextWave()
end

function Stages.update()
    for _, b in ipairs(G.barrels) do
        if b.hitT > 0 then b.hitT = b.hitT - 1 end
    end

    if G.scrolling then
        -- scroll 0.5-4 px/frame depending on how far right the player pushes
        local diff = G.maxScroll - G.camX
        local speed = math.min(diff, math.max(0.5, (G.player.x - G.camX) / 100))
        G.camX = G.camX + speed
        if G.camX >= G.maxScroll then
            G.camX = G.maxScroll
            G.scrolling = false
        end
    elseif G.camX < G.maxScroll
        and G.player.x - G.camX > C.SCROLL_TRIGGER then
        G.scrolling = true
        if not waveSpawned then
            spawnWave()
        end
    end

    -- wave is beaten once everyone is down and the scroll has finished
    if waveSpawned and not G.scrolling and G.camX >= G.maxScroll
        and #G.enemies == 0 then
        Stages.nextWave()
    end
end

-- a player attack connecting with barrels (called from Fighters.strike)
function Stages.hitBarrels(f, atk)
    for i = #G.barrels, 1, -1 do
        local b = G.barrels[i]
        local dx = b.x - f.x
        if b.hitT <= 0
            and Util.sign(dx) == f.facing
            and math.abs(dx) < atk.reach + 14
            and math.abs(b.y - f.y) < C.HALF_HIT_H + 5 then
            b.hp = b.hp - 1
            b.hitT = 6
            Sfx.play("barrel_hit")
            if b.hp <= 0 then
                G.addScore(C.BARREL_SCORE)
                Harness.count("barrels")
                table.remove(G.barrels, i)
                G.pickups[#G.pickups + 1] = { x = b.x, y = b.y }
            end
        end
    end
end

function Stages.drawBackground()
    local rx = -(G.camX % C.SCREEN_W)
    Assets.road:draw(rx, 0)
    Assets.road:draw(rx + C.SCREEN_W, 0)

    local x = -G.camX - C.TILE_SPACING
    for _, img in ipairs(tiles) do
        if x >= C.SCREEN_W then break end
        if x + C.TILE_W >= 0 then
            img:draw(x, 0)
        end
        x = x + C.TILE_SPACING
    end
end

function Stages.drawBarrel(b)
    local sx = b.x - G.camX
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillEllipseInRect(sx - 14, b.y - 4, 28, 7)
    gfx.setColor(gfx.kColorBlack)
    local jitter = b.hitT > 0 and ((G.frame % 2) * 2 - 1) or 0
    Assets.barrel:draw(sx - 80 + jitter, b.y - 95)
end

function Stages.drawPickup(pk)
    local sx = pk.x - G.camX
    gfx.setColor(gfx.kColorBlack)
    gfx.setDitherPattern(0.5)
    gfx.fillEllipseInRect(sx - 10, pk.y - 3, 20, 5)
    gfx.setColor(gfx.kColorBlack)
    Assets.pickup:draw(sx - 17, pk.y - 34)
end

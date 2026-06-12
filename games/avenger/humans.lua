-- The ten ground crew everyone is fighting over: standing about, waving,
-- getting abducted, falling, and (with luck) being caught and set down.

local gfx <const> = playdate.graphics

Humans = {}

-- spots on the terrain image (x, y); world y adds C.TERRAIN_Y
local START_POS <const> = {
    { 102, 205 }, { 244, 104 }, { 432, 187 }, { 631, 202 }, { 968, 131 },
    { 1096, 139 }, { 1300, 202 }, { 1423, 173 }, { 1658, 96 }, { 1823, 116 },
}

function Humans.spawnAll()
    G.humans = {}
    for _, pos in ipairs(START_POS) do
        G.humans[#G.humans + 1] = {
            x = pos[1],
            y = pos[2] + C.TERRAIN_Y,
            vy = 0,
            animT = math.random(0, 60),
            waving = false,
            dead = false,
            exploding = false,
            explodeFrame = 0,
            carrier = nil, -- nil | "player" | an enemy table
            falling = false,
            sprite = "human_stand0",
        }
    end
end

-- is there solid ground at this human's feet? (per-pixel against the terrain)
function Humans.onTerrain(h)
    local tx = math.floor(h.x % C.LEVEL_W)
    local ty = math.floor(h.y - C.TERRAIN_Y)
    if ty >= Assets.terrainH then return true end -- never fall out of the world
    if ty < 0 then return false end
    return Assets.img.terrain:sample(tx, ty) ~= gfx.kColorClear
end

function Humans.catchable(h)
    -- the ship can only catch a human in mid-air
    return h.carrier == nil and h.falling and not h.dead and not h.exploding
end

function Humans.abductable(h)
    -- enemies won't grab one that is already falling
    return h.carrier == nil and not h.falling and not h.dead and not h.exploding
end

function Humans.pickedUp(h, carrier)
    h.carrier = carrier
    h.falling = false
end

function Humans.dropped(h)
    h.carrier = nil
    h.falling = not Humans.onTerrain(h)
    h.vy = 0
end

function Humans.die(h)
    h.exploding = true
    h.animT = 0
    Sfx.play("prisoner_die")
end

function Humans.laserHitTest(h, x, y)
    if h.exploding then return false end
    if math.abs(x - h.x) >= 15 or math.abs(y - h.y) >= 15 then return false end
    Humans.die(h)
    return true
end

function Humans.update(h)
    h.x = h.x + Util.wrapDelta(h.x)
    h.animT = h.animT + 1

    if h.exploding then
        h.explodeFrame = math.min(9, h.animT)
        if h.animT >= 10 then h.dead = true end
        return
    end

    if not h.carrier then
        h.falling = not Humans.onTerrain(h)
        if h.falling then
            h.vy = math.min(h.vy + C.HUMAN_GRAVITY, C.HUMAN_MAX_FALL)
            h.y = h.y + h.vy
        elseif h.vy > C.HUMAN_FATAL_FALL then
            Humans.die(h) -- that landing was too hard
            return
        end
    end

    local pose, frames = "stand", 1
    if h.carrier == "player" then
        pose, frames = "saved", 1
    elseif h.carrier then
        pose, frames = "abducted", 4
    elseif h.falling then
        pose, frames = "fall", 2
    elseif h.waving then
        pose, frames = "wave", 3
        if h.animT > 50 then h.waving = false end
    elseif math.random(100) == 1 then
        h.waving = true
        h.animT = 0
    end
    h.sprite = "human_" .. pose .. Util.fbFrame(h.animT // 4, frames)
end

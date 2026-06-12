-- The hero: input-driven movement, the three-punch combo, kicks, pickups
-- and life loss.

Player = {}

function Player.new()
    local p = {
        player = true,
        anims = Assets.hero,
        x = 200, y = 200, h = 0,
        vx = 0, vy = 0,
        facing = 1,
        frame = 0,
        walking = false,
        attack = nil,
        attackT = -999,
        hitT = 0, hitFrame = 0,
        fall = nil, fallT = 0, useDie = false,
        gone = false,
        health = C.PLAYER_HP,
        maxHealth = C.PLAYER_HP,
        lives = C.LIVES,
        speedX = C.PLAYER_SPEED_X,
        speedY = C.PLAYER_SPEED_Y,
        animRate = 4,
        anchorY = 128,
        halfW = C.HALF_HIT_W,
        halfH = C.HALF_HIT_H,
        decideAttack = Player.decideAttack,
        getMoveTarget = Player.getMoveTarget,
        getFacing = Player.getFacing,
        getOpponents = Player.getOpponents,
    }
    return p
end

function Player.decideAttack(p)
    local i = G.input
    if i.punch then
        -- chain into the next combo step if the last punch was recent
        if p.attack and p.attack.combo and p.attackT >= -C.COMBO_WINDOW then
            return Attacks[p.attack.combo]
        end
        return Attacks.punch1
    end
    if i.kick then
        -- kick on the move becomes a jump kick
        if i.dx ~= 0 then
            return Attacks.flykick
        end
        return Attacks.kick
    end
    return nil
end

function Player.getMoveTarget(p)
    return p.x + G.input.dx * p.speedX, p.y + G.input.dy * p.speedY
end

function Player.getFacing(p)
    if G.input.dx ~= 0 then return G.input.dx end
    return nil
end

function Player.getOpponents(p)
    return G.enemies
end

local function loseLife(p)
    p.lives = p.lives - 1
    Harness.count("deaths")
    if p.lives > 0 then
        p.health = p.maxHealth
        p.useDie = false
        p.fall = "getup"
        p.fallT = 0
    else
        G.state = "gameover"
        Harness.count("gameovers")
        G.stateT = 0
        G.saveHigh()
    end
end

function Player.update(p)
    Fighters.update(p)

    if p.gone then
        p.gone = false
        loseLife(p)
    end

    -- collect health pickups by walking over them
    for i = #G.pickups, 1, -1 do
        local pk = G.pickups[i]
        if math.abs(pk.x - p.x) < C.PICKUP_RADIUS
            and math.abs(pk.y - p.y) < C.HALF_HIT_H then
            p.health = math.min(p.health + C.HEAL_AMOUNT, p.maxHealth)
            Sfx.play("health")
            Harness.count("pickups")
            table.remove(G.pickups, i)
        end
    end
end

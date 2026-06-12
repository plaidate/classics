-- Car behaviour: shared motion, rival AI, and the player's handling,
-- collisions, checkpoints and lap timing. The corners are an illusion:
-- the road only ever shoves the player sideways (offsetXChange), and
-- steering exists to cancel that shove.

Cars = {}

local LETTERS <const> = { "b", "c", "d", "e" }

local function newCar(x, z, letter)
    return {
        x = x, z = z, speed = 0, grip = 1,
        letter = letter, tyre = 0,
        img = "car_" .. letter .. "_0_0",
    }
end

function Cars.spriteFrame(car, angle, braking, boost)
    local frame
    if car.speed == 0 then
        frame = 0
    elseif braking then
        frame = 3
    elseif boost then
        frame = math.floor(car.tyre % 2) + 4
    else
        frame = math.floor(car.tyre % 2) + 1
    end
    car.img = "car_" .. car.letter .. "_" .. angle .. "_" .. frame
end

local function moveCar(car, dt)
    car.z = car.z - car.speed * dt
    car.tyre = car.tyre + dt * car.speed * 0.75
end

-- Rivals ------------------------------------------------------------

function Cars.newCPU(x, z, accel, targetSpeed)
    local c = newCar(x, z, LETTERS[math.random(4)])
    c.isCPU = true
    c.accel = C.ACCEL_MAX * accel
    c.targetSpeed = targetSpeed
    c.targetX = x
    c.steering = 0
    c.changeT = Util.uniform(2, 4)
    return c
end

function Cars.updateCPU(c, R, dt)
    if R.raceComplete and R.player then
        c.targetSpeed = R.player.speed -- cruise alongside after the flag
    end
    c.speed = Util.moveTowards(c.speed, c.targetSpeed, c.accel * dt)
    c.x = Util.moveTowards(c.x, c.targetX, 200 * dt)
    moveCar(c, dt)

    local idx = Track.aheadIdx(c.z)
    if idx then c.steering = Track.ox[idx + 1] end

    -- Every few seconds pick a new target speed (biased upward so the
    -- pack stays lively) and a new lane, away from nearby cars.
    c.changeT = c.changeT - dt
    if c.changeT <= 0 and not R.raceComplete then
        c.targetSpeed = Util.clamp(c.targetSpeed + Util.uniform(-4, 6),
            C.CPU_MIN_SPEED, C.CPU_MAX_SPEED)
        if idx then
            local cap = Track.maxSpd[idx + 1]
            if cap and c.targetSpeed > cap then
                c.targetSpeed = Util.uniform(cap - 3, cap)
            end
        end
        for _ = 1, 20 do
            c.targetX = Util.uniform(-500, 500)
            local clear = true
            for i = 1, #R.cars do
                local other = R.cars[i]
                if other ~= c and math.abs(c.z - other.z) < 20
                    and math.abs(c.targetX - other.x) < 150 then
                    clear = false
                    break
                end
            end
            if clear then break end
        end
        c.changeT = Util.uniform(2, 4)
    end
end

-- Player ------------------------------------------------------------

function Cars.newPlayer(x, z)
    local p = newCar(x, z, "a")
    p.isPlayer = true
    p.offsetXChange = 0
    p.resetting = false
    p.explodeT = nil
    p.lastCheckpoint = nil
    p.lap = 1
    p.lapTime = 0
    p.raceTime = 0
    p.fastestLap = nil
    p.lastLapFastest = false
    p.braking = false
    p.onGrass = false
    p.grassSndT = 0
    p.prevPos = C.NUM_CARS
    return p
end

local function carCollisions(p, R)
    for i = 1, #R.cars do
        local car = R.cars[i]
        if car ~= p then
            local dx = p.x - car.x
            local dz = p.z - car.z
            if math.abs(dx) < 130 and dz < 0.6 and dz > -1.2 then
                local mid = dz / 2 + car.z
                if math.abs(dz) < 0.2 then
                    -- side swipe: push apart
                    p.x = p.x + Util.sign(dx) * 25
                    car.x = car.x - Util.sign(dx) * 25
                elseif dz > 0 then
                    -- we ran into the car ahead
                    p.speed = math.max(car.speed - 3, 0)
                    car.speed = math.max(car.speed, p.speed + 3)
                    car.targetSpeed = car.speed
                    p.z = mid + 0.36
                    car.z = mid - 0.36
                    Sfx.play("bump")
                    Harness.count("collisions")
                else
                    -- shunted from behind: free speed
                    p.speed = math.max(p.speed, car.speed + 3)
                    car.speed = math.max(p.speed - 3, 0)
                    p.z = mid - 0.72
                    car.z = mid + 0.72
                    Sfx.play("bump_behind")
                    Harness.count("collisions")
                end
            end
        end
    end
end

function Cars.updatePlayer(p, R, dt)
    if not R.raceComplete then
        p.lapTime = p.lapTime + dt
        p.raceTime = p.raceTime + dt
    end
    p.grassSndT = p.grassSndT - dt
    Sfx.engineUpdate(p.speed)

    -- overtake jingle when our standing changes at a real speed gap
    local cur = Util.indexOf(R.cars, p)
    if cur ~= p.prevPos then
        if cur < p.prevPos then Harness.count("overtakes") end
        local other = R.cars[p.prevPos]
        if other and math.abs(p.speed - other.speed) > 4 then
            Sfx.play("overtake")
        end
        p.prevPos = cur
    end

    if p.resetting then
        if p.explodeT then
            p.explodeT = p.explodeT + 1
            if p.explodeT > 31 then p.explodeT = nil end
        else
            -- glide back to the middle of the road
            p.x = Util.moveTowards(p.x, 0, 1000 * dt)
            p.resetting = p.x ~= 0
        end
    end

    local xMove = 0
    local accel = 0
    local pieceIdx = nil

    if not p.resetting then
        p.braking = false
        if not R.raceComplete then
            if G.input.accel then
                accel = (p.speed < C.HIGH_ACCEL) and C.ACCEL_MAX or C.ACCEL_MIN
                p.speed = p.speed + accel * dt
            elseif G.input.brake then
                p.braking = true
                p.speed = math.max(0, p.speed - dt * 10)
            end
        end

        -- frame-rate independent drag, heavier on grass
        local drag = p.onGrass and 0.995 or 0.9975
        p.speed = p.speed * drag ^ (dt * 60)

        if p.offsetXChange ~= 0 then
            -- cornering: lose grip when fast and steering with the bend
            if p.speed > C.LOSE_GRIP_SPEED
                and Util.sign(G.input.steer) == -Util.sign(p.offsetXChange) then
                p.grip = Util.remapClamp(p.speed,
                    C.LOSE_GRIP_SPEED, C.ZERO_GRIP_SPEED, 1, 0)
            else
                p.grip = 1
            end
            if not R.raceComplete then
                p.x = p.x - p.offsetXChange * C.CORNER_PUSH
            end
        else
            p.grip = 1
        end

        local prevIdx = Track.aheadIdx(p.z)

        if p.speed > 0 and not R.raceComplete then
            xMove = G.input.steer * p.speed * C.STEER_STRENGTH * p.grip * dt
            p.x = p.x - xMove
        end

        moveCar(p, dt)
        carCollisions(p, R)

        pieceIdx = Track.aheadIdx(p.z)
        if pieceIdx then
            -- roadside obstacles
            local scen = Track.scen[pieceIdx + 1]
            if scen and not p.resetting then
                for s = 1, #scen do
                    local obj = scen[s]
                    for zi = 1, #obj.zones do
                        local zone = obj.zones[zi]
                        if p.x > obj.x + zone[1] and p.x < obj.x + zone[2] then
                            p.speed = 0
                            p.resetting = true
                            p.explodeT = 0
                            Sfx.play("explosion")
                            Harness.count("collisions")
                        end
                    end
                end
            end

            -- start/finish line crossings -> laps
            if prevIdx then
                for i = prevIdx, pieceIdx do
                    if Track.line[i + 1] then
                        if p.lastCheckpoint and p.lastCheckpoint ~= i then
                            p.lap = p.lap + 1
                            Harness.count("laps")
                            if not p.fastestLap or p.lapTime < p.fastestLap then
                                p.fastestLap = p.lapTime
                                p.lastLapFastest = true
                                Sfx.play("fastlap")
                            else
                                p.lastLapFastest = false
                            end
                            if p.lap == C.NUM_LAPS then
                                Sfx.play("final_lap")
                            end
                            p.lapTime = 0
                        end
                        p.lastCheckpoint = i
                        Harness.count("checkpoints")
                    end
                end
            end

            -- grass at the road edges
            if math.abs(p.x) + 50 > C.TRACK_W / 2 then
                p.onGrass = true
                Harness.count("offroad")
                if p.grassSndT <= 0 then
                    Sfx.play("hit_grass")
                    p.grassSndT = 0.15
                end
                if math.abs(p.x) > 3000 then
                    p.speed = 0
                    p.resetting = true
                end
            else
                p.onGrass = false
            end
        end
    end

    -- skid volume from grip and how tight the bend is
    local vol = 0
    if not (p.resetting or p.grip >= C.SKID_GRIP or G.input.steer == 0) then
        vol = Util.remapClamp(p.grip, C.SKID_GRIP, 0.5, 0, 1)
        if pieceIdx then
            vol = vol * Util.remapClamp(math.abs(Track.ox[pieceIdx + 1]), 0, 7.5, 0, 1)
        end
    end
    Sfx.skid(vol)

    -- pick the sprite
    if p.explodeT then
        p.img = string.format("explode%02d", p.explodeT // 2)
    else
        local dir = 0
        if xMove < 0 then dir = -1 elseif xMove > 0 then dir = 1 end
        local boost = accel > 0 and p.speed < C.HIGH_ACCEL and p.speed > 0
        Cars.spriteFrame(p, dir, p.braking, boost)
    end
end

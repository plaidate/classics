-- A race in progress: the field of cars, the camera, the start-line
-- countdown, and the background parallax that sells the corners. The
-- title screen runs one of these with no player (demo mode).

Race = {}

function Race.new(withPlayer)
    local R = {
        cars = {},
        player = nil,
        camX = 0, camY = C.CAM_HEIGHT, camZ = 0,
        bgX = -800, bgY = 15,
        firstFrame = true,
        timer = 0,
        startTimer = 0,
        raceComplete = false,
        timeUp = false,
    }

    -- starting grid, staggered left/right
    for i = 0, C.NUM_CARS - 1 do
        local z = -3 - i * C.GRID_SPACING
        local x = (i % 2 == 0) and -200 or 200
        if i == 0 and withPlayer then
            R.player = Cars.newPlayer(x, z)
            R.cars[#R.cars + 1] = R.player
        else
            local speed = Util.remap(i, 0, C.NUM_CARS - 1, C.CPU_MIN_SPEED, C.CPU_MAX_SPEED)
            local accel = Util.remap(i, 0, C.NUM_CARS - 1, 1.5, 2)
            R.cars[#R.cars + 1] = Cars.newCPU(x, z, accel, speed)
        end
    end
    R.camFollow = R.player or R.cars[1]

    if R.player then
        R.startTimer = 3.999 -- countdown; demo races start instantly
        Sfx.music("engines_startline")
        Sfx.engineStart()
    end
    return R
end

local function zLess(a, b) return a.z < b.z end

function Race.update(R, dt)
    R.timer = R.timer + dt

    -- start-line countdown, with a beep at each tick
    if R.startTimer > 0 then
        local old = R.startTimer
        R.startTimer = math.max(0, R.startTimer - dt)
        if R.startTimer == 0 then
            Sfx.music("ambience")
            Sfx.play("gobeep")
        elseif math.floor(old) ~= math.floor(R.startTimer) then
            Sfx.play("startbeep")
        end
    end

    local oldCamZ = R.camZ
    local prevAhead = Track.aheadIdx(oldCamZ)

    if R.startTimer == 0 then
        for i = 1, #R.cars do
            local car = R.cars[i]
            if car.isCPU then
                Cars.updateCPU(car, R, dt)
            else
                Cars.updatePlayer(car, R, dt)
            end
        end
    end

    if not R.raceComplete and R.player then
        if R.player.lapTime >= C.TIME_LIMIT then
            -- race called off: lap timer would overflow the HUD, and a
            -- walked-away demo unit gets its title screen back
            Sfx.stopMusic()
            R.timeUp = true
            R.raceComplete = true
        elseif R.player.lap > C.NUM_LAPS then
            Sfx.stopMusic()
            R.raceComplete = true
            Sfx.play("game_complete")
        end
        if R.raceComplete then
            local lap = R.player.fastestLap
            local raceTime = (not R.timeUp) and R.player.raceTime or nil
            G.newLapRecord, G.newRaceRecord = G.saveRecords(lap, raceTime)
        end
        table.sort(R.cars, zLess) -- keep the field in race order
    end

    -- camera trails the followed car
    R.camX = R.camFollow.x
    R.camZ = R.camFollow.z + C.CAM_FOLLOW

    -- The corners are fake: accumulate how much road offset the camera
    -- crossed this frame, scroll the skyline by it, and shove the
    -- player's car sideways by the same amount (offsetXChange).
    local newAhead = Track.aheadIdx(R.camZ)
    local dist = oldCamZ - R.camZ
    local ocx, ocy = 0, 0
    if dist > 0 and not R.firstFrame and prevAhead and newAhead then
        if newAhead > prevAhead then
            -- movement spans a piece boundary: take the fractions of
            -- the first and last pieces, plus all of any in between
            local fFirst = oldCamZ - math.floor(oldCamZ)
            local fLast = math.floor(R.camZ) + 1 - R.camZ
            ocx = Track.ox[prevAhead + 1] * fFirst + Track.ox[newAhead + 1] * fLast
            ocy = Track.oy[prevAhead + 1] * fFirst + Track.oy[newAhead + 1] * fLast
            for i = prevAhead + 1, newAhead - 1 do
                ocx = ocx + Track.ox[i + 1]
                ocy = ocy + Track.oy[i + 1]
            end
        else
            ocx = Track.ox[prevAhead + 1] * dist
            ocy = Track.oy[prevAhead + 1] * dist
        end
        R.bgX = R.bgX + ocx
        R.bgY = R.bgY + ocy
        while R.bgX < -1600 do R.bgX = R.bgX + 1600 end
        while R.bgX > 1600 do R.bgX = R.bgX - 1600 end
    end
    if R.player then R.player.offsetXChange = ocx end
    R.firstFrame = false
end

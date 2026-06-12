-- Crank steering with d-pad fallback, A/B pedals, and the smoke-test
-- autopilot (full throttle, steer to road centre, brake for corners).

Input = {}

local function autopilot()
    local R = G.race
    local p = R and R.player
    if not p then
        return 0, false, false, true
    end

    -- steer back toward the road centre; the corner shove shows up as
    -- a growing |x|, so this also counter-steers through bends
    local steer = Util.clamp(p.x / 300, -1, 1)

    -- brake when a sharp curve (or a rival speed cap) is coming up
    local brake = false
    local idx = Track.aheadIdx(p.z)
    if idx then
        local last = math.min(idx + 14, Track.count - 1)
        for i = idx, last do
            local cap = Track.maxSpd[i + 1]
            if (cap and p.speed > cap)
                or (p.speed > 52 and math.abs(Track.ox[i + 1]) >= 4) then
                brake = true
                break
            end
        end
    end
    return steer, not brake, brake, true
end

-- returns: steer (-1..1), accel, brake, start
function Input.gather()
    if Harness.enabled then return autopilot() end

    -- the crank is the wheel; d-pad is full lock
    local steer = playdate.getCrankChange() * C.CRANK_STEER
    if playdate.buttonIsPressed(playdate.kButtonLeft) then steer = steer - 1 end
    if playdate.buttonIsPressed(playdate.kButtonRight) then steer = steer + 1 end
    steer = Util.clamp(steer, -1, 1)

    local accel = playdate.buttonIsPressed(playdate.kButtonA)
    local brake = playdate.buttonIsPressed(playdate.kButtonB)
    local start = playdate.buttonJustPressed(playdate.kButtonA)
        or playdate.buttonJustPressed(playdate.kButtonB)
    return steer, accel, brake, start
end

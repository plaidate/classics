-- Small math helpers. NOTE: the Makefile stages this file over core's
-- util.lua, so clamp must stay here (the game uses it; core's copy is
-- shadowed). after/runPending are unused by this game.

Util = Util or {}

function Util.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function Util.sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

-- step n toward target by at most speed; returns new value and direction moved
function Util.moveTowards(n, target, speed)
    if n < target then
        return math.min(n + speed, target), 1
    elseif n > target then
        return math.max(n - speed, target), -1
    end
    return n, 0
end

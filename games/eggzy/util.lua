-- Helpers layered on the shared core Util (clamp + the delayed-call
-- scheduler): sign and moveTowards, which only this game needs.

Util = Util or {}

function Util.sign(x)
    if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end
end

-- step n toward target by at most speed
function Util.moveTowards(n, target, speed)
    if n < target then
        return math.min(n + speed, target)
    else
        return math.max(n - speed, target)
    end
end

-- Helpers: clamp, sign, moveTowards, and a one-shot delayed-call scheduler.

Util = Util or {}

function Util.clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

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

local pending = {}

function Util.after(delay, fn)
    pending[#pending + 1] = { t = delay, fn = fn }
end

function Util.runPending()
    for i = #pending, 1, -1 do
        local p = pending[i]
        p.t = p.t - C.DT
        if p.t <= 0 then
            table.remove(pending, i)
            p.fn()
        end
    end
end

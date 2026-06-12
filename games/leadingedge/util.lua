-- Small numeric helpers shared everywhere (clamp comes from the core).

Util = Util or {}

function Util.sign(x)
    if x == 0 then return 0 end
    return x < 0 and -1 or 1
end

function Util.remap(v, a0, a1, b0, b1)
    return (b1 - b0) * (v - a0) / (a1 - a0) + b0
end

function Util.remapClamp(v, a0, a1, b0, b1)
    local lo, hi = math.min(b0, b1), math.max(b0, b1)
    return Util.clamp(Util.remap(v, a0, a1, b0, b1), lo, hi)
end

function Util.moveTowards(n, target, step)
    if n < target then
        return math.min(n + step, target)
    end
    return math.max(n - step, target)
end

function Util.uniform(a, b)
    return a + math.random() * (b - a)
end

function Util.indexOf(list, item)
    for i = 1, #list do
        if list[i] == item then return i end
    end
    return 0
end

-- "m:ss.mmm", zero-padded seconds
function Util.formatTime(seconds)
    return string.format("%d:%06.3f", math.floor(seconds / 60), seconds % 60)
end

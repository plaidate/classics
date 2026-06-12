-- Helpers: vector bits (core's util provides clamp/after/runPending).

Util = Util or {}

function Util.norm(x, y)
    local d = math.sqrt(x * x + y * y)
    if d == 0 then return 0, 0, 0 end
    return x / d, y / d, d
end

function Util.dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

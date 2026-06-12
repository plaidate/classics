-- Small helpers: 2D vector bits and centered blits.
-- (clamp/after/runPending come from the classics core.)

Util = Util or {}

function Util.normalize(dx, dy)
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return 0, -1 end
    return dx / len, dy / len
end

function Util.rotate(dx, dy, degrees)
    local a = math.rad(degrees)
    local c, s = math.cos(a), math.sin(a)
    return dx * c - dy * s, dx * s + dy * c
end

function Util.drawCentered(img, x, y)
    local w, h = img:getSize()
    img:draw(math.floor(x - w / 2), math.floor(y - h / 2))
end

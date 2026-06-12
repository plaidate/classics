-- Small helpers: hand-rolled vector bits and wrap-around math.
-- (clamp comes from the core's Util.)

Util = Util or {}

function Util.sign(x)
    if x > 0 then return 1 elseif x < 0 then return -1 else return 0 end
end

function Util.dist(dx, dy)
    return math.sqrt(dx * dx + dy * dy)
end

function Util.uniform(a, b)
    return a + math.random() * (b - a)
end

function Util.remapClamp(v, a, b, outA, outB)
    local t = Util.clamp((v - a) / (b - a), 0, 1)
    return outA + (outB - outA) * t
end

-- ping-pong frame index: with 4 frames the sequence runs 0,1,2,3,2,1,...
function Util.fbFrame(frame, numFrames)
    if numFrames < 2 then return 0 end
    frame = frame % (numFrames * 2 - 2)
    if frame >= numFrames then frame = (numFrames - 1) * 2 - frame end
    return frame
end

-- signed horizontal offset folded into half a level either way
function Util.wrapSigned(dx)
    return (dx + C.LEVEL_W / 2) % C.LEVEL_W - C.LEVEL_W / 2
end

function Util.wrapDist(x1, x2)
    return math.abs(Util.wrapSigned(x1 - x2))
end

-- how far (a multiple of the level width) x must shift to sit within half
-- a level of the player, so everything lives on the player's side of the seam
function Util.wrapDelta(x)
    local dx = x - G.player.x
    return Util.wrapSigned(dx) - dx
end

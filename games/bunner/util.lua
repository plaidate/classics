-- Game-specific helpers on top of the core Util (clamp/after/runPending).

Util = Util or {}

function Util.pick(t)
    return t[math.random(#t)]
end

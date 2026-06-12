-- Short sprite-sequence effects: pickups, clock bonuses, explosions, the
-- lost-life puff. Each entry plays prefix0..prefixN-1 then expires.

local gfx <const> = playdate.graphics

Fx = {}

-- opts: delay (frames before frame 0 shows), rise (frames after which it
-- floats upward, like the clock-bonus numbers)
function Fx.add(prefix, frames, interval, x, y, opts)
    G.fx[#G.fx + 1] = {
        prefix = prefix, frames = frames, interval = interval,
        x = x, y = y,
        t = -(opts and opts.delay or 0),
        rise = (opts and opts.rise) or -1,
    }
end

function Fx.update()
    for i = #G.fx, 1, -1 do
        local f = G.fx[i]
        f.t = f.t + 1
        if f.rise > -1 and f.t > f.rise then
            f.y = f.y - 1
        end
        if f.t >= f.frames * f.interval then
            table.remove(G.fx, i)
        end
    end
end

function Fx.draw()
    for _, f in ipairs(G.fx) do
        if f.t >= 0 then
            local frame = math.min(f.t // f.interval, f.frames - 1)
            local im = Assets.get(f.prefix .. frame)
            local w, h = im:getSize()
            im:draw(f.x - w // 2, f.y - h // 2)
        end
    end
end

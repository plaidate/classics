-- Image loading and the quantised scaled-sprite cache.
-- Everything is loaded once at startup; distance scaling reuses cached
-- downscaled copies so per-frame scaling work stays small.

local gfx <const> = playdate.graphics

Img = {}

local images = {}
local scaled = {}
local scaledCount = 0

function Img.get(name)
    local img = images[name]
    if not img then
        img = gfx.image.new("images/" .. name)
        assert(img, "missing image: " .. name)
        images[name] = img
    end
    return img
end

function Img.size(name)
    return Img.get(name):getSize()
end

-- Draw a sprite anchored bottom-centre at (cx, bottomY), scaled so that
-- it ends up targetW pixels wide. Near-native sizes draw directly,
-- moderate sizes come from a quantised cache, and big upscales (rare,
-- close-up frames only) use drawScaled to avoid caching huge images.
function Img.drawSprite(name, cx, bottomY, targetW)
    local img = Img.get(name)
    local w, h = img:getSize()
    local s = targetW / w
    if s < 0.02 then return end
    if s > 0.96 and s < 1.04 then
        img:draw(cx - w // 2, bottomY - h)
    elseif s >= 1.5 then
        img:drawScaled(cx - targetW / 2, bottomY - h * s, s)
    else
        local q
        if s < 0.2 then
            q = math.max(1, math.floor(s * 40)) / 40
        else
            q = math.floor(s * 16) / 16
        end
        local key = name .. q
        local entry = scaled[key]
        if not entry then
            local si = img:scaledImage(q)
            local sw, sh = si:getSize()
            entry = { img = si, w = sw, h = sh }
            if scaledCount > 700 then -- safety valve, never expected
                scaled = {}
                scaledCount = 0
            end
            scaled[key] = entry
            scaledCount = scaledCount + 1
        end
        entry.img:draw(cx - entry.w // 2, bottomY - entry.h)
    end
end

function Img.preload()
    local names = {
        "background", "logo", "status", "xb_a",
        "left_light", "right_light", "arrow_left", "arrow_right",
        "billboard00", "billboard01", "billboard02", "billboard03",
    }
    for i = 0, 5 do names[#names + 1] = "start" .. i end
    for i = 0, 15 do names[#names + 1] = string.format("explode%02d", i) end
    for _, letter in ipairs({ "a", "b", "c", "d", "e" }) do
        for angle = -4, 4 do
            for frame = 0, 5 do
                names[#names + 1] = "car_" .. letter .. "_" .. angle .. "_" .. frame
            end
        end
    end
    local codes = { 33, 46 }
    for c = 48, 58 do codes[#codes + 1] = c end
    for c = 65, 90 do codes[#codes + 1] = c end
    for _, c in ipairs(codes) do names[#names + 1] = "font0" .. c end
    for c = 48, 57 do names[#names + 1] = "status1b_0" .. c end
    names[#names + 1] = "status2_046"
    names[#names + 1] = "status2_058"
    for c = 48, 57 do names[#names + 1] = "status2_0" .. c end
    for _, n in ipairs(names) do Img.get(n) end
end

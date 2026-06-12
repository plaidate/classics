-- Rendering: real 1-bit artwork (half-scale conversions of the original
-- 800x480 assets, so they line up with this game's 400x240 geometry).

local gfx <const> = playdate.graphics

Draw = {}

local function img(name)
    return assert(gfx.image.new("images/" .. name), "missing image " .. name)
end

local tableImg <const> = img("table")
local ballImg <const> = img("ball")
local overImg <const> = img("over")
local menuImgs <const> = { img("menu0"), img("menu1") } -- 1P / 2P highlighted

-- per player: [1] = normal, [2] = glow (ball just bounced off the bat)
local batImgs <const> = {
    { img("bat00"), img("bat01") },
    { img("bat10"), img("bat11") },
}

local impactImgs <const> = {
    img("impact0"), img("impact1"), img("impact2"), img("impact3"), img("impact4"),
}

-- per-player digit sets (set 0 converts fully transparent: its source art
-- is sub-50% alpha, which the 1-bit conversion discards)
local digitImgs = { [0] = {}, [1] = {} }
for d = 0, 9 do
    digitImgs[0][d] = img("digit1" .. d)
    digitImgs[1][d] = img("digit2" .. d)
end

local function textWhite(s, x, y, align)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    if align then
        gfx.drawTextAligned(s, x, y, align)
    else
        gfx.drawText(s, x, y)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- Two digits per player, at half the original layout's positions.
local function drawScore(p, score)
    local s = string.format("%02d", score)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite) -- the grey digit art dithers too dark to read
    for i = 0, 1 do
        local d = tonumber(s:sub(i + 1, i + 1))
        digitImgs[p][d]:draw((255 + 160 * p + 55 * i) // 2, 23)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Draw.field()
    gfx.clear(gfx.kColorBlack)
    tableImg:draw(0, 0)
end

function Draw.play()
    Draw.field()

    drawScore(0, G.bats[1].score)
    drawScore(1, G.bats[2].score)

    for i = 1, 2 do
        local bat = G.bats[i]
        local frame = (bat.glow > 0) and 2 or 1
        batImgs[i][frame]:drawCentered(bat.x, bat.y)
    end

    if G.serveT <= 0 or G.frame % 8 < 5 then
        ballImg:drawCentered(G.ball.x, G.ball.y)
    end

    for _, im in ipairs(G.impacts) do
        -- one sprite per 2 ticks of the existing impact timer (t runs 0..10)
        local frame = math.min(im.t // 2, 4) + 1
        impactImgs[frame]:drawCentered(im.x, im.y)
    end
end

function Draw.title()
    Draw.field()
    menuImgs[G.menuSel]:draw(0, 0)
    if G.frame % 30 < 20 then
        textWhite("*PRESS A TO SERVE*", C.SCREEN_W / 2, 212, kTextAlignment.center)
    end
end

function Draw.over()
    Draw.play()
    overImg:draw(0, 0)
    local who
    if G.twoPlayer then
        who = "PLAYER " .. G.winner .. " WINS!"
    else
        who = (G.winner == 1) and "YOU WIN!" or "THE MACHINE WINS"
    end
    textWhite("*" .. who .. "*", C.SCREEN_W / 2, 170, kTextAlignment.center)
    if G.frame % 30 < 20 then
        textWhite("PRESS A FOR ANOTHER GAME", C.SCREEN_W / 2, 195, kTextAlignment.center)
    end
end

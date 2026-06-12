-- Rendering: converted 1-bit artwork over the unchanged game logic.
--
-- Asset mapping (names follow the Code the Classics originals, half scale):
--   images/pitch          500x700 backdrop; markings at x 29..471, y 39..661
--   images/player<t><d><f> 25x25 figures: t = team 0/1, d = direction 0-7
--                          (0 = up, clockwise), f = 0 stand / 1-4 run cycle
--   images/players<d><f>  matching ground shadows
--   images/ball, balls    ball and its shadow
--   images/arrow0         controlled-player indicator
--   images/goal0, goal1   top and bottom goal frames
--   images/bar, s0-s9     in-game score bar and digits
--   images/menu1<n>       menu screens, images/over<n> + l<t><n> full time
--
-- The logic pitch is 360x680 inside a 400x800 world, but the art pitch is
-- 442x622 inside 500x700, so the backdrop (and the goal frames with it) is
-- scaled per-axis once at load so the painted lines land on the logic lines.

local gfx <const> = playdate.graphics

Draw = {}

-- painted line positions inside images/pitch (see header note)
local ART_L <const>, ART_R <const> = 29, 471
local ART_T <const>, ART_B <const> = 39, 661
local ART_GOAL_CX <const> = 250 -- goal anchors in art coordinates
local ART_GOAL_TY <const>, ART_GOAL_BY <const> = 0, 700

local worldImg
local playerImgs = {} -- [team][dir][frame]; frame 0 stands, 1-4 run
local shadowImgs = {} -- [dir][frame]
local ballImg, ballShadowImg, arrowImg
local goalTop, goalBot, goalTopX, goalTopY, goalBotX, goalBotY
local barImg, sImgs = nil, {}
local lImgs = {} -- [team][score] big full-time digits
local menuImgs, overImgs = {}, {}
local goalBannerImg

local function img(name)
    local i = gfx.image.new("images/" .. name)
    assert(i, "missing image: " .. name)
    return i
end

function Draw.build()
    for team = 1, 2 do
        playerImgs[team] = {}
        for dir = 0, 7 do
            playerImgs[team][dir] = {}
            for frame = 0, 4 do
                playerImgs[team][dir][frame] =
                    img("player" .. (team - 1) .. dir .. frame)
            end
        end
    end
    for dir = 0, 7 do
        shadowImgs[dir] = {}
        for frame = 0, 4 do
            shadowImgs[dir][frame] = img("players" .. dir .. frame)
        end
    end

    ballImg = img("ball")
    ballShadowImg = img("balls")
    arrowImg = img("arrow0")
    barImg = img("bar")
    goalBannerImg = img("goal")
    for n = 0, 9 do sImgs[n] = img("s" .. n) end
    for team = 1, 2 do
        lImgs[team] = {}
        for n = 0, 9 do lImgs[team][n] = img("l" .. (team - 1) .. n) end
    end
    menuImgs[1] = img("menu10") -- EASY highlighted
    menuImgs[2] = img("menu12") -- HARD highlighted
    overImgs[0] = img("over0")  -- you (blue) win
    overImgs[1] = img("over1")  -- CPU (red) wins

    -- fit the art pitch onto the logic pitch: per-axis scale, then offset
    local sx = (C.PITCH_R - C.PITCH_L) / (ART_R - ART_L)
    local sy = (C.PITCH_B - C.PITCH_T) / (ART_B - ART_T)
    local ox = C.PITCH_L - ART_L * sx
    local oy = C.PITCH_T - ART_T * sy

    local pitchSrc = img("pitch")
    worldImg = gfx.image.new(C.WORLD_W, C.WORLD_H, gfx.kColorWhite)
    gfx.lockFocus(worldImg)
    gfx.setPattern(C.PAT_DOTS) -- letterbox bands beyond the art's 700 rows
    gfx.fillRect(0, 0, C.WORLD_W, C.WORLD_H)
    pitchSrc:drawScaled(ox, oy, sx, sy)
    gfx.unlockFocus()

    -- goal frames ride the same transform so they sit on the painted lines
    goalTop = img("goal0"):scaledImage(sx, sy)
    goalBot = img("goal1"):scaledImage(sx, sy)
    local gw, gh = goalTop:getSize()
    goalTopX = math.floor(ART_GOAL_CX * sx + ox - gw / 2 + 0.5)
    goalTopY = math.floor(ART_GOAL_TY * sy + oy - gh / 2 + 0.5)
    gw, gh = goalBot:getSize()
    goalBotX = math.floor(ART_GOAL_CX * sx + ox - gw / 2 + 0.5)
    goalBotY = math.floor(ART_GOAL_BY * sy + oy - gh / 2 + 0.5)
end

-- quantize a facing vector to the art's eight directions (0 up, clockwise)
local function dirIndex(fx, fy)
    return math.floor(4 * math.atan(fx, -fy) / math.pi + 8.5) % 8
end

-- frame 0 stands; the run cycle steps every 9 world-units of travel
local function frameIndex(p)
    if not p.moving then return 0 end
    return math.floor(p.animT / 9) % 4 + 1
end

local function drawWorld()
    local cam = math.floor(G.camY + 0.5)
    gfx.clear(gfx.kColorWhite)
    worldImg:draw(0, -cam)
    goalTop:draw(goalTopX, goalTopY - cam) -- top goal sits behind everyone

    -- players and the ball sort together on y; their shadows go on after
    local order = {}
    for i, p in ipairs(G.players) do order[i] = p end
    local ball = G.ball
    if ball then order[#order + 1] = ball end
    table.sort(order, function(a, b) return a.y < b.y end)

    for _, o in ipairs(order) do
        local x, y = math.floor(o.x + 0.5), math.floor(o.y + 0.5) - cam
        if y > -26 and y < C.SCREEN_H + 26 then
            if o.team then
                playerImgs[o.team][dirIndex(o.fx, o.fy)][frameIndex(o)]
                    :draw(x - 12, y - 18)
            else
                ballImg:draw(x - 6, y - 8) -- ball rides 2px above its spot
            end
        end
    end
    for _, o in ipairs(order) do
        local x, y = math.floor(o.x + 0.5), math.floor(o.y + 0.5) - cam
        if y > -26 and y < C.SCREEN_H + 26 then
            if o.team then
                shadowImgs[dirIndex(o.fx, o.fy)][frameIndex(o)]
                    :draw(x - 12, y - 18)
            else
                ballShadowImg:draw(x - 6, y - 5)
            end
        end
    end

    goalBot:draw(goalBotX, goalBotY - cam) -- bottom goal fronts everyone

    local p = G.ctl
    if p and G.state ~= "menu" then
        local x, y = math.floor(p.x + 0.5), math.floor(p.y + 0.5) - cam
        local bob = (G.frame % 20 < 10) and 0 or 1
        arrowImg:draw(x - 5, y - 23 + bob)
        if G.charge then
            local w = Util.clamp(G.charge * C.CHARGE_RATE
                / (C.KICK_MAX - C.KICK_MIN), 0, 1) * 16
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(x - 8, y - 30, 16, 4)
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(x - 8, y - 30, 16, 4)
            gfx.fillRect(x - 8, y - 30, math.floor(w), 4)
        end
    end
end

local function drawHud()
    -- score bar reads "RED team .. v .. BLUE team": you are blue, on the right
    barImg:draw(112, 0)
    sImgs[math.min(G.score[1], 9)]:draw(203, 3)
    sImgs[math.min(G.score[2], 9)]:draw(184, 3)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(330, 0, 70, 18)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(330, 0, 70, 18)
    local t = math.floor(G.clock)
    gfx.drawTextAligned(string.format("%s %d:%02d",
        (G.half == 1) and "1ST" or "2ND", t // 60, t % 60),
        C.SCREEN_W - 8, 1, kTextAlignment.right)
end

function Draw.play()
    Sfx.matchScene()
    drawWorld()
    drawHud()
end

function Draw.banner(text)
    if text == "GOAL!" then
        goalBannerImg:draw(50, 76)
        return
    end
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(110, 100, 180, 34)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(110, 100, 180, 34)
    gfx.drawRect(112, 102, 176, 30)
    gfx.drawTextAligned("*" .. text .. "*", 200, 109, kTextAlignment.center)
end

local function recordLine()
    local r = G.record
    return "RECORD  W " .. r.w .. "   D " .. r.d .. "   L " .. r.l
end

function Draw.menu()
    Sfx.menuScene()
    menuImgs[G.difficulty]:draw(0, 0)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite) -- white text on the art
    gfx.drawTextAligned(recordLine(), 200, 2, kTextAlignment.center)
    if G.frame % 180 < 90 then
        if G.frame % 30 < 20 then
            gfx.drawTextAligned("*PRESS A TO KICK OFF*", 200, 222,
                kTextAlignment.center)
        end
    else
        gfx.drawTextAligned("d-pad: run   B: switch   hold A: kick", 200, 222,
            kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function Draw.fulltime()
    Sfx.matchScene()
    local cpuWon = G.score[2] > G.score[1]
    overImgs[cpuWon and 1 or 0]:draw(0, 0)
    lImgs[1][math.min(G.score[1], 9)]:draw(212, 72)
    lImgs[2][math.min(G.score[2], 9)]:draw(150, 72)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    if G.score[1] == G.score[2] then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        gfx.setColor(gfx.kColorBlack) -- hide the "team wins" strap on a draw
        gfx.fillRect(40, 110, 320, 100)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("*IT'S A DRAW*", 200, 150, kTextAlignment.center)
    end
    gfx.drawTextAligned(recordLine(), 200, 2, kTextAlignment.center)
    if G.frame % 30 < 20 then
        gfx.drawTextAligned("PRESS A FOR THE MENU", 200, 222,
            kTextAlignment.center)
    end
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

-- The crank is the bat. D-pad works as a fallback; A serves and fires.

Input = {}

local botDrift = 0

-- Returns: dx (bat movement in px), fireDown, firePressed.
function Input.gather()
    if Harness.enabled then
        if G.state ~= "play" or not G.bat then
            return 0, false, true
        end
        -- shadow the lowest ball, with a wandering aim error
        botDrift = Util.clamp(botDrift + math.random(-1, 1), -20, 20)
        local targetX
        if G.portalOpen then
            targetX = C.SCREEN_W + 60 -- head for the exit
        else
            local lowest
            for _, b in ipairs(G.balls) do
                if not lowest or b.y > lowest.y then lowest = b end
            end
            targetX = (lowest and lowest.x or G.bat.x) + botDrift
        end
        local dx = Util.clamp(targetX - G.bat.x, -C.BAT_DPAD_PX, C.BAT_DPAD_PX)
        return dx, math.random(4) == 1, true
    end

    local dx = playdate.getCrankChange() * C.CRANK_RATIO
    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        dx = dx - C.BAT_DPAD_PX
    end
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        dx = dx + C.BAT_DPAD_PX
    end
    return dx, playdate.buttonIsPressed(playdate.kButtonA),
        playdate.buttonJustPressed(playdate.kButtonA)
end

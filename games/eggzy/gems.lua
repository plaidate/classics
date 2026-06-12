-- Gems and the exit door. Grabbing a gem feeds the clock, the score, and a
-- short combo window; clearing them all swings the door open.

Gems = {}

function Gems.update()
    local p = G.player
    if p and not p.hurt then
        local left, top = p.x - C.PLAYER_HALF_W, p.y - C.PLAYER_H
        for i = #G.gems, 1, -1 do
            local g = G.gems[i]
            local cx, cy = g.x, g.y - 16 -- gem sprite center
            if cx >= left and cx <= left + C.PLAYER_HALF_W * 2
                and cy >= top and cy <= p.y then
                table.remove(G.gems, i)
                if G.comboT > 0 then
                    G.combo = G.combo + 1
                else
                    G.combo = 1
                end
                G.comboT = C.COMBO_WINDOW
                G.addScore(C.GEM_SCORE * G.combo)
                G.gainTime(G.gemBonus(), cx, cy)
                Harness.count("collects")
                Sfx.play("collect")
            end
        end
    end

    if G.comboT > 0 then
        G.comboT = G.comboT - 1
        if G.comboT == 0 then G.combo = 0 end
    end

    if #G.gems == 0 and not G.exitOpen then
        G.exitOpen = true
    end

    local d = G.door
    if d and G.exitOpen and d.frame < 13 and G.frame % 3 == 0 then
        d.frame = d.frame + 1
    end
end

-- true when the player can leave through the door
function Gems.atExit()
    local d, p = G.door, G.player
    return d and G.exitOpen and d.frame >= 13 and p and not p.hurt
        and p.landed and math.abs(p.x - d.x) < 12 and math.abs(p.y - d.y) < 6
end

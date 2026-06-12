-- Pitch geometry: bounds for players, the ball, and the goal mouths.

Pitch = {}

function Pitch.attackDir(team)
    return team == 1 and -1 or 1
end

function Pitch.goalY(team) -- the goal this team attacks
    return team == 1 and C.PITCH_T or C.PITCH_B
end

-- players may roam the surround but not walk through the goal frames
function Pitch.canWalk(x, y)
    if x < 8 or x > C.WORLD_W - 8 then return false end
    if math.abs(x - C.CENTER_X) < C.GOAL_HALF_W + 8 then
        return y > C.PITCH_T and y < C.PITCH_B
    end
    return y > 16 and y < C.WORLD_H - 16
end

-- where the ball may be dribbled: the pitch plus the goal mouths
function Pitch.onPitch(x, y)
    if x >= C.PITCH_L and x <= C.PITCH_R and y >= C.PITCH_T and y <= C.PITCH_B then
        return true
    end
    return math.abs(x - C.CENTER_X) < C.GOAL_HALF_W
        and y > C.PITCH_T - C.GOAL_DEPTH and y < C.PITCH_B + C.GOAL_DEPTH
end

function Pitch.ballBoundsX(y)
    if y < C.PITCH_T or y > C.PITCH_B then
        return C.CENTER_X - C.GOAL_HALF_W, C.CENTER_X + C.GOAL_HALF_W
    end
    return C.PITCH_L, C.PITCH_R
end

function Pitch.ballBoundsY(x)
    if math.abs(x - C.CENTER_X) < C.GOAL_HALF_W then
        return C.PITCH_T - C.GOAL_DEPTH + 3, C.PITCH_B + C.GOAL_DEPTH - 3
    end
    return C.PITCH_T, C.PITCH_B
end

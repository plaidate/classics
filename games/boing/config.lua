-- Tunables and harness flags.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    -- field (the source design is 800x480: everything here is half scale)
    BAT_X = 20,          -- distance of each bat from its wall
    BAT_HALF_H = 32,
    BAT_HIT_X = 172,     -- |x - center| where bat collision happens
    WALL_HALF_H = 110,   -- |y - center| where the ball bounces

    BALL_START_SPEED = 5, -- unit steps per frame
    PLAYER_SPEED = 3,     -- px per frame (d-pad)
    CRANK_RATIO = 0.6,    -- px of bat travel per degree of crank
    MAX_AI_SPEED = 3,

    WIN_SCORE = 10,
}


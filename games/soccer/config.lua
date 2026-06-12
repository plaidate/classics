-- Tunables, dither patterns, and harness flags.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    WORLD_W = 400,
    WORLD_H = 800,
    PITCH_L = 20,
    PITCH_R = 380,
    PITCH_T = 60,
    PITCH_B = 740,
    CENTER_X = 200,
    CENTER_Y = 400,
    GOAL_HALF_W = 32, -- open goals, no keepers: kept small on purpose
    GOAL_DEPTH = 14,

    HALF_LEN = SMOKE_BUILD and 25 or 90, -- seconds per half (smoke runs short halves)

    CONTROL_DIST = 9, -- within this of the ball, a player can take it
    DRIBBLE_LEAD = 9, -- the ball rides this far ahead of the carrier

    RUN_SPEED = 80,        -- AI default
    CARRY_SPEED = 86,      -- CPU carrier (plus difficulty boost)
    INTERCEPT_SPEED = 95,  -- AI players closing on a loose ball
    CHASE_SPEED = 97,      -- chasers hunting the carrier
    CTL_CARRY_SPEED = 96,  -- controlled player with the ball
    CTL_SPEED = 106,       -- controlled player without

    KICK_MIN = 200,
    KICK_MAX = 300,
    CHARGE_RATE = 250, -- kick power gained per second of holding A
    FRICTION = 0.97,   -- ball speed multiplier per frame
    PASS_RANGE = 190,
    SHOOT_RANGE = 170,

    STEAL_HOLDOFF = 2,   -- seconds a dispossessed player can't retake the ball
    KICK_HOLDOFF = 0.35, -- so a kicker doesn't trap his own kick

    PAT_50 = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 },
    PAT_DOTS = { 0x11, 0x00, 0x00, 0x00, 0x44, 0x00, 0x00, 0x00 },
}

-- difficulty presets: CPU pace boost, chasers on the carrier, pass patience
C.DIFFICULTY = {
    { name = "EASY", boost = 0,  chasers = 1, patience = 2.4 },
    { name = "HARD", boost = 14, chasers = 2, patience = 1.2 },
}

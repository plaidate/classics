-- Tunables, dither patterns, and harness flags.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    TILE = 16,
    COLS = 25,

    GRAVITY = 620,
    MAX_FALL = 300,
    RUN_SPEED = 120,
    JUMP_VY = -305,

    MAX_ORBS = 5,
    ORB_SPEED = 120,
    ORB_RISE = 42,
    ORB_LIFE = 4.2,
    ORB_BLOW0 = 0.12,    -- seconds of horizontal travel before floating
    ORB_BLOW_MAX = 2.0,  -- holding B can extend travel up to this
    ORB_COOLDOWN = 0.35,

    BOLT_SPEED = 210,
    FLAME_RANGE = 44,
    FLAME_COOLDOWN = 2.5,

    START_LIVES = 2,
    START_HEALTH = 3,
    HURT_TIME = 3.4,  -- full invulnerability window after a hit
    KNOCK_TIME = 1.7, -- portion of HURT_TIME spent knocked back, ends early on landing
    KNOCK_VY = -230,
    KNOCK_SPEED = 120,

    FRUIT_TTL = 8,
    FRUIT_RAIN_FRAMES = 50,
    ROBOT_DROP_FRAMES = 40,

    PAT_25 = { 0x88, 0x00, 0x22, 0x00, 0x88, 0x00, 0x22, 0x00 },
    PAT_50 = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 },
    PAT_75 = { 0xEE, 0xBB, 0xEE, 0xBB, 0xEE, 0xBB, 0xEE, 0xBB },
    PAT_DIAG = { 0x88, 0x44, 0x22, 0x11, 0x88, 0x44, 0x22, 0x11 },
}

-- Tunables, dither patterns, and harness flags.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    -- the field: 16px cells, the bottom four rows are the player's zone
    CELL = 16,
    COLS = 25,
    ROWS = 15,
    ZONE_ROW = 11,

    PLAYER_SPEED = 110,
    CRANK_NUDGE = 0.25,    -- pixels of strafe per crank degree
    FIRE_COOLDOWN = 0.125, -- ~8 shots per second
    BULLET_SPEED = 300,
    RESPAWN_TIME = 1.7,
    INVULN_TIME = 1.7,

    BASE_PACE = 8,      -- myriapod cells per second on wave 1
    PACE_PER_WAVE = 0.5,
    MAX_PACE = 14,
    FAST_WAVE_MULT = 1.4, -- every fourth wave is a sprinter

    ROCK_HP = 3,
    BASE_ROCKS = 30, -- plus one per wave

    START_LIVES = 3,
    EXTRA_LIFE_AT = 10000,

    BEE_CHANCE = 0.004, -- per-frame spawn rolls
    FLY_CHANCE = 0.004,
    SPIDER_CHANCE = 0.008,

    PAT_25 = { 0x88, 0x00, 0x22, 0x00, 0x88, 0x00, 0x22, 0x00 },
    PAT_50 = { 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55 },
    PAT_75 = { 0xEE, 0xBB, 0xEE, 0xBB, 0xEE, 0xBB, 0xEE, 0xBB },
}

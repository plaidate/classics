-- Tunables and harness flags.
-- All world units are half the original arcade-pixel scale, at 30fps.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    -- the wrapping world
    LEVEL_W = 2048,
    LEVEL_H = 320,
    TERRAIN_Y = 80, -- the terrain image hangs this far below the world's top

    -- camera: the ship sits a third in from the edge it is flying away from
    CAM_NEAR = 133,
    CAM_FAR = 267,
    CAM_LEAD = 7.5, -- extra look-ahead px per px/frame of ship speed
    CAM_EASE = 10,
    CAM_MAX_STEP = 8,

    -- ship handling (per-frame drag and thrust force)
    DRAG_X = 0.96,
    DRAG_Y = 0.81,
    FORCE_X = 0.4,
    FORCE_Y = 0.95,
    CRANK_Y = 0.25, -- px of altitude per degree of crank

    START_LIVES = 5,
    MAX_SHIELDS = 5,
    HURT_TIME = 30,
    EXPLODE_TIME = 36, -- 18 explosion sprites, two ticks each
    FIRE_COOLDOWN = 5,
    LASER_SPEED = 20,
    LASER_RANGE = 400,
    BULLET_RANGE = 480,
    PICKUP_RANGE = 20, -- how close the ship must fly to catch a faller
    CARRY_DY = 25,     -- a carried human hangs this far below its carrier

    HUMAN_GRAVITY = 0.1,
    HUMAN_MAX_FALL = 4,
    HUMAN_FATAL_FALL = 3, -- landing faster than this is lethal

    APPEAR_TIME = 16, -- frames of the materialise animation
    SKY_Y = 32,       -- abduction altitude: humans become mutants here
    ENEMY_SCORE = 150,
    BAITER_INTERVAL = 900, -- a fresh baiter hunts campers every 30 seconds
    WAVE_COMPLETE_TIME = 160,

    -- minimap strip, centered at the top of the screen
    RADAR_X = 111,
    RADAR_Y = 2,
    RADAR_W = 177,
    RADAR_H = 29,
}

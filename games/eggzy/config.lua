-- Tunables and harness flags.
-- Movement numbers are ported from the reference game's 60fps full-scale
-- values to 30fps at half scale (px/frame doubles, distances halve).

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    TILE = 16,
    COLS = 25,
    ROWS = 15,

    -- player movement
    RUN_SPEED = 5,       -- px/frame
    RUN_ACCEL = 2,       -- px/frame^2 toward target speed
    JUMP_VY = -10,       -- jump impulse
    GRAVITY = 1,         -- px/frame^2
    LOW_GRAVITY = 0.67,  -- gentler gravity right after takeoff
    LOW_GRAV_FRAMES = 3,
    MAX_FALL = 7,
    COYOTE_FRAMES = 3,   -- jump grace after walking off a ledge
    JUMP_BUFFER_FRAMES = 3,
    JUMP_CUT = 2,        -- extra rise decay once A is released
    CLIMB_SPEED = 3,
    LADDER_GRAB_RANGE = 8,
    PLAYER_HALF_W = 5,
    PLAYER_H = 20,

    STOMP_BOUNCE_VY = -6,
    HURT_VY = -12,
    SPAWN_CLEAR_RADIUS = 75, -- enemies this close to a respawn are destroyed

    -- the clock (seconds)
    LEVEL_TIME = SMOKE_BUILD and 120 or 30, -- the smoke bot navigates slowly; humans get the real clock
    GEM_TIME_BONUS = { 2, 1, 0.5 }, -- by layout cycle, clamped to the last
    STOMP_TIME_BONUS = 3,

    START_LIVES = 3,
    GEM_SCORE = 100,     -- multiplied by the current combo
    STOMP_SCORE = 200,
    CLEAR_SCORE = 500,
    CLEAR_TIME_SCORE = 10, -- per second left on the clock
    COMBO_WINDOW = 90,   -- frames to chain gem combos

    WALKER_SPEED = 2,
    FLYER_SPEED = 2,

    DRAW_BG = true, -- draw the dithered biome backdrops behind the level
}


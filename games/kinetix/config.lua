-- Tunables.
-- The arena art is 320x320 (half the original's 640 field) centered on the
-- 400x240 screen; everything below y=240 simply falls off the open bottom.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    ARENA_X = 40,        -- left edge of the 320-wide arena art
    ARENA_W = 320,

    LEFT_EDGE = 52,      -- inner faces of the walls, in screen px
    RIGHT_EDGE = 348,
    TOP_EDGE = 25,

    BAT_Y = 218,         -- the bat's collision line (its top face)
    BAT_ART_LIFT = 7,    -- bat art pokes this far above the collision line
    BAT_MIN_X = 58,      -- bat centre limits, before half-width is added
    BAT_MAX_X = 342,
    BAT_DPAD_PX = 8,     -- d-pad bat speed, px per frame
    CRANK_RATIO = 0.85,  -- bat px per crank degree (one turn spans the field)

    BALL_R = 3.5,
    SERVE_OFFSET = 5,        -- ball rests this far right of bat centre
    BALL_START_SPEED = 5,    -- whole-pixel sub-steps per frame
    BALL_MIN_SPEED = 4,
    BALL_MAX_SPEED = 11,
    SPEED_UP_SECS = 10,      -- creep one speed step this often...
    SPEED_UP_SECS_FAST = 15, -- ...or this often once already moving fast
    FAST_THRESHOLD = 7,
    NEGLECT_SECS = 5,        -- ball away from bat this long: timer runs double
    STUCK_SECS = 30,         -- no brick/bat contact: metal bricks soften

    GRID_X = 50,         -- brick grid origin, screen px
    GRID_Y = 48,
    BRICK_W = 20,
    BRICK_H = 10,
    GRID_COLS = 15,

    SHADOW = 5,          -- drop-shadow offset for bricks and capsules
    BIG_SHADOW = 8,      -- ...and for the ball and bat

    DROP_CHANCE = 0.2,   -- chance a broken brick sheds a capsule
    BULLET_SPEED = 8,    -- px per frame, straight up
    FIRE_COOLDOWN = 15,  -- frames between gun volleys
    PORTAL_FRAME_T = 3,  -- frames per portal-opening animation step
    PORTAL_X = 330,      -- where the exit portal is drawn (centre)
    PORTAL_Y = 212,

    BRICK_SCORE = 10,
    START_LIVES = 3,
}

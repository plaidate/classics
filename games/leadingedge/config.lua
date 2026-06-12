-- Tunables and harness flags.
-- World distances are half the desktop original's; Z is measured in
-- track pieces and is unchanged.

C = {
    SCREEN_W = 400, SCREEN_H = 240,
    HALF_W = 200, HALF_H = 120,
    DT = 1 / 30,

    -- world geometry
    TRACK_W = 1500,      -- full road width in world units
    HALF_STRIPE_W = 12,  -- centre stripe half-width
    HALF_RUMBLE_W = 125, -- rumble strip width beyond the road edge
    LAMP_X = 900,        -- TRACK_W/2 + 150
    BILLBOARD_X = 1050,  -- TRACK_W/2 + 300

    -- camera / projection
    CAM_HEIGHT = 200,
    CAM_FOLLOW = 2,      -- camera trails the car by this many pieces
    VIEW = 40,           -- track pieces drawn ahead
    CLIP = -0.25,        -- near plane for road and scenery
    CLIP_CARS = -0.08,   -- cars may come a little closer before vanishing
    MAX_CAR_W = 320,     -- skip sprites that would scale wider than this
    MAX_SCENERY_W = 480,

    -- player handling
    LOSE_GRIP_SPEED = 50,
    ZERO_GRIP_SPEED = 100,
    ACCEL_MAX = 20,
    ACCEL_MIN = 10,
    HIGH_ACCEL = 30,     -- below this speed, acceleration is strongest
    CORNER_PUSH = 5.8,   -- how hard corners shove you outward
    STEER_STRENGTH = 36,
    SKID_GRIP = 0.8,     -- skid sound fades in below this grip

    -- rivals
    CPU_MIN_SPEED = 40,
    CPU_MAX_SPEED = 65,
    NUM_CARS = 20,
    GRID_SPACING = 0.55,

    NUM_LAPS = 5,
    TIME_LIMIT = 240,    -- seconds per lap before the race is called off
    DEMO_RESET = 120,    -- title-screen demo race restarts after this

    CRANK_STEER = 0.04,  -- steering input per degree of crank turn
}

-- Tunables and harness flags.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    -- the world is horizontal bands, hopped one cell at a time
    ROW_H = 24,
    CELL_W = 20,
    COLS = 20,
    EDGE_PAD = 10,

    HOP_TIME = 0.15,
    HOP_QUEUE = 3,

    SCROLL_BASE = 14, -- px/s; up to 3x when the rabbit nears the top
    OFF_BOTTOM = 28,  -- px past the bottom edge before the eagle strikes

    CAR_W = { 32, 44 },
    CAR_SPEED_MIN = 30,
    CAR_SPEED_MAX = 60,
    CAR_SPEED_CAP = 90,
    CAR_SPEED_RAMP = 0.5, -- extra px/s per row of progress
    CAR_GAP = 110,        -- min empty px between cars at populate time
    CAR_GAP_VAR = 150,
    CAR_SPACING = 160,    -- min px between spawned cars

    LOG_W = { 48, 72 },
    LOG_SPEED_MIN = 18,
    LOG_SPEED_MAX = 42,
    LOG_GAP = 50,
    LOG_GAP_VAR = 80,
    LOG_SPACING = 130,

    TRAIN_W = 220,
    TRAIN_SPEED = 300,
    TRAIN_WARN = 1.0,     -- seconds of bell before the train arrives
    TRAIN_CHANCE = 0.012, -- per-frame spawn chance while the track is visible

    DEATH_PAUSE = 1.6,
    EAGLE_PAUSE = 2.6,
    EAGLE_SPEED = 280,

    CRANK_HOP = 60, -- degrees of forward crank per up-hop
    SPAWN_PAD = 60, -- how far offscreen movers spawn and are culled
}

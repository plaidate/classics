-- Tunables and harness flags.
-- The street is a 400x240 view onto a scrolling world; y is the depth band.
-- The reference art was drawn at 2x and 60fps, so distances are halved,
-- frame counts halved, per-frame velocities kept, accelerations doubled.

C = {
    SCREEN_W = 400,
    SCREEN_H = 240,
    DT = 1 / 30,

    MIN_Y = 155,  -- top of the walkable street band
    MAX_Y = 239,  -- bottom of the screen

    GRAVITY = 0.8,       -- per-frame, for jump kicks
    KNOCKBACK = 5,       -- px/frame shove when knocked down
    KNOCK_FRICTION = 1,  -- px/frame^2 slide decay while down
    STUN_PER_DMG = 4,    -- hit-stun frames per point of damage
    DOWN_TIME = 60,      -- frames flat on the ground before getting up
    KO_TIME = 120,       -- frames from knockdown to removal when out of health
    GETUP_TIME = 10,

    PLAYER_HP = 30,
    LIVES = 3,
    PLAYER_SPEED_X = 3,
    PLAYER_SPEED_Y = 2,
    COMBO_WINDOW = 15,     -- frames after an attack ends to chain the next punch
    FLYKICK_VX = 3,
    FLYKICK_VY = -8,

    MAX_ATTACKERS = 2,     -- enemies allowed to move in on the player at once
    APPROACH_DIST = 42,    -- enemies hover at this x offset before swinging
    ATTACK_CHANCE = 10,    -- 1-in-N per frame to swing once in position
    BACKAWAY_CHANCE = 250, -- 1-in-N per frame to retreat from a swinging player
    HALF_HIT_W = 12,       -- half width of a fighter's hittable area
    HALF_HIT_H = 10,       -- depth tolerance for attacks to connect

    SCROLL_TRIGGER = 250,  -- player screen x that starts a GO scroll
    TILE_SPACING = 145,    -- background building tile pitch
    TILE_W = 208,

    BARREL_HP = 3,
    BARREL_SCORE = 5,
    HEAL_AMOUNT = 10,
    PICKUP_RADIUS = 15,

    HEALTH_BAR_W = 117,
    HEALTH_BAR_H = 13,
}

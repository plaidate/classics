-- Shared game state and the helpers that mutate it.

G = {
    state = "menu", -- "menu" | "play" | "goal" | "halftime" | "fulltime"
    frame = 0,
    stateT = 0,
    difficulty = 1,
    score = { 0, 0 }, -- team 1 (you, attacking the top goal) and team 2 (CPU)
    half = 1,
    clock = 0,
    camY = 280,
    players = {},
    ball = nil,
    ctl = nil,        -- the player under human control
    kickPlayer = nil, -- who takes the kickoff while prekick is set
    prekick = false,
    kickTeam = 1,
    charge = nil, -- kick power accumulates while A is held
}

function G.diff()
    return C.DIFFICULTY[G.difficulty]
end

local saved = playdate.datastore.read()
G.record = (saved and saved.record) or { w = 0, d = 0, l = 0 }

function G.saveRecord()
    playdate.datastore.write({ record = G.record })
end

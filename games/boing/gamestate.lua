-- Shared state.

G = {
    state = "title", -- "title" | "play" | "over"
    frame = 0,
    twoPlayer = false,
    bats = nil,
    ball = nil,
    impacts = {},
    aiOffset = 0,
    serveT = 0,
    winner = nil,
    overT = 0,
    menuSel = 1,
}

-- Shared game state and persisted records.

G = {
    state = "title", -- "title" | "play" | "gameover"
    frame = 0,
    stateT = 0,
    demoT = 0,
    race = nil,
    input = { steer = 0, accel = false, brake = false },
    newLapRecord = false,
    newRaceRecord = false,
}

local saved = playdate.datastore.read()
G.bestLap = saved and saved.bestLap or nil
G.bestRace = saved and saved.bestRace or nil

-- Called once when a race is properly completed. Returns whether each
-- record was beaten.
function G.saveRecords(fastestLap, raceTime)
    local newLap = (fastestLap ~= nil) and (not G.bestLap or fastestLap < G.bestLap)
    local newRace = (raceTime ~= nil) and (not G.bestRace or raceTime < G.bestRace)
    if newLap then G.bestLap = fastestLap end
    if newRace then G.bestRace = raceTime end
    if newLap or newRace then
        Harness.count("records")
        playdate.datastore.write({ bestLap = G.bestLap, bestRace = G.bestRace })
    end
    return newLap or false, newRace or false
end

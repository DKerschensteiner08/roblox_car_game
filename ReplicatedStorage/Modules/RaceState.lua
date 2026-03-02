--!strict
-- Shared race-state shape placeholder.
-- Ticket 3/4 can expand this into strict typed payload contracts.

export type PlayerRaceProgress = {
	currentLap: number,
	nextCheckpointIndex: number,
	lapStartTime: number?,
	lastLapTime: number?,
	bestLapTime: number?,
}

export type RacePhase = "Waiting" | "Countdown" | "Racing" | "Finished"

local RaceState = {}

return RaceState

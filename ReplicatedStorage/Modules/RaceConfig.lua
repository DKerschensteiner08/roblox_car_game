--!strict
-- Shared race/game config scaffold.
-- Keep authoritative validation on the server; clients may read for UI hints only.

local RaceConfig = {
	Game = {
		MinPlayersToStart = 1,
		DefaultLaps = 3,
	},

	Checkpoints = {
		FolderName = "Checkpoints",
		FinishLineName = "FinishLine",
	},

	Rewards = {
		Participation = 10,
		LapComplete = 5,
		RaceWin = 25,
	},
}

return RaceConfig

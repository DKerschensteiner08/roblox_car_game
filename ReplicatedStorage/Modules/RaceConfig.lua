--!strict
-- Shared race/game config scaffold.
-- Keep authoritative validation on the server; clients may read for UI hints only.

local RaceConfig = {
	Game = {
		MinPlayersToStart = 1,
		DefaultLaps = 3,
		RaceStateBroadcastRate = 0.2,
		LeaderboardBroadcastRate = 1.0,
	},

	Checkpoints = {
		FolderName = "Checkpoints",
		FinishLineName = "FinishLine",
		DefaultCount = 3,
		CheckpointSpacing = 120,
		StartPosition = Vector3.new(0, 4, 0),
	},

	Rewards = {
		Participation = 10,
		LapComplete = 5,
		RaceWin = 25,
	},
}

return RaceConfig

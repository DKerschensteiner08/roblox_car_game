--!strict
-- Central list of RemoteEvent names used across client/server.
-- Ticket 1 creates them; Tickets 2-5 will start publishing payload contracts here.

local RemoteNames = {
	-- Client -> Server requests
	CarSpawnRequest = "CarSpawnRequest", -- spawn/respawn current car
	CarResetRequest = "CarResetRequest", -- flip recovery/reset
	CarSelectRequest = "CarSelectRequest", -- garage selection

	-- Server -> Client race updates
	RaceStateUpdate = "RaceStateUpdate", -- race phase + lap/checkpoint status
	CheckpointProgress = "CheckpointProgress", -- per-checkpoint progression debug/UI
	LapTimerUpdate = "LapTimerUpdate", -- current lap timer and finished lap times
	LeaderboardUpdate = "LeaderboardUpdate", -- best lap/current lap leaderboard feed
	RewardUpdate = "RewardUpdate", -- earned rewards/currency notices
}

return RemoteNames

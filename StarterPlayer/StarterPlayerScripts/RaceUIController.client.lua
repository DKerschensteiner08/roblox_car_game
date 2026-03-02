--!strict
-- Client UI scaffold: race progress and lap timer display.
-- Server remains source of truth for race/lap completion.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("RemoteNames"))

local checkpointRemote = remotesFolder:WaitForChild(RemoteNames.CheckpointProgress) :: RemoteEvent
local lapTimerRemote = remotesFolder:WaitForChild(RemoteNames.LapTimerUpdate) :: RemoteEvent
local leaderboardRemote = remotesFolder:WaitForChild(RemoteNames.LeaderboardUpdate) :: RemoteEvent

checkpointRemote.OnClientEvent:Connect(function(payload)
	-- TODO(Ticket 3): Render checkpoint/lap debug status.
	print("[RaceUI] CheckpointProgress", payload)
end)

lapTimerRemote.OnClientEvent:Connect(function(payload)
	-- TODO(Ticket 4): Update lap timer UI.
	print("[RaceUI] LapTimerUpdate", payload)
end)

leaderboardRemote.OnClientEvent:Connect(function(payload)
	-- TODO(Ticket 5): Update leaderboard UI.
	print("[RaceUI] LeaderboardUpdate", payload)
end)

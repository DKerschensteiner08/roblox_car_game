--!strict
-- Server-authoritative race service scaffold.
-- Ticket 3/4 will own checkpoint + lap validation and timer truth here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(modulesFolder:WaitForChild("RemoteNames"))
local RaceConfig = require(modulesFolder:WaitForChild("RaceConfig"))

local RaceService = {}

local function onPlayerAdded(player: Player)
	local raceStateRemote = remotesFolder:WaitForChild(RemoteNames.RaceStateUpdate) :: RemoteEvent
	raceStateRemote:FireClient(player, {
		phase = "Waiting",
		lapsRequired = RaceConfig.Game.DefaultLaps,
	})
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

return RaceService

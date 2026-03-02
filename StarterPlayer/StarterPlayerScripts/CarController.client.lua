--!strict
-- Client car input helper for Ticket 2.
-- R = flip recovery/reset, T = respawn car.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("RemoteNames"))

local carResetRemote = remotesFolder:WaitForChild(RemoteNames.CarResetRequest) :: RemoteEvent
local carSpawnRemote = remotesFolder:WaitForChild(RemoteNames.CarSpawnRequest) :: RemoteEvent

local function requestSpawn()
	carSpawnRemote:FireServer()
end

requestSpawn()
localPlayer.CharacterAdded:Connect(function()
	task.delay(0.3, requestSpawn)
end)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		carResetRemote:FireServer()
	elseif input.KeyCode == Enum.KeyCode.T then
		carSpawnRemote:FireServer()
	end
end)

print("[CarController] Ready. Controls: R=Reset, T=Respawn")

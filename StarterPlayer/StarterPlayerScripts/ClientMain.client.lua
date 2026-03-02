--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local RemoteNames = require(modulesFolder:WaitForChild("Shared"):WaitForChild("RemoteNames"))
local requestSpawnCar = remotesFolder:WaitForChild(RemoteNames.Functions.RequestSpawnCar) :: RemoteFunction
local requestResetCar = remotesFolder:WaitForChild(RemoteNames.Functions.RequestResetCar) :: RemoteFunction

local function requestSpawn()
	local ok, msg = requestSpawnCar:InvokeServer()
	if not ok then
		warn("[ClientMain] Spawn failed:", msg)
	end
end

requestSpawn()

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		requestResetCar:InvokeServer()
	elseif input.KeyCode == Enum.KeyCode.T then
		requestSpawn()
	end
end)

print("[ClientMain] Client started (R reset, T respawn)")

--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local RemoteNames = require(modulesFolder:WaitForChild("Shared"):WaitForChild("RemoteNames"))
local requestSpawnCar = remotesFolder:WaitForChild(RemoteNames.Functions.RequestSpawnCar) :: RemoteFunction
local requestResetCar = remotesFolder:WaitForChild(RemoteNames.Functions.RequestResetCar) :: RemoteFunction
local systemMessageRemote = remotesFolder:WaitForChild(RemoteNames.Events.SystemMessage) :: RemoteEvent

local function playUiSfx(_sfxName: string)
	-- SFX hook stub for later integration.
	-- Example: play click/success/fail sounds from SoundService.
end

local function requestSpawn()
	local ok, msg = requestSpawnCar:InvokeServer()
	if not ok then
		warn("[ClientMain] Spawn failed:", msg)
	else
		playUiSfx("spawn")
	end
end

requestSpawn()

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		requestResetCar:InvokeServer()
		playUiSfx("reset")
	elseif input.KeyCode == Enum.KeyCode.T then
		requestSpawn()
	end
end)

systemMessageRemote.OnClientEvent:Connect(function(payload)
	local msg = tostring(payload.Message or "")
	if string.find(string.lower(msg), "purchased") then
		playUiSfx("success")
	elseif string.find(string.lower(msg), "not enough") then
		playUiSfx("fail")
	end
end)

print("[ClientMain] Client started (R reset, T respawn)")

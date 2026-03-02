--!strict
-- Ticket 1 bootstrap:
-- Ensures ReplicatedStorage/Remotes exists and all required RemoteEvents are present.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local RemoteNames = require(ModulesFolder:WaitForChild("RemoteNames"))

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

for _, remoteName in pairs(RemoteNames) do
	local existing = remotesFolder:FindFirstChild(remoteName)
	if existing == nil then
		local remote = Instance.new("RemoteEvent")
		remote.Name = remoteName
		remote.Parent = remotesFolder
	end
end

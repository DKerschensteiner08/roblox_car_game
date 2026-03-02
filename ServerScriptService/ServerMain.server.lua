--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local RemoteNames = require(modulesFolder:WaitForChild("Shared"):WaitForChild("RemoteNames"))

local function ensureRemoteEvent(name: string)
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = remotesFolder
	return ev
end

local function ensureRemoteFunction(name: string)
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteFunction") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local fn = Instance.new("RemoteFunction")
	fn.Name = name
	fn.Parent = remotesFolder
	return fn
end

for _, eventName in pairs(RemoteNames.Events) do
	ensureRemoteEvent(eventName)
end
for _, functionName in pairs(RemoteNames.Functions) do
	ensureRemoteFunction(functionName)
end

local servicesFolder = ServerScriptService:WaitForChild("Services")
local orderedServices = {
	require(servicesFolder:WaitForChild("PlayerDataService")),
	require(servicesFolder:WaitForChild("CarService")),
	require(servicesFolder:WaitForChild("EarningService")),
	require(servicesFolder:WaitForChild("ShopService")),
	require(servicesFolder:WaitForChild("ZoneService")),
	require(servicesFolder:WaitForChild("RebirthService")),
}

local context = {
	ReplicatedStorage = ReplicatedStorage,
	ServerScriptService = ServerScriptService,
	Remotes = remotesFolder,
	Modules = modulesFolder,
}

for _, service in ipairs(orderedServices) do
	if service.Init then
		service.Init(context)
	end
end
for _, service in ipairs(orderedServices) do
	if service.Start then
		service.Start()
	end
end

print("[ServerMain] Startup complete")

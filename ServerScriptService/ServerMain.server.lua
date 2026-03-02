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
local serviceModuleNames = {
	"PlayerDataService",
	"CarService",
	"EarningService",
	"ShopService",
	"ZoneService",
	"RebirthService",
}

local serviceMap: {[string]: any} = {}
for _, moduleName in ipairs(serviceModuleNames) do
	serviceMap[moduleName] = require(servicesFolder:WaitForChild(moduleName))
end

local context = {
	ReplicatedStorage = ReplicatedStorage,
	ServerScriptService = ServerScriptService,
	Remotes = remotesFolder,
	Modules = modulesFolder,
	Services = serviceMap,
}

for _, moduleName in ipairs(serviceModuleNames) do
	local service = serviceMap[moduleName]
	if service.Init then
		service.Init(context)
	end
end

for _, moduleName in ipairs(serviceModuleNames) do
	local service = serviceMap[moduleName]
	if service.Start then
		service.Start()
	end
end

print("[ServerMain] Startup complete")

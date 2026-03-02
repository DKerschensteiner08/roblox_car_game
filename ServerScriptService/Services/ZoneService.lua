--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ZoneService = {}

local zoneConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("ZoneConfig"))
local remoteNames = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("RemoteNames"))

local zonesById: {[string]: {[string]: any}} = {}
local orderedZones = zoneConfig.Zones
local requestUnlockZone: RemoteFunction
local systemMessageRemote: RemoteEvent
local dataService: any
local carService: any

local function pointInAABB(point: Vector3, center: Vector3, size: Vector3): boolean
	local offset = point - center
	return math.abs(offset.X) <= size.X * 0.5
		and math.abs(offset.Y) <= size.Y * 0.5
		and math.abs(offset.Z) <= size.Z * 0.5
end

local function buildZoneParts()
	local folder = Workspace:FindFirstChild("ZoneVisuals")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ZoneVisuals"
		folder.Parent = Workspace
	end

	for _, zone in ipairs(orderedZones) do
		local base = folder:FindFirstChild(zone.Id .. "_Pad")
		if not base then
			base = Instance.new("Part")
			base.Name = zone.Id .. "_Pad"
			base.Anchored = true
			base.CanCollide = true
			base.Material = Enum.Material.Asphalt
			base.Color = Color3.fromRGB(50, 50, 50)
			base.Size = Vector3.new(zone.RegionSize.X, 4, zone.RegionSize.Z)
			base.Position = zone.RegionCenter - Vector3.new(0, zone.RegionSize.Y * 0.5 + 2, 0)
			base.Parent = folder
		end
	end

	for index = 2, #orderedZones do
		local prev = orderedZones[index - 1]
		local zone = orderedZones[index]
		local gate = folder:FindFirstChild("Gate_" .. zone.Id)
		if not gate then
			gate = Instance.new("Part")
			gate.Name = "Gate_" .. zone.Id
			gate.Anchored = true
			gate.CanCollide = true
			gate.Material = Enum.Material.Metal
			gate.Color = Color3.fromRGB(210, 60, 60)
			gate.Size = Vector3.new(8, 20, 90)
			local gateX = (prev.RegionCenter.X + zone.RegionCenter.X) * 0.5
			gate.Position = Vector3.new(gateX, 10, zone.RegionCenter.Z)
			gate.Parent = folder
		end
	end
end

local function getPreviousUnlockedZoneId(unlockedZones: {[string]: boolean}): string
	local result = orderedZones[1].Id
	for _, zone in ipairs(orderedZones) do
		if unlockedZones[zone.Id] then
			result = zone.Id
		else
			break
		end
	end
	return result
end

function ZoneService.GetZoneById(zoneId: string): {[string]: any}?
	return zonesById[zoneId]
end

function ZoneService.GetZoneForPosition(position: Vector3): {[string]: any}
	for _, zone in ipairs(orderedZones) do
		if pointInAABB(position, zone.RegionCenter, zone.RegionSize) then
			return zone
		end
	end
	return orderedZones[1]
end

function ZoneService.ResolveZoneForPlayer(player: Player, position: Vector3): (string, number, boolean)
	local zone = ZoneService.GetZoneForPosition(position)
	if dataService.IsZoneUnlocked(player, zone.Id) then
		return zone.Id, zone.Multiplier, true
	end
	return orderedZones[1].Id, orderedZones[1].Multiplier, false
end

function ZoneService.EnforceZoneAccess(player: Player): boolean
	local primary = carService.GetPlayerCarPrimaryPart(player)
	if not primary then
		return false
	end
	local zone = ZoneService.GetZoneForPosition(primary.Position)
	if dataService.IsZoneUnlocked(player, zone.Id) then
		return false
	end

	local fallbackId = getPreviousUnlockedZoneId(dataService.GetProfile(player).UnlockedZones)
	local fallbackZone = ZoneService.GetZoneById(fallbackId) or orderedZones[1]
	local targetPos = fallbackZone.RegionCenter + Vector3.new(0, 8, 0)
	local model = carService.GetPlayerCarModel(player)
	if model and model.PrimaryPart then
		local look = model.PrimaryPart.CFrame.LookVector
		model:PivotTo(CFrame.lookAt(targetPos, targetPos + Vector3.new(look.X, 0, look.Z)))
		model.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
		model.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
	end
	return true
end

function ZoneService.Init(context)
	for _, zone in ipairs(zoneConfig.Zones) do
		zonesById[zone.Id] = zone
	end
	requestUnlockZone = context.Remotes:WaitForChild(remoteNames.Functions.RequestUnlockZone) :: RemoteFunction
	systemMessageRemote = context.Remotes:WaitForChild(remoteNames.Events.SystemMessage) :: RemoteEvent
	dataService = context.Services.PlayerDataService
	carService = context.Services.CarService
	buildZoneParts()
	print("[ZoneService] Init")
end

function ZoneService.Start()
	requestUnlockZone.OnServerInvoke = function(player: Player, zoneId: string)
		if typeof(zoneId) ~= "string" then
			return false, "Invalid zone"
		end
		local zone = ZoneService.GetZoneById(zoneId)
		if not zone then
			return false, "Unknown zone"
		end
		if dataService.IsZoneUnlocked(player, zoneId) then
			return false, "Already unlocked"
		end

		if not dataService.SpendCash(player, zone.UnlockCost) then
			systemMessageRemote:FireClient(player, { Message = "Not enough cash for zone unlock" })
			dataService.PushDataSync(player)
			return false, "Insufficient cash"
		end

		dataService.UnlockZone(player, zoneId)
		dataService.PushDataSync(player)
		systemMessageRemote:FireClient(player, { Message = "Unlocked " .. zone.DisplayName })
		return true, "Zone unlocked"
	end

	print("[ZoneService] Start")
end

return ZoneService

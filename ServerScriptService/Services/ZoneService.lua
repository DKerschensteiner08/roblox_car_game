--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneService = {}

local zoneConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("ZoneConfig"))

local zonesById: {[string]: {[string]: any}} = {}

local function pointInAABB(point: Vector3, center: Vector3, size: Vector3): boolean
	local offset = point - center
	return math.abs(offset.X) <= size.X * 0.5
		and math.abs(offset.Y) <= size.Y * 0.5
		and math.abs(offset.Z) <= size.Z * 0.5
end

function ZoneService.Init(_context)
	for _, zone in ipairs(zoneConfig.Zones) do
		zonesById[zone.Id] = zone
	end
	print("[ZoneService] Init")
end

function ZoneService.Start()
	print("[ZoneService] Start")
end

function ZoneService.GetZoneById(zoneId: string): {[string]: any}?
	return zonesById[zoneId]
end

function ZoneService.GetZoneForPosition(position: Vector3): {[string]: any}
	for _, zone in ipairs(zoneConfig.Zones) do
		if pointInAABB(position, zone.RegionCenter, zone.RegionSize) then
			return zone
		end
	end
	return zoneConfig.Zones[1]
end

function ZoneService.GetZoneMultiplierForPlayer(player: Player, position: Vector3, unlockedZones: {[string]: boolean}): number
	local zone = ZoneService.GetZoneForPosition(position)
	if unlockedZones[zone.Id] then
		return zone.Multiplier
	end
	local starter = zoneConfig.Zones[1]
	return starter.Multiplier
end

return ZoneService

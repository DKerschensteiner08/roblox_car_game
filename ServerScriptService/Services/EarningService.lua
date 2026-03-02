--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EarningService = {}

local remoteNames = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("RemoteNames"))
local util = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Util"))

local dataService: any
local carService: any
local zoneService: any
local cashPopupRemote: RemoteEvent

local lastPositions: {[number]: Vector3} = {}
local tickAccumulator = 0

local TICK_RATE = 0.25
local BASE_RATE = 1.1
local MAX_DISTANCE_PER_TICK = 120

local function handleTick()
	for _, player in ipairs(Players:GetPlayers()) do
		local primary = carService.GetPlayerCarPrimaryPart(player)
		if not primary then
			lastPositions[player.UserId] = nil
			dataService.PushDataSync(player, {
				Speed = 0,
				ZoneMultiplier = 1,
			})
			continue
		end

		local currentPos = primary.Position
		local lastPos = lastPositions[player.UserId]
		lastPositions[player.UserId] = currentPos

		local speed = primary.AssemblyLinearVelocity.Magnitude
		if not lastPos then
			dataService.PushDataSync(player, {
				Speed = util.SafeFloor(speed),
				ZoneMultiplier = 1,
			})
			continue
		end

		local distance = (currentPos - lastPos).Magnitude
		if distance > MAX_DISTANCE_PER_TICK then
			dataService.PushDataSync(player, {
				Speed = util.SafeFloor(speed),
				ZoneMultiplier = 1,
				AntiCheat = "Distance spike ignored",
			})
			continue
		end

		local profile = dataService.GetProfile(player)
		local zoneMultiplier = zoneService.GetZoneMultiplierForPlayer(player, currentPos, profile.UnlockedZones)
		local upgradeMultiplier = dataService.GetUpgradeMultiplier(player)
		local rebirthMultiplier = dataService.GetRebirthMultiplier(player)

		local gain = math.floor(distance * BASE_RATE * zoneMultiplier * upgradeMultiplier * rebirthMultiplier)
		if gain > 0 then
			dataService.AddCash(player, gain)
			cashPopupRemote:FireClient(player, {
				Amount = gain,
				Position = currentPos,
			})
		end

		local activeZone = zoneService.GetZoneForPosition(currentPos)
		if profile.UnlockedZones[activeZone.Id] then
			profile.CurrentZoneId = activeZone.Id
		else
			profile.CurrentZoneId = "starter_zone"
		end

		dataService.PushDataSync(player, {
			Speed = util.SafeFloor(speed),
			ZoneMultiplier = zoneMultiplier,
			BaseRate = BASE_RATE,
		})
	end
end

function EarningService.Init(context)
	dataService = context.Services.PlayerDataService
	carService = context.Services.CarService
	zoneService = context.Services.ZoneService
	cashPopupRemote = context.Remotes:WaitForChild(remoteNames.Events.CashPopup) :: RemoteEvent
	print("[EarningService] Init")
end

function EarningService.Start()
	RunService.Heartbeat:Connect(function(dt)
		tickAccumulator += dt
		if tickAccumulator < TICK_RATE then
			return
		end
		tickAccumulator = 0
		handleTick()
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastPositions[player.UserId] = nil
	end)

	print("[EarningService] Start")
end

return EarningService

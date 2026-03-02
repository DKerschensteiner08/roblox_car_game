--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local PlayerDataService = {}

local remoteNames = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("RemoteNames"))
local upgradeConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("UpgradeConfig"))
local carConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("CarConfig"))
local zoneConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("ZoneConfig"))

local profiles: {[number]: {[string]: any}} = {}
local dataSyncRemote: RemoteEvent

local DATASTORE_NAME = "DriveToEarn_v1"
local AUTO_SAVE_INTERVAL = 120
local SAVE_RETRIES = 3

local profileStore: DataStore? = nil
local saveEnabled = true

local function makeDefaultProfile(): {[string]: any}
	return {
		Cash = 0,
		UpgradeLevel = 1,
		OwnedCars = { starter_hatch = true },
		EquippedCarId = "starter_hatch",
		UnlockedZones = { starter_zone = true },
		CurrentZoneId = "starter_zone",
		RebirthCount = 0,
	}
end

local function cloneFlags(source: {[string]: any}?): {[string]: boolean}
	local result: {[string]: boolean} = {}
	if source then
		for key, value in pairs(source) do
			if value == true then
				result[tostring(key)] = true
			end
		end
	end
	return result
end

local function sanitizeProfile(rawProfile: {[string]: any}?): {[string]: any}
	local profile = makeDefaultProfile()
	if not rawProfile then
		return profile
	end

	if typeof(rawProfile.Cash) == "number" then
		profile.Cash = math.max(0, math.floor(rawProfile.Cash))
	end
	if typeof(rawProfile.UpgradeLevel) == "number" then
		profile.UpgradeLevel = math.max(1, math.floor(rawProfile.UpgradeLevel))
	end
	if typeof(rawProfile.RebirthCount) == "number" then
		profile.RebirthCount = math.max(0, math.floor(rawProfile.RebirthCount))
	end

	profile.OwnedCars = cloneFlags(rawProfile.OwnedCars)
	profile.UnlockedZones = cloneFlags(rawProfile.UnlockedZones)

	profile.OwnedCars[carConfig.StarterCarId] = true
	profile.UnlockedZones[zoneConfig.Zones[1].Id] = true

	if typeof(rawProfile.EquippedCarId) == "string" and profile.OwnedCars[rawProfile.EquippedCarId] then
		profile.EquippedCarId = rawProfile.EquippedCarId
	end

	if typeof(rawProfile.CurrentZoneId) == "string" and profile.UnlockedZones[rawProfile.CurrentZoneId] then
		profile.CurrentZoneId = rawProfile.CurrentZoneId
	else
		profile.CurrentZoneId = zoneConfig.Zones[1].Id
	end

	return profile
end

local function getDataStoreKey(userId: number): string
	return "player_" .. tostring(userId)
end

local function getUpgradeTier(level: number)
	for _, tier in ipairs(upgradeConfig.Earnings) do
		if tier.Level == level then
			return tier
		end
	end
	return upgradeConfig.Earnings[1]
end

local function getNextUpgradeTier(level: number)
	for _, tier in ipairs(upgradeConfig.Earnings) do
		if tier.Level == level + 1 then
			return tier
		end
	end
	return nil
end

local function ensureLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local cashValue = leaderstats:FindFirstChild("Cash")
	if not cashValue then
		cashValue = Instance.new("IntValue")
		cashValue.Name = "Cash"
		cashValue.Parent = leaderstats
	end
end

local function syncLeaderstats(player: Player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end
	ensureLeaderstats(player)
	local leaderstats = player:FindFirstChild("leaderstats") :: Folder
	local cashValue = leaderstats:FindFirstChild("Cash") :: IntValue
	cashValue.Value = math.floor(profile.Cash)
end

local function saveProfile(userId: number, profile: {[string]: any}): boolean
	if not saveEnabled or profileStore == nil then
		return false
	end
	local key = getDataStoreKey(userId)
	for attempt = 1, SAVE_RETRIES do
		local ok, err = pcall(function()
			(profileStore :: DataStore):SetAsync(key, profile)
		end)
		if ok then
			return true
		end
		warn(string.format("[PlayerDataService] Save failed user=%d attempt=%d err=%s", userId, attempt, tostring(err)))
		task.wait(0.5 * attempt)
	end
	return false
end

local function loadProfile(userId: number): {[string]: any}
	if not saveEnabled or profileStore == nil then
		return makeDefaultProfile()
	end
	local key = getDataStoreKey(userId)
	for attempt = 1, SAVE_RETRIES do
		local ok, result = pcall(function()
			return (profileStore :: DataStore):GetAsync(key)
		end)
		if ok then
			return sanitizeProfile(result)
		end
		warn(string.format("[PlayerDataService] Load failed user=%d attempt=%d err=%s", userId, attempt, tostring(result)))
		task.wait(0.5 * attempt)
	end
	return makeDefaultProfile()
end

function PlayerDataService.GetRebirthCost(player: Player): number
	local profile = PlayerDataService.GetProfile(player)
	return 100000 * (profile.RebirthCount + 1)
end

function PlayerDataService.GetProfile(player: Player): {[string]: any}
	local profile = profiles[player.UserId]
	if not profile then
		profile = makeDefaultProfile()
		profiles[player.UserId] = profile
	end
	return profile
end

function PlayerDataService.GetCash(player: Player): number
	return PlayerDataService.GetProfile(player).Cash
end

function PlayerDataService.SetCash(player: Player, amount: number)
	local profile = PlayerDataService.GetProfile(player)
	profile.Cash = math.max(0, math.floor(amount))
	syncLeaderstats(player)
end

function PlayerDataService.AddCash(player: Player, amount: number)
	if amount <= 0 then
		return
	end
	local profile = PlayerDataService.GetProfile(player)
	profile.Cash = profile.Cash + math.floor(amount)
	syncLeaderstats(player)
end

function PlayerDataService.CanAfford(player: Player, amount: number): boolean
	return PlayerDataService.GetCash(player) >= math.floor(amount)
end

function PlayerDataService.SpendCash(player: Player, amount: number): boolean
	amount = math.floor(amount)
	if amount <= 0 then
		return true
	end
	if not PlayerDataService.CanAfford(player, amount) then
		return false
	end
	PlayerDataService.SetCash(player, PlayerDataService.GetCash(player) - amount)
	return true
end

function PlayerDataService.GetUpgradeLevel(player: Player): number
	return PlayerDataService.GetProfile(player).UpgradeLevel
end

function PlayerDataService.SetUpgradeLevel(player: Player, level: number)
	local profile = PlayerDataService.GetProfile(player)
	profile.UpgradeLevel = math.max(1, math.floor(level))
end

function PlayerDataService.GetUpgradeMultiplier(player: Player): number
	local profile = PlayerDataService.GetProfile(player)
	return getUpgradeTier(profile.UpgradeLevel).Multiplier
end

function PlayerDataService.GetNextUpgrade(player: Player)
	local profile = PlayerDataService.GetProfile(player)
	return getNextUpgradeTier(profile.UpgradeLevel)
end

function PlayerDataService.GetRebirthMultiplier(player: Player): number
	local profile = PlayerDataService.GetProfile(player)
	return 1 + (profile.RebirthCount * 0.2)
end

function PlayerDataService.OwnsCar(player: Player, carId: string): boolean
	local profile = PlayerDataService.GetProfile(player)
	return profile.OwnedCars[carId] == true
end

function PlayerDataService.AddOwnedCar(player: Player, carId: string)
	local profile = PlayerDataService.GetProfile(player)
	profile.OwnedCars[carId] = true
end

function PlayerDataService.GetEquippedCarId(player: Player): string
	local profile = PlayerDataService.GetProfile(player)
	if carConfig.Cars[profile.EquippedCarId] then
		return profile.EquippedCarId
	end
	return carConfig.StarterCarId
end

function PlayerDataService.SetEquippedCarId(player: Player, carId: string)
	local profile = PlayerDataService.GetProfile(player)
	if profile.OwnedCars[carId] and carConfig.Cars[carId] then
		profile.EquippedCarId = carId
	end
end

function PlayerDataService.IsZoneUnlocked(player: Player, zoneId: string): boolean
	local profile = PlayerDataService.GetProfile(player)
	return profile.UnlockedZones[zoneId] == true
end

function PlayerDataService.UnlockZone(player: Player, zoneId: string)
	local profile = PlayerDataService.GetProfile(player)
	profile.UnlockedZones[zoneId] = true
end

function PlayerDataService.ApplyRebirthReset(player: Player)
	local profile = PlayerDataService.GetProfile(player)
	profile.RebirthCount += 1
	profile.Cash = 0
	profile.UpgradeLevel = 1
	profile.OwnedCars = { starter_hatch = true }
	profile.EquippedCarId = "starter_hatch"
	profile.UnlockedZones = { starter_zone = true }
	profile.CurrentZoneId = "starter_zone"
	syncLeaderstats(player)
end

local function buildStringList(flags: {[string]: boolean}): {string}
	local ids = {}
	for id, owned in pairs(flags) do
		if owned then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

local function getNextLockedZoneInfo(unlockedZones: {[string]: boolean}): (string, number)
	for _, zone in ipairs(zoneConfig.Zones) do
		if not unlockedZones[zone.Id] then
			return zone.Id, zone.UnlockCost
		end
	end
	return "", 0
end

function PlayerDataService.PushDataSync(player: Player, extra: {[string]: any}?)
	local profile = PlayerDataService.GetProfile(player)
	local nextUpgrade = PlayerDataService.GetNextUpgrade(player)
	local nextZoneId, nextZoneCost = getNextLockedZoneInfo(profile.UnlockedZones)
	local payload = {
		Cash = profile.Cash,
		UpgradeLevel = profile.UpgradeLevel,
		UpgradeMultiplier = PlayerDataService.GetUpgradeMultiplier(player),
		CurrentZoneId = profile.CurrentZoneId,
		RebirthCount = profile.RebirthCount,
		RebirthMultiplier = PlayerDataService.GetRebirthMultiplier(player),
		RebirthCost = PlayerDataService.GetRebirthCost(player),
		NextUpgradeCost = if nextUpgrade then nextUpgrade.Cost else 0,
		NextUpgradeMultiplier = if nextUpgrade then nextUpgrade.Multiplier else PlayerDataService.GetUpgradeMultiplier(player),
		EquippedCarId = PlayerDataService.GetEquippedCarId(player),
		OwnedCars = buildStringList(profile.OwnedCars),
		UnlockedZones = buildStringList(profile.UnlockedZones),
		NextZoneId = nextZoneId,
		NextZoneCost = nextZoneCost,
	}
	if extra then
		for key, value in pairs(extra) do
			(payload :: any)[key] = value
		end
	end
	dataSyncRemote:FireClient(player, payload)
end

function PlayerDataService.SavePlayer(player: Player)
	local profile = profiles[player.UserId]
	if not profile then
		return
	end
	saveProfile(player.UserId, profile)
end

function PlayerDataService.Init(context)
	dataSyncRemote = context.Remotes:WaitForChild(remoteNames.Events.DataSync) :: RemoteEvent
	local ok, storeOrErr = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok then
		profileStore = storeOrErr
	else
		saveEnabled = false
		warn("[PlayerDataService] DataStore unavailable. Running unsaved session.", storeOrErr)
	end
	print("[PlayerDataService] Init")
end

function PlayerDataService.Start()
	Players.PlayerAdded:Connect(function(player)
		profiles[player.UserId] = loadProfile(player.UserId)
		syncLeaderstats(player)
		PlayerDataService.PushDataSync(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		profiles[player.UserId] = loadProfile(player.UserId)
		syncLeaderstats(player)
		PlayerDataService.PushDataSync(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.SavePlayer(player)
		profiles[player.UserId] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				PlayerDataService.SavePlayer(player)
			end
		end
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerDataService.SavePlayer(player)
		end
	end)

	print("[PlayerDataService] Start")
end

return PlayerDataService

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = {}

local remoteNames = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("RemoteNames"))
local upgradeConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("UpgradeConfig"))

local profiles: {[number]: {[string]: any}} = {}
local dataSyncRemote: RemoteEvent

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

local function getUpgradeMultiplier(level: number): number
	for _, tier in ipairs(upgradeConfig.Earnings) do
		if tier.Level == level then
			return tier.Multiplier
		end
	end
	return 1
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

function PlayerDataService.GetUpgradeMultiplier(player: Player): number
	local profile = PlayerDataService.GetProfile(player)
	return getUpgradeMultiplier(profile.UpgradeLevel)
end

function PlayerDataService.GetRebirthMultiplier(player: Player): number
	local profile = PlayerDataService.GetProfile(player)
	return 1 + (profile.RebirthCount * 0.2)
end

function PlayerDataService.PushDataSync(player: Player, extra: {[string]: any}?)
	local profile = PlayerDataService.GetProfile(player)
	local payload = {
		Cash = profile.Cash,
		UpgradeLevel = profile.UpgradeLevel,
		UpgradeMultiplier = PlayerDataService.GetUpgradeMultiplier(player),
		CurrentZoneId = profile.CurrentZoneId,
		RebirthCount = profile.RebirthCount,
		RebirthMultiplier = PlayerDataService.GetRebirthMultiplier(player),
	}
	if extra then
		for key, value in pairs(extra) do
			(payload :: any)[key] = value
		end
	end
	dataSyncRemote:FireClient(player, payload)
end

function PlayerDataService.Init(context)
	dataSyncRemote = context.Remotes:WaitForChild(remoteNames.Events.DataSync) :: RemoteEvent
	print("[PlayerDataService] Init")
end

function PlayerDataService.Start()
	Players.PlayerAdded:Connect(function(player)
		profiles[player.UserId] = makeDefaultProfile()
		syncLeaderstats(player)
		PlayerDataService.PushDataSync(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		profiles[player.UserId] = makeDefaultProfile()
		syncLeaderstats(player)
		PlayerDataService.PushDataSync(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		profiles[player.UserId] = nil
	end)
	print("[PlayerDataService] Start")
end

return PlayerDataService

--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopService = {}

local remoteNames = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("RemoteNames"))

local requestBuyUpgrade: RemoteFunction
local systemMessageRemote: RemoteEvent
local dataService: any

function ShopService.Init(context)
	requestBuyUpgrade = context.Remotes:WaitForChild(remoteNames.Functions.RequestBuyUpgrade) :: RemoteFunction
	systemMessageRemote = context.Remotes:WaitForChild(remoteNames.Events.SystemMessage) :: RemoteEvent
	dataService = context.Services.PlayerDataService
	print("[ShopService] Init")
end

local function sendMessage(player: Player, msg: string)
	systemMessageRemote:FireClient(player, {
		Message = msg,
	})
end

function ShopService.Start()
	requestBuyUpgrade.OnServerInvoke = function(player: Player)
		local nextUpgrade = dataService.GetNextUpgrade(player)
		if not nextUpgrade then
			sendMessage(player, "Max upgrade reached")
			dataService.PushDataSync(player)
			return false, "Max level"
		end

		local cost = math.floor(nextUpgrade.Cost)
		if not dataService.SpendCash(player, cost) then
			sendMessage(player, "Not enough cash for upgrade")
			dataService.PushDataSync(player)
			return false, "Insufficient cash"
		end

		local currentLevel = dataService.GetUpgradeLevel(player)
		dataService.SetUpgradeLevel(player, currentLevel + 1)
		dataService.PushDataSync(player)
		sendMessage(player, string.format("Upgrade purchased! Earnings x%.2f", nextUpgrade.Multiplier))
		return true, "Upgrade purchased"
	end

	print("[ShopService] Start")
end

return ShopService

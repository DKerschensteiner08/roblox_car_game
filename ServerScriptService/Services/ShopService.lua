--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopService = {}

local remoteNames = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("RemoteNames"))
local carConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("CarConfig"))

local requestBuyUpgrade: RemoteFunction
local requestBuyCar: RemoteFunction
local requestEquipCar: RemoteFunction
local systemMessageRemote: RemoteEvent
local dataService: any
local carService: any

function ShopService.Init(context)
	requestBuyUpgrade = context.Remotes:WaitForChild(remoteNames.Functions.RequestBuyUpgrade) :: RemoteFunction
	requestBuyCar = context.Remotes:WaitForChild(remoteNames.Functions.RequestBuyCar) :: RemoteFunction
	requestEquipCar = context.Remotes:WaitForChild(remoteNames.Functions.RequestEquipCar) :: RemoteFunction
	systemMessageRemote = context.Remotes:WaitForChild(remoteNames.Events.SystemMessage) :: RemoteEvent
	dataService = context.Services.PlayerDataService
	carService = context.Services.CarService
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

	requestBuyCar.OnServerInvoke = function(player: Player, carId: string)
		if typeof(carId) ~= "string" then
			return false, "Invalid car"
		end
		local carDef = carConfig.Cars[carId]
		if not carDef then
			return false, "Unknown car"
		end
		if dataService.OwnsCar(player, carId) then
			sendMessage(player, carDef.DisplayName .. " already owned")
			return false, "Already owned"
		end

		if not dataService.SpendCash(player, carDef.Cost) then
			sendMessage(player, "Not enough cash for car")
			dataService.PushDataSync(player)
			return false, "Insufficient cash"
		end

		dataService.AddOwnedCar(player, carId)
		dataService.SetEquippedCarId(player, carId)
		carService.SpawnCar(player, carId)
		dataService.PushDataSync(player)
		sendMessage(player, "Purchased and equipped " .. carDef.DisplayName)
		return true, "Car purchased"
	end

	requestEquipCar.OnServerInvoke = function(player: Player, carId: string)
		if typeof(carId) ~= "string" then
			return false, "Invalid car"
		end
		if not carConfig.Cars[carId] then
			return false, "Unknown car"
		end
		if not dataService.OwnsCar(player, carId) then
			sendMessage(player, "You do not own that car")
			return false, "Not owned"
		end

		dataService.SetEquippedCarId(player, carId)
		carService.SpawnCar(player, carId)
		dataService.PushDataSync(player)
		sendMessage(player, "Equipped " .. carConfig.Cars[carId].DisplayName)
		return true, "Car equipped"
	end

	print("[ShopService] Start")
end

return ShopService

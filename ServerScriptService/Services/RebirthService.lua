--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RebirthService = {}

local remoteNames = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("RemoteNames"))

local requestRebirth: RemoteFunction
local systemMessageRemote: RemoteEvent
local dataService: any
local carService: any

function RebirthService.Init(context)
	requestRebirth = context.Remotes:WaitForChild(remoteNames.Functions.RequestRebirth) :: RemoteFunction
	systemMessageRemote = context.Remotes:WaitForChild(remoteNames.Events.SystemMessage) :: RemoteEvent
	dataService = context.Services.PlayerDataService
	carService = context.Services.CarService
	print("[RebirthService] Init")
end

function RebirthService.Start()
	requestRebirth.OnServerInvoke = function(player: Player)
		local cost = dataService.GetRebirthCost(player)
		if not dataService.CanAfford(player, cost) then
			return false, "Not enough cash"
		end

		dataService.ApplyRebirthReset(player)
		carService.SpawnCar(player, "starter_hatch")
		dataService.PushDataSync(player)
		systemMessageRemote:FireClient(player, { Message = "Rebirth complete! Permanent earnings multiplier increased." })
		return true, "Rebirth complete"
	end

	print("[RebirthService] Start")
end

return RebirthService

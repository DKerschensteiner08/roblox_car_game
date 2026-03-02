--!strict

local Players = game:GetService("Players")

local PlayerDataService = {}

local profiles: {[number]: {[string]: any}} = {}

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

function PlayerDataService.Init(_context)
	print("[PlayerDataService] Init")
end

function PlayerDataService.Start()
	Players.PlayerAdded:Connect(function(player)
		profiles[player.UserId] = makeDefaultProfile()
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		profiles[player.UserId] = makeDefaultProfile()
	end

	Players.PlayerRemoving:Connect(function(player)
		profiles[player.UserId] = nil
	end)
	print("[PlayerDataService] Start")
end

function PlayerDataService.GetProfile(player: Player): {[string]: any}
	local profile = profiles[player.UserId]
	if not profile then
		profile = makeDefaultProfile()
		profiles[player.UserId] = profile
	end
	return profile
end

return PlayerDataService

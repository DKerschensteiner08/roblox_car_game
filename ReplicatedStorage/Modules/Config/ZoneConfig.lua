--!strict

local ZoneConfig = {
	Debug = true,
	Zones = {
		{
			Id = "starter_zone",
			DisplayName = "Starter Zone",
			UnlockCost = 0,
			Multiplier = 1.0,
			RegionCenter = Vector3.new(0, 5, 0),
			RegionSize = Vector3.new(600, 60, 600),
		},
	},
}

return ZoneConfig

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
			RegionSize = Vector3.new(700, 120, 700),
		},
		{
			Id = "coastal_zone",
			DisplayName = "Coastal Zone",
			UnlockCost = 5000,
			Multiplier = 1.8,
			RegionCenter = Vector3.new(850, 5, 0),
			RegionSize = Vector3.new(700, 120, 700),
		},
		{
			Id = "city_zone",
			DisplayName = "City Zone",
			UnlockCost = 25000,
			Multiplier = 3.0,
			RegionCenter = Vector3.new(1700, 5, 0),
			RegionSize = Vector3.new(700, 120, 700),
		},
	},
}

return ZoneConfig

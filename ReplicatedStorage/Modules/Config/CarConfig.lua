--!strict

local CarConfig = {
	Debug = true,
	StarterCarId = "starter_hatch",
	Cars = {
		starter_hatch = {
			Id = "starter_hatch",
			DisplayName = "Starter Hatch",
			Cost = 0,
			MaxSpeed = 85,
			Acceleration = 1.0,
		},
		desert_runner = {
			Id = "desert_runner",
			DisplayName = "Desert Runner",
			Cost = 6000,
			MaxSpeed = 105,
			Acceleration = 1.15,
		},
		street_gt = {
			Id = "street_gt",
			DisplayName = "Street GT",
			Cost = 22000,
			MaxSpeed = 130,
			Acceleration = 1.35,
		},
	},
}

return CarConfig

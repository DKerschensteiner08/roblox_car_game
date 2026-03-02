--!strict

local UpgradeConfig = {
	Debug = true,
	Earnings = {
		{ Level = 1, Cost = 0, Multiplier = 1.00 },
		{ Level = 2, Cost = 250, Multiplier = 1.15 },
		{ Level = 3, Cost = 800, Multiplier = 1.35 },
		{ Level = 4, Cost = 2000, Multiplier = 1.60 },
		{ Level = 5, Cost = 5000, Multiplier = 2.00 },
	},
}

return UpgradeConfig

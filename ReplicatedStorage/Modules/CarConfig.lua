--!strict
-- Shared car tuning for Ticket 2 prototype.
-- Server uses these values as the source of truth for movement forces.

local CarConfig = {
	Drive = {
		ForwardAccel = 60, -- studs/s^2
		ReverseAccel = 35, -- studs/s^2
		RollingDrag = 2.5, -- per-second speed damping along forward axis
		LateralGrip = 10, -- per-second speed damping along side axis
	},

	Steering = {
		MaxTurnRateDeg = 90, -- max yaw rate in degrees/second
		SpeedForFullSteer = 45, -- studs/s where steering reaches full response
	},

	Stability = {
		RollPitchDamping = 0.9, -- angular damping applied each frame on X/Z axes
	},

	Respawn = {
		SpawnHeightOffset = 4,
		ResetCooldownSeconds = 1.25,
		RespawnCooldownSeconds = 1.0,
	},

	Camera = {
		Distance = 15,
		Height = 6,
		LookAhead = 12,
		VelocityLead = 0.08,
		Smoothness = 9,
		BaseFov = 75,
		MaxFovBoost = 8,
		FovPerSpeed = 0.18,
	},
}

return CarConfig

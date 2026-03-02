--!strict
-- Follow-camera scaffold for Ticket 2.

local RunService = game:GetService("RunService")

RunService:BindToRenderStep("CarFollowCamera", Enum.RenderPriority.Camera.Value, function(_dt)
	-- TODO(Ticket 2): Track player's vehicle and apply smooth follow camera transform.
end)

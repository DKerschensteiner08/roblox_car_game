--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local smoothPos: Vector3? = nil
local smoothFocus: Vector3? = nil

local function getOwnedCarPrimaryPart(): BasePart?
	local carsFolder = Workspace:FindFirstChild("Cars")
	if not carsFolder then
		return nil
	end
	for _, item in ipairs(carsFolder:GetChildren()) do
		if item:IsA("Model") and item:GetAttribute("OwnerUserId") == localPlayer.UserId then
			if item.PrimaryPart then
				return item.PrimaryPart
			end
		end
	end
	return nil
end

local function alpha(dt: number): number
	return 1 - math.exp(-8 * dt)
end

RunService:BindToRenderStep("DriveCam", Enum.RenderPriority.Camera.Value, function(dt)
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end

	local primary = getOwnedCarPrimaryPart()
	if not primary then
		cam.CameraType = Enum.CameraType.Custom
		smoothPos = nil
		smoothFocus = nil
		return
	end

	cam.CameraType = Enum.CameraType.Scriptable
	local vel = primary.AssemblyLinearVelocity
	local look = primary.CFrame.LookVector
	local desiredFocus = primary.Position + look * 10
	local desiredPos = primary.Position - look * 14 + Vector3.new(0, 6, 0) + vel * 0.05

	local a = alpha(dt)
	smoothPos = if smoothPos then smoothPos:Lerp(desiredPos, a) else desiredPos
	smoothFocus = if smoothFocus then smoothFocus:Lerp(desiredFocus, a) else desiredFocus

	cam.CFrame = CFrame.lookAt(smoothPos :: Vector3, smoothFocus :: Vector3)
	cam.FieldOfView = 75 + math.clamp(vel.Magnitude * 0.1, 0, 10)
end)

print("[CameraController] Ready")

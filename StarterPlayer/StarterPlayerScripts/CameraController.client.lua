--!strict
-- Ticket 2 follow camera for the local player's spawned car.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local carConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CarConfig"))

local smoothedPosition: Vector3? = nil
local smoothedFocus: Vector3? = nil
local usingScriptable = false

local function getOwnedCarChassis(): BasePart?
	local carsFolder = Workspace:FindFirstChild("Cars")
	if not carsFolder then
		return nil
	end

	for _, item in ipairs(carsFolder:GetChildren()) do
		if not item:IsA("Model") then
			continue
		end

		if item:GetAttribute("OwnerUserId") ~= localPlayer.UserId then
			continue
		end

		local chassis = item:FindFirstChild("Chassis")
		if chassis and chassis:IsA("BasePart") then
			return chassis
		end
	end

	return nil
end

local function exponentialAlpha(smoothness: number, dt: number): number
	return 1 - math.exp(-smoothness * dt)
end

RunService:BindToRenderStep("CarFollowCamera", Enum.RenderPriority.Camera.Value, function(dt)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local chassis = getOwnedCarChassis()
	if not chassis then
		if usingScriptable then
			usingScriptable = false
			camera.CameraType = Enum.CameraType.Custom
			smoothedPosition = nil
			smoothedFocus = nil
			camera.FieldOfView = carConfig.Camera.BaseFov
		end
		return
	end

	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
		usingScriptable = true
	end

	local velocity = chassis.AssemblyLinearVelocity
	local speed = velocity.Magnitude
	local look = chassis.CFrame.LookVector

	local desiredFocus = chassis.Position + look * carConfig.Camera.LookAhead
	local desiredPosition =
		chassis.Position
		- look * carConfig.Camera.Distance
		+ Vector3.new(0, carConfig.Camera.Height, 0)
		+ velocity * carConfig.Camera.VelocityLead

	local alpha = exponentialAlpha(carConfig.Camera.Smoothness, dt)
	if smoothedPosition == nil then
		smoothedPosition = desiredPosition
	else
		smoothedPosition = smoothedPosition:Lerp(desiredPosition, alpha)
	end

	if smoothedFocus == nil then
		smoothedFocus = desiredFocus
	else
		smoothedFocus = smoothedFocus:Lerp(desiredFocus, alpha)
	end

	camera.FieldOfView = carConfig.Camera.BaseFov
		+ math.clamp(speed * carConfig.Camera.FovPerSpeed, 0, carConfig.Camera.MaxFovBoost)
	camera.CFrame = CFrame.lookAt(smoothedPosition :: Vector3, smoothedFocus :: Vector3, Vector3.new(0, 1, 0))
end)

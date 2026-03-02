--!strict
-- Ticket 2: server-authoritative spawn/reset and arcade driving for one car per player.
-- Client provides seat inputs through VehicleSeat; server applies forces.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("RemoteNames"))
local CarConfig = require(modulesFolder:WaitForChild("CarConfig"))

type CarState = {
	model: Model,
	chassis: BasePart,
	seat: VehicleSeat,
	driveForce: VectorForce,
	turnRate: AngularVelocity,
}

local carByPlayer: {[number]: CarState} = {}
local lastResetByPlayer: {[number]: number} = {}
local lastRespawnByPlayer: {[number]: number} = {}

local carsFolder = Workspace:FindFirstChild("Cars")
if not carsFolder then
	carsFolder = Instance.new("Folder")
	carsFolder.Name = "Cars"
	carsFolder.Parent = Workspace
end

local carResetRemote = remotesFolder:WaitForChild(RemoteNames.CarResetRequest) :: RemoteEvent
local carSpawnRemote = remotesFolder:WaitForChild(RemoteNames.CarSpawnRequest) :: RemoteEvent

local function getSpawnCFrame(player: Player): CFrame
	local explicitSpawn = Workspace:FindFirstChild("CarSpawn")
	if explicitSpawn and explicitSpawn:IsA("BasePart") then
		return explicitSpawn.CFrame + Vector3.new(0, CarConfig.Respawn.SpawnHeightOffset, 0)
	end

	local character = player.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local base = root.CFrame
			return base + base.LookVector * 12 + Vector3.new(0, CarConfig.Respawn.SpawnHeightOffset, 0)
		end
	end

	return CFrame.new(0, 12, 0)
end

local function createWheel(name: string, position: Vector3, parent: Instance, chassis: BasePart)
	local wheel = Instance.new("Part")
	wheel.Name = name
	wheel.Shape = Enum.PartType.Ball
	wheel.Size = Vector3.new(2.4, 2.4, 2.4)
	wheel.Material = Enum.Material.SmoothPlastic
	wheel.Color = Color3.fromRGB(20, 20, 20)
	wheel.CanCollide = false
	wheel.Massless = true
	wheel.CFrame = CFrame.new(position)
	wheel.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = chassis
	weld.Part1 = wheel
	weld.Parent = wheel
end

local function seatPlayer(player: Player, seat: VehicleSeat)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		seat:Sit(humanoid)
	end
end

local function buildCar(player: Player, spawnCFrame: CFrame): CarState
	local model = Instance.new("Model")
	model.Name = string.format("%s_Car", player.Name)
	model:SetAttribute("OwnerUserId", player.UserId)

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(6, 1.4, 8)
	chassis.Material = Enum.Material.Metal
	chassis.Color = Color3.fromRGB(220, 40, 40)
	chassis.TopSurface = Enum.SurfaceType.Smooth
	chassis.BottomSurface = Enum.SurfaceType.Smooth
	chassis.CFrame = spawnCFrame
	chassis.Parent = model

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2.5, 1.2, 2.5)
	seat.TopSurface = Enum.SurfaceType.Smooth
	seat.BottomSurface = Enum.SurfaceType.Smooth
	seat.Material = Enum.Material.Metal
	seat.Color = Color3.fromRGB(35, 35, 35)
	seat.CFrame = spawnCFrame * CFrame.new(0, 1.3, 0)
	seat.Parent = model

	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = chassis
	seatWeld.Part1 = seat
	seatWeld.Parent = seat

	local offsets = {
		Vector3.new(-2.6, -1.2, -2.8),
		Vector3.new(2.6, -1.2, -2.8),
		Vector3.new(-2.6, -1.2, 2.8),
		Vector3.new(2.6, -1.2, 2.8),
	}
	for index, offset in ipairs(offsets) do
		createWheel(("Wheel%d"):format(index), (spawnCFrame * CFrame.new(offset)).Position, model, chassis)
	end

	local driveAttachment = Instance.new("Attachment")
	driveAttachment.Name = "DriveAttachment"
	driveAttachment.Parent = chassis

	local driveForce = Instance.new("VectorForce")
	driveForce.Name = "DriveForce"
	driveForce.Attachment0 = driveAttachment
	driveForce.ApplyAtCenterOfMass = true
	driveForce.RelativeTo = Enum.ActuatorRelativeTo.World
	driveForce.Parent = chassis

	local turnRate = Instance.new("AngularVelocity")
	turnRate.Name = "TurnRate"
	turnRate.Attachment0 = driveAttachment
	turnRate.RelativeTo = Enum.ActuatorRelativeTo.World
	turnRate.MaxTorque = math.huge
	turnRate.Parent = chassis

	model.PrimaryPart = chassis
	model.Parent = carsFolder

	pcall(function()
		chassis:SetNetworkOwner(player)
	end)

	seatPlayer(player, seat)

	return {
		model = model,
		chassis = chassis,
		seat = seat,
		driveForce = driveForce,
		turnRate = turnRate,
	}
end

local function clearCarForPlayer(player: Player)
	local existing = carByPlayer[player.UserId]
	if existing then
		existing.model:Destroy()
		carByPlayer[player.UserId] = nil
	end
end

local function spawnCarForPlayer(player: Player)
	clearCarForPlayer(player)
	carByPlayer[player.UserId] = buildCar(player, getSpawnCFrame(player))
end

local function canUseCooldown(tableRef: {[number]: number}, userId: number, duration: number): boolean
	local now = os.clock()
	local lastUse = tableRef[userId] or 0
	if now - lastUse < duration then
		return false
	end
	tableRef[userId] = now
	return true
end

local function resetCar(player: Player)
	local state = carByPlayer[player.UserId]
	if not state then
		return
	end

	local chassis = state.chassis
	local pos = chassis.Position + Vector3.new(0, CarConfig.Respawn.SpawnHeightOffset, 0)
	local forward = chassis.CFrame.LookVector
	local flatForward = Vector3.new(forward.X, 0, forward.Z)
	if flatForward.Magnitude < 0.01 then
		flatForward = Vector3.new(0, 0, -1)
	end
	flatForward = flatForward.Unit

	state.model:PivotTo(CFrame.lookAt(pos, pos + flatForward, Vector3.new(0, 1, 0)))
	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero
end

carSpawnRemote.OnServerEvent:Connect(function(player: Player)
	if not canUseCooldown(lastRespawnByPlayer, player.UserId, CarConfig.Respawn.RespawnCooldownSeconds) then
		return
	end
	spawnCarForPlayer(player)
end)

carResetRemote.OnServerEvent:Connect(function(player: Player)
	if not canUseCooldown(lastResetByPlayer, player.UserId, CarConfig.Respawn.ResetCooldownSeconds) then
		return
	end
	resetCar(player)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.delay(0.25, function()
			if player.Parent == Players then
				spawnCarForPlayer(player)
			end
		end)
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		task.delay(0.25, function()
			if player.Parent == Players then
				spawnCarForPlayer(player)
			end
		end)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	clearCarForPlayer(player)
	lastResetByPlayer[player.UserId] = nil
	lastRespawnByPlayer[player.UserId] = nil
end)

RunService.Heartbeat:Connect(function()
	for _, state in pairs(carByPlayer) do
		if state.model.Parent == nil then
			continue
		end

		local chassis = state.chassis
		local seat = state.seat

		local velocity = chassis.AssemblyLinearVelocity
		local look = chassis.CFrame.LookVector
		local right = chassis.CFrame.RightVector
		local forwardSpeed = velocity:Dot(look)
		local lateralSpeed = velocity:Dot(right)

		local throttle = seat.ThrottleFloat
		local steer = seat.SteerFloat

		local accelLimit = if throttle >= 0 then CarConfig.Drive.ForwardAccel else CarConfig.Drive.ReverseAccel
		local driveAccel = throttle * accelLimit
		local dragAccel = -forwardSpeed * CarConfig.Drive.RollingDrag
		local lateralAccel = -lateralSpeed * CarConfig.Drive.LateralGrip

		local netAccel = look * (driveAccel + dragAccel) + right * lateralAccel
		state.driveForce.Force = netAccel * chassis.AssemblyMass

		local speedFactor = math.clamp(math.abs(forwardSpeed) / CarConfig.Steering.SpeedForFullSteer, 0, 1)
		local direction = if forwardSpeed >= 0 then 1 else -1
		local maxTurnRateRad = math.rad(CarConfig.Steering.MaxTurnRateDeg)
		state.turnRate.AngularVelocity = Vector3.new(0, steer * maxTurnRateRad * speedFactor * direction, 0)

		local angular = chassis.AssemblyAngularVelocity
		chassis.AssemblyAngularVelocity = Vector3.new(
			angular.X * CarConfig.Stability.RollPitchDamping,
			angular.Y,
			angular.Z * CarConfig.Stability.RollPitchDamping
		)
	end
end)

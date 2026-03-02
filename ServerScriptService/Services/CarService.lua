--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarService = {}

local carConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("CarConfig"))
local remoteNames = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("RemoteNames"))

local dataService: any
local remotesFolder: Folder
local requestSpawnCar: RemoteFunction
local requestResetCar: RemoteFunction

local carsFolder: Folder
local carsByUserId: {[number]: Model} = {}

local function ensureCarsFolder(): Folder
	local existing = Workspace:FindFirstChild("Cars")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Cars"
	folder.Parent = Workspace
	return folder
end

local function ensureSpawnPart(): BasePart
	local existing = Workspace:FindFirstChild("CarSpawn")
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local part = Instance.new("Part")
	part.Name = "CarSpawn"
	part.Anchored = true
	part.CanCollide = true
	part.Transparency = 1
	part.Size = Vector3.new(20, 1, 20)
	part.CFrame = CFrame.new(0, 6, 0)
	part.Parent = Workspace
	return part
end

local function createWheel(parent: Model, chassis: BasePart, cf: CFrame, name: string)
	local wheel = Instance.new("Part")
	wheel.Name = name
	wheel.Shape = Enum.PartType.Ball
	wheel.Size = Vector3.new(2.2, 2.2, 2.2)
	wheel.Material = Enum.Material.SmoothPlastic
	wheel.Color = Color3.fromRGB(30, 30, 30)
	wheel.CanCollide = false
	wheel.Massless = true
	wheel.CFrame = cf
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

local function buildCarModel(player: Player, carId: string): Model
	local carDef = carConfig.Cars[carId] or carConfig.Cars[carConfig.StarterCarId]
	local spawnPart = ensureSpawnPart()
	local model = Instance.new("Model")
	model.Name = player.Name .. "_Car"
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("CarId", carId)

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(6, 1.4, 9)
	chassis.Material = Enum.Material.Metal
	chassis.Color = Color3.fromRGB(200, 60, 60)
	chassis.CFrame = spawnPart.CFrame + Vector3.new(0, 4, 0)
	chassis.Parent = model

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2.6, 1.2, 2.6)
	seat.CFrame = chassis.CFrame * CFrame.new(0, 1.5, 0)
	seat.MaxSpeed = carDef.MaxSpeed
	seat.Torque = 20000 * carDef.Acceleration
	seat.TurnSpeed = 2
	seat.Parent = model

	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = chassis
	seatWeld.Part1 = seat
	seatWeld.Parent = seat

	createWheel(model, chassis, chassis.CFrame * CFrame.new(-2.5, -1.1, -3.2), "WheelFL")
	createWheel(model, chassis, chassis.CFrame * CFrame.new(2.5, -1.1, -3.2), "WheelFR")
	createWheel(model, chassis, chassis.CFrame * CFrame.new(-2.5, -1.1, 3.2), "WheelRL")
	createWheel(model, chassis, chassis.CFrame * CFrame.new(2.5, -1.1, 3.2), "WheelRR")

	model.PrimaryPart = chassis
	model.Parent = carsFolder

	pcall(function()
		chassis:SetNetworkOwner(player)
	end)

	task.delay(0.1, function()
		seatPlayer(player, seat)
	end)

	return model
end

local function clearPlayerCar(player: Player)
	local existing = carsByUserId[player.UserId]
	if existing then
		existing:Destroy()
		carsByUserId[player.UserId] = nil
	end
end

function CarService.SpawnCar(player: Player, carId: string?): Model
	clearPlayerCar(player)
	local selectedId = carId or dataService.GetEquippedCarId(player)
	local model = buildCarModel(player, selectedId)
	carsByUserId[player.UserId] = model
	return model
end

function CarService.ResetCar(player: Player): boolean
	local model = carsByUserId[player.UserId]
	if not model or not model.PrimaryPart then
		return false
	end
	local primary = model.PrimaryPart
	local currentPos = primary.Position + Vector3.new(0, 4, 0)
	local look = primary.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	flat = flat.Unit
	model:PivotTo(CFrame.lookAt(currentPos, currentPos + flat, Vector3.new(0, 1, 0)))
	primary.AssemblyLinearVelocity = Vector3.zero
	primary.AssemblyAngularVelocity = Vector3.zero
	return true
end

function CarService.GetPlayerCarModel(player: Player): Model?
	return carsByUserId[player.UserId]
end

function CarService.GetPlayerCarPrimaryPart(player: Player): BasePart?
	local model = carsByUserId[player.UserId]
	if model and model.PrimaryPart then
		return model.PrimaryPart
	end
	return nil
end

function CarService.Init(context)
	dataService = context.Services.PlayerDataService
	remotesFolder = context.Remotes
	requestSpawnCar = remotesFolder:WaitForChild(remoteNames.Functions.RequestSpawnCar) :: RemoteFunction
	requestResetCar = remotesFolder:WaitForChild(remoteNames.Functions.RequestResetCar) :: RemoteFunction
	carsFolder = ensureCarsFolder()
	ensureSpawnPart()
	print("[CarService] Init")
end

function CarService.Start()
	requestSpawnCar.OnServerInvoke = function(player: Player)
		CarService.SpawnCar(player)
		return true, "Spawned"
	end

	requestResetCar.OnServerInvoke = function(player: Player)
		local ok = CarService.ResetCar(player)
		return ok, if ok then "Reset" else "No car"
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.delay(0.35, function()
				if player.Parent == Players then
					CarService.SpawnCar(player)
				end
			end)
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.delay(0.35, function()
			if player.Parent == Players then
				CarService.SpawnCar(player)
			end
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		clearPlayerCar(player)
	end)

	print("[CarService] Start")
end

return CarService

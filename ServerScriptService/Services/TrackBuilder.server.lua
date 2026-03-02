--!strict
-- Builds a minimal playable race map if key structures are missing.
-- Safe to keep enabled: existing parts are reused and not overwritten.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local RaceConfig = require(modulesFolder:WaitForChild("RaceConfig"))

local function ensurePart(name: string, parent: Instance, props: {[string]: any}): BasePart
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		return existing
	end

	local part = Instance.new("Part")
	part.Name = name
	part.Parent = parent

	for key, value in pairs(props) do
		(part :: any)[key] = value
	end

	return part
end

local function ensureFolder(name: string, parent: Instance): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local mapFolder = ensureFolder("Map", Workspace)
local trackFolder = ensureFolder("Track", mapFolder)

local startPos = RaceConfig.Checkpoints.StartPosition
local spacing = RaceConfig.Checkpoints.CheckpointSpacing
local checkpointCount = RaceConfig.Checkpoints.DefaultCount
local trackLength = spacing * (checkpointCount + 1)
local trackMidX = startPos.X + trackLength * 0.5

ensurePart("Ground", trackFolder, {
	Anchored = true,
	CanCollide = true,
	Material = Enum.Material.Asphalt,
	Color = Color3.fromRGB(58, 58, 58),
	Size = Vector3.new(trackLength + 220, 6, 220),
	Position = Vector3.new(trackMidX, startPos.Y - 7, startPos.Z),
})

ensurePart("Road", trackFolder, {
	Anchored = true,
	CanCollide = true,
	Material = Enum.Material.Slate,
	Color = Color3.fromRGB(35, 35, 35),
	Size = Vector3.new(trackLength + 40, 1, 60),
	Position = Vector3.new(trackMidX, startPos.Y - 3.5, startPos.Z),
})

local barrierHeight = 8
local barrierY = startPos.Y + barrierHeight * 0.5 - 3
local barrierZOffset = 34
local barrierLength = trackLength + 40
ensurePart("BarrierLeft", trackFolder, {
	Anchored = true,
	CanCollide = true,
	Material = Enum.Material.Metal,
	Color = Color3.fromRGB(200, 40, 40),
	Size = Vector3.new(barrierLength, barrierHeight, 2),
	Position = Vector3.new(trackMidX, barrierY, startPos.Z - barrierZOffset),
})
ensurePart("BarrierRight", trackFolder, {
	Anchored = true,
	CanCollide = true,
	Material = Enum.Material.Metal,
	Color = Color3.fromRGB(200, 40, 40),
	Size = Vector3.new(barrierLength, barrierHeight, 2),
	Position = Vector3.new(trackMidX, barrierY, startPos.Z + barrierZOffset),
})

local spawn = ensurePart("CarSpawn", Workspace, {
	Anchored = true,
	CanCollide = true,
	Transparency = 1,
	Size = Vector3.new(20, 1, 20),
})
spawn.CFrame = CFrame.lookAt(
	Vector3.new(startPos.X - 30, startPos.Y - 3, startPos.Z),
	Vector3.new(startPos.X + 70, startPos.Y - 3, startPos.Z)
)

local checkpointsFolder = ensureFolder(RaceConfig.Checkpoints.FolderName, Workspace)
for index = 1, checkpointCount do
	local checkpointName = ("CP%d"):format(index)
	ensurePart(checkpointName, checkpointsFolder, {
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Transparency = 0.45,
		Color = Color3.fromRGB(0, 170, 255),
		Size = Vector3.new(12, 10, 56),
		Position = startPos + Vector3.new(spacing * index, 2, 0),
	})
end

ensurePart(RaceConfig.Checkpoints.FinishLineName, Workspace, {
	Anchored = true,
	CanCollide = false,
	Material = Enum.Material.Neon,
	Transparency = 0.25,
	Color = Color3.fromRGB(255, 255, 255),
	Size = Vector3.new(10, 10, 56),
	Position = startPos + Vector3.new(0, 2, 0),
})

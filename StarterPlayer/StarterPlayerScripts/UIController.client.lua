--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("Shared"):WaitForChild("RemoteNames"))

local dataSyncRemote = remotesFolder:WaitForChild(RemoteNames.Events.DataSync) :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "HUD"
frame.Size = UDim2.fromOffset(300, 170)
frame.Position = UDim2.fromOffset(18, 18)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.2
frame.Parent = screenGui

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.FillDirection = Enum.FillDirection.Vertical
list.Parent = frame

local function makeLabel(name: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -12, 0, 26)
	label.Position = UDim2.fromOffset(6, 0)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.Text = name .. ": --"
	label.Parent = frame
	return label
end

local cashLabel = makeLabel("Cash")
local multLabel = makeLabel("Multiplier")
local zoneLabel = makeLabel("Zone")
local speedLabel = makeLabel("Speed")
local msgLabel = makeLabel("Message")
msgLabel.TextColor3 = Color3.fromRGB(255, 210, 110)

local function toNumber(value: any, fallback: number): number
	if typeof(value) == "number" then
		return value
	end
	return fallback
end

dataSyncRemote.OnClientEvent:Connect(function(payload)
	local cash = math.floor(toNumber(payload.Cash, 0))
	local zoneMult = toNumber(payload.ZoneMultiplier, 1)
	local upMult = toNumber(payload.UpgradeMultiplier, 1)
	local rebirthMult = toNumber(payload.RebirthMultiplier, 1)
	local speed = math.floor(toNumber(payload.Speed, 0))
	local zoneId = tostring(payload.CurrentZoneId or "starter_zone")

	cashLabel.Text = string.format("Cash: $%d", cash)
	multLabel.Text = string.format("Multiplier: x%.2f (Zone x%.2f * Up x%.2f * Reb x%.2f)", zoneMult * upMult * rebirthMult, zoneMult, upMult, rebirthMult)
	zoneLabel.Text = string.format("Zone: %s", zoneId)
	speedLabel.Text = string.format("Speed: %d", speed)
	if payload.AntiCheat then
		msgLabel.Text = "Message: " .. tostring(payload.AntiCheat)
	else
		msgLabel.Text = "Message: Driving earns cash"
	end
end)

print("[UIController] Ready")

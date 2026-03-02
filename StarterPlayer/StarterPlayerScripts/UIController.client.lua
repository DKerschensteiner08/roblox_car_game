--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("Shared"):WaitForChild("RemoteNames"))

local dataSyncRemote = remotesFolder:WaitForChild(RemoteNames.Events.DataSync) :: RemoteEvent
local systemMessageRemote = remotesFolder:WaitForChild(RemoteNames.Events.SystemMessage) :: RemoteEvent
local requestBuyUpgrade = remotesFolder:WaitForChild(RemoteNames.Functions.RequestBuyUpgrade) :: RemoteFunction

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "HUD"
frame.Size = UDim2.fromOffset(420, 260)
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
local upgradeLabel = makeLabel("Upgrade")
local msgLabel = makeLabel("Message")
msgLabel.TextColor3 = Color3.fromRGB(255, 210, 110)

local buyUpgradeButton = Instance.new("TextButton")
buyUpgradeButton.Name = "BuyUpgrade"
buyUpgradeButton.Size = UDim2.new(1, -12, 0, 34)
buyUpgradeButton.Position = UDim2.fromOffset(6, 0)
buyUpgradeButton.BackgroundColor3 = Color3.fromRGB(55, 120, 55)
buyUpgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
buyUpgradeButton.Font = Enum.Font.GothamBold
buyUpgradeButton.TextSize = 18
buyUpgradeButton.Text = "Buy Earnings Upgrade"
buyUpgradeButton.Parent = frame

local cachedNextCost = 0

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
	local upgradeLevel = math.floor(toNumber(payload.UpgradeLevel, 1))
	cachedNextCost = math.floor(toNumber(payload.NextUpgradeCost, 0))
	local nextUpgradeMult = toNumber(payload.NextUpgradeMultiplier, upMult)

	cashLabel.Text = string.format("Cash: $%d", cash)
	multLabel.Text = string.format("Multiplier: x%.2f (Zone x%.2f * Up x%.2f * Reb x%.2f)", zoneMult * upMult * rebirthMult, zoneMult, upMult, rebirthMult)
	zoneLabel.Text = string.format("Zone: %s", zoneId)
	speedLabel.Text = string.format("Speed: %d", speed)
	if cachedNextCost > 0 then
		upgradeLabel.Text = string.format("Upgrade L%d -> L%d: $%d (x%.2f)", upgradeLevel, upgradeLevel + 1, cachedNextCost, nextUpgradeMult)
		buyUpgradeButton.Text = string.format("Buy Upgrade ($%d)", cachedNextCost)
		buyUpgradeButton.BackgroundColor3 = Color3.fromRGB(55, 120, 55)
	else
		upgradeLabel.Text = string.format("Upgrade: MAX (x%.2f)", upMult)
		buyUpgradeButton.Text = "Max Upgrade Reached"
		buyUpgradeButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	end
	if payload.AntiCheat then
		msgLabel.Text = "Message: " .. tostring(payload.AntiCheat)
	end
end)

systemMessageRemote.OnClientEvent:Connect(function(payload)
	msgLabel.Text = "Message: " .. tostring(payload.Message or "")
end)

buyUpgradeButton.Activated:Connect(function()
	if cachedNextCost <= 0 then
		return
	end
	local ok, msg = requestBuyUpgrade:InvokeServer()
	if not ok then
		msgLabel.Text = "Message: " .. tostring(msg)
	end
end)

print("[UIController] Ready")

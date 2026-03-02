--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("Shared"):WaitForChild("RemoteNames"))
local CarConfig = require(modulesFolder:WaitForChild("Config"):WaitForChild("CarConfig"))

local dataSyncRemote = remotesFolder:WaitForChild(RemoteNames.Events.DataSync) :: RemoteEvent
local systemMessageRemote = remotesFolder:WaitForChild(RemoteNames.Events.SystemMessage) :: RemoteEvent
local requestBuyUpgrade = remotesFolder:WaitForChild(RemoteNames.Functions.RequestBuyUpgrade) :: RemoteFunction
local requestBuyCar = remotesFolder:WaitForChild(RemoteNames.Functions.RequestBuyCar) :: RemoteFunction
local requestEquipCar = remotesFolder:WaitForChild(RemoteNames.Functions.RequestEquipCar) :: RemoteFunction
local requestUnlockZone = remotesFolder:WaitForChild(RemoteNames.Functions.RequestUnlockZone) :: RemoteFunction

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "HUD"
frame.Size = UDim2.fromOffset(450, 440)
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
local equippedLabel = makeLabel("Equipped Car")
local zoneUnlockLabel = makeLabel("Zone Unlock")
local msgLabel = makeLabel("Message")
msgLabel.TextColor3 = Color3.fromRGB(255, 210, 110)

local buyUpgradeButton = Instance.new("TextButton")
buyUpgradeButton.Size = UDim2.new(1, -12, 0, 34)
buyUpgradeButton.Position = UDim2.fromOffset(6, 0)
buyUpgradeButton.BackgroundColor3 = Color3.fromRGB(55, 120, 55)
buyUpgradeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
buyUpgradeButton.Font = Enum.Font.GothamBold
buyUpgradeButton.TextSize = 18
buyUpgradeButton.Text = "Buy Earnings Upgrade"
buyUpgradeButton.Parent = frame

local unlockZoneButton = Instance.new("TextButton")
unlockZoneButton.Size = UDim2.new(1, -12, 0, 34)
unlockZoneButton.Position = UDim2.fromOffset(6, 0)
unlockZoneButton.BackgroundColor3 = Color3.fromRGB(80, 90, 140)
unlockZoneButton.TextColor3 = Color3.fromRGB(255, 255, 255)
unlockZoneButton.Font = Enum.Font.GothamBold
unlockZoneButton.TextSize = 18
unlockZoneButton.Text = "Unlock Zone"
unlockZoneButton.Parent = frame

local dealershipHeader = makeLabel("Dealership")
dealershipHeader.Text = "Dealership"

local carButtonsById: {[string]: TextButton} = {}
for _, carDef in pairs(CarConfig.Cars) do
	local button = Instance.new("TextButton")
	button.Name = "Car_" .. carDef.Id
	button.Size = UDim2.new(1, -12, 0, 30)
	button.Position = UDim2.fromOffset(6, 0)
	button.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.Gotham
	button.TextSize = 16
	button.Text = string.format("%s ($%d)", carDef.DisplayName, carDef.Cost)
	button.Parent = frame
	carButtonsById[carDef.Id] = button
end

local cachedNextCost = 0
local cachedOwnedCars: {[string]: boolean} = {}
local cachedEquippedCarId = CarConfig.StarterCarId
local cachedNextZoneId = ""
local cachedNextZoneCost = 0

local function toNumber(value: any, fallback: number): number
	if typeof(value) == "number" then
		return value
	end
	return fallback
end

local function rebuildCarButtons()
	for carId, button in pairs(carButtonsById) do
		local carDef = CarConfig.Cars[carId]
		local owned = cachedOwnedCars[carId] == true
		local equipped = carId == cachedEquippedCarId
		if equipped then
			button.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
			button.Text = string.format("%s (Equipped)", carDef.DisplayName)
		elseif owned then
			button.BackgroundColor3 = Color3.fromRGB(70, 90, 130)
			button.Text = string.format("%s (Owned)", carDef.DisplayName)
		else
			button.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
			button.Text = string.format("%s ($%d)", carDef.DisplayName, carDef.Cost)
		end
	end
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
	cachedEquippedCarId = tostring(payload.EquippedCarId or CarConfig.StarterCarId)
	cachedNextZoneId = tostring(payload.NextZoneId or "")
	cachedNextZoneCost = math.floor(toNumber(payload.NextZoneCost, 0))

	cachedOwnedCars = {}
	if typeof(payload.OwnedCars) == "table" then
		for _, carId in ipairs(payload.OwnedCars) do
			cachedOwnedCars[tostring(carId)] = true
		end
	end

	cashLabel.Text = string.format("Cash: $%d", cash)
	multLabel.Text = string.format("Multiplier: x%.2f (Zone x%.2f * Up x%.2f * Reb x%.2f)", zoneMult * upMult * rebirthMult, zoneMult, upMult, rebirthMult)
	zoneLabel.Text = string.format("Zone: %s", zoneId)
	speedLabel.Text = string.format("Speed: %d", speed)
	equippedLabel.Text = "Equipped Car: " .. cachedEquippedCarId
	if cachedNextCost > 0 then
		upgradeLabel.Text = string.format("Upgrade L%d -> L%d: $%d (x%.2f)", upgradeLevel, upgradeLevel + 1, cachedNextCost, nextUpgradeMult)
		buyUpgradeButton.Text = string.format("Buy Upgrade ($%d)", cachedNextCost)
		buyUpgradeButton.BackgroundColor3 = Color3.fromRGB(55, 120, 55)
	else
		upgradeLabel.Text = string.format("Upgrade: MAX (x%.2f)", upMult)
		buyUpgradeButton.Text = "Max Upgrade Reached"
		buyUpgradeButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	end

	if cachedNextZoneCost > 0 and cachedNextZoneId ~= "" then
		zoneUnlockLabel.Text = string.format("Next Zone: %s ($%d)", cachedNextZoneId, cachedNextZoneCost)
		unlockZoneButton.Text = string.format("Unlock Zone %s ($%d)", cachedNextZoneId, cachedNextZoneCost)
		unlockZoneButton.BackgroundColor3 = Color3.fromRGB(80, 90, 140)
	else
		zoneUnlockLabel.Text = "Zone Unlock: All zones unlocked"
		unlockZoneButton.Text = "All Zones Unlocked"
		unlockZoneButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
	end

	if payload.AntiCheat then
		msgLabel.Text = "Message: " .. tostring(payload.AntiCheat)
	end
	rebuildCarButtons()
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

unlockZoneButton.Activated:Connect(function()
	if cachedNextZoneCost <= 0 or cachedNextZoneId == "" then
		return
	end
	local ok, msg = requestUnlockZone:InvokeServer(cachedNextZoneId)
	if not ok then
		msgLabel.Text = "Message: " .. tostring(msg)
	end
end)

for carId, button in pairs(carButtonsById) do
	button.Activated:Connect(function()
		if cachedOwnedCars[carId] then
			local ok, msg = requestEquipCar:InvokeServer(carId)
			if not ok then
				msgLabel.Text = "Message: " .. tostring(msg)
			end
		else
			local ok, msg = requestBuyCar:InvokeServer(carId)
			if not ok then
				msgLabel.Text = "Message: " .. tostring(msg)
			end
		end
	end)
end

print("[UIController] Ready")

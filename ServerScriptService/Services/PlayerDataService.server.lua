--!strict
-- Ticket 5: lightweight in-memory leaderboard values.
-- DataStore persistence can be layered in later without changing race flow.

local Players = game:GetService("Players")

local function ensureAttribute(player: Player, attributeName: string, defaultValue: number)
	if player:GetAttribute(attributeName) == nil then
		player:SetAttribute(attributeName, defaultValue)
	end
end

local function bindAttributeToValue(player: Player, attributeName: string, value: IntValue)
	local function sync()
		local raw = player:GetAttribute(attributeName)
		local numberValue = 0
		if typeof(raw) == "number" then
			numberValue = math.floor(raw)
		end
		value.Value = numberValue
	end

	player:GetAttributeChangedSignal(attributeName):Connect(sync)
	sync()
end

local function onPlayerAdded(player: Player)
	ensureAttribute(player, "Cash", 0)
	ensureAttribute(player, "BestLapMs", 0)
	ensureAttribute(player, "CurrentLap", 0)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats

	local bestLapMs = Instance.new("IntValue")
	bestLapMs.Name = "BestLapMs"
	bestLapMs.Parent = leaderstats

	local currentLap = Instance.new("IntValue")
	currentLap.Name = "CurrentLap"
	currentLap.Parent = leaderstats

	bindAttributeToValue(player, "Cash", cash)
	bindAttributeToValue(player, "BestLapMs", bestLapMs)
	bindAttributeToValue(player, "CurrentLap", currentLap)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

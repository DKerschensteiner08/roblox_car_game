--!strict
-- Tickets 3-5 client HUD: checkpoint progress, lap timer, rewards, and leaderboard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("RemoteNames"))

local localPlayer = Players.LocalPlayer

local checkpointRemote = remotesFolder:WaitForChild(RemoteNames.CheckpointProgress) :: RemoteEvent
local lapTimerRemote = remotesFolder:WaitForChild(RemoteNames.LapTimerUpdate) :: RemoteEvent
local leaderboardRemote = remotesFolder:WaitForChild(RemoteNames.LeaderboardUpdate) :: RemoteEvent
local rewardRemote = remotesFolder:WaitForChild(RemoteNames.RewardUpdate) :: RemoteEvent
local raceStateRemote = remotesFolder:WaitForChild(RemoteNames.RaceStateUpdate) :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RaceHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Root"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1, 1)
root.Parent = screenGui

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.Size = UDim2.fromOffset(320, 46)
timerLabel.Position = UDim2.new(0.5, -160, 0, 20)
timerLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
timerLabel.BackgroundTransparency = 0.25
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextScaled = true
timerLabel.Text = "Lap Time: 00:00.000"
timerLabel.Parent = root

local progressLabel = Instance.new("TextLabel")
progressLabel.Name = "Progress"
progressLabel.Size = UDim2.fromOffset(360, 36)
progressLabel.Position = UDim2.new(0.5, -180, 0, 70)
progressLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
progressLabel.BackgroundTransparency = 0.3
progressLabel.TextColor3 = Color3.fromRGB(200, 240, 255)
progressLabel.Font = Enum.Font.Gotham
progressLabel.TextScaled = true
progressLabel.Text = "Checkpoint: 0/0 | Lap 0/0"
progressLabel.Parent = root

local rewardLabel = Instance.new("TextLabel")
rewardLabel.Name = "Reward"
rewardLabel.Size = UDim2.fromOffset(420, 32)
rewardLabel.Position = UDim2.new(0.5, -210, 0, 112)
rewardLabel.BackgroundTransparency = 1
rewardLabel.TextColor3 = Color3.fromRGB(255, 225, 115)
rewardLabel.Font = Enum.Font.GothamMedium
rewardLabel.TextScaled = true
rewardLabel.Text = ""
rewardLabel.Parent = root

local leaderboardLabel = Instance.new("TextLabel")
leaderboardLabel.Name = "Leaderboard"
leaderboardLabel.Size = UDim2.fromOffset(290, 200)
leaderboardLabel.Position = UDim2.new(1, -305, 0, 20)
leaderboardLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
leaderboardLabel.BackgroundTransparency = 0.3
leaderboardLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
leaderboardLabel.TextXAlignment = Enum.TextXAlignment.Left
leaderboardLabel.TextYAlignment = Enum.TextYAlignment.Top
leaderboardLabel.Font = Enum.Font.Code
leaderboardLabel.TextSize = 18
leaderboardLabel.Text = "Leaderboard\n"
leaderboardLabel.Parent = root

local lapElapsedServer = 0
local lapTickReceived = 0
local lapRunning = false
local raceFinished = false

local rewardShownUntil = 0
local rewardText = ""

local function formatTime(seconds: number?): string
	if not seconds then
		return "--:--.---"
	end
	if seconds < 0 then
		seconds = 0
	end
	local totalMs = math.floor(seconds * 1000 + 0.5)
	local minutes = math.floor(totalMs / 60000)
	local remainder = totalMs % 60000
	local sec = math.floor(remainder / 1000)
	local ms = remainder % 1000
	return string.format("%02d:%02d.%03d", minutes, sec, ms)
end

local function refreshRewardVisibility()
	if os.clock() <= rewardShownUntil then
		rewardLabel.Text = rewardText
	else
		rewardLabel.Text = ""
	end
end

checkpointRemote.OnClientEvent:Connect(function(payload)
	local currentLap = tonumber(payload.currentLap) or 0
	local lapsRequired = tonumber(payload.lapsRequired) or 0
	local checkpointCount = tonumber(payload.checkpointCount) or 0
	local nextIndex = tonumber(payload.nextCheckpointIndex) or 1

	local passed = math.clamp(nextIndex - 1, 0, checkpointCount)
	progressLabel.Text = string.format(
		"Checkpoint: %d/%d | Lap %d/%d",
		passed,
		checkpointCount,
		currentLap,
		lapsRequired
	)
end)

lapTimerRemote.OnClientEvent:Connect(function(payload)
	local eventType = tostring(payload.event)
	if eventType == "tick" then
		lapElapsedServer = tonumber(payload.elapsed) or 0
		lapRunning = payload.isRunning == true
		if lapRunning then
			raceFinished = false
		end
		lapTickReceived = os.clock()
	end
end)

leaderboardRemote.OnClientEvent:Connect(function(payload)
	local rows = payload.rows
	if typeof(rows) ~= "table" then
		return
	end

	local lines = {"Leaderboard"}
	for index, row in ipairs(rows) do
		if index > 8 then
			break
		end
		local name = tostring(row.name or "Player")
		local lap = tonumber(row.currentLap) or 0
		local best = tonumber(row.bestLapTime)
		table.insert(lines, string.format("%d. %s | Lap %d | Best %s", index, name, lap, formatTime(best)))
	end
	leaderboardLabel.Text = table.concat(lines, "\n")
end)

rewardRemote.OnClientEvent:Connect(function(payload)
	local amount = tonumber(payload.amount) or 0
	local reason = tostring(payload.reason or "Reward")
	rewardText = string.format("+%d Cash (%s)", amount, reason)
	rewardShownUntil = os.clock() + 3
	refreshRewardVisibility()
end)

raceStateRemote.OnClientEvent:Connect(function(payload)
	if tostring(payload.phase) == "Finished" then
		raceFinished = true
		lapRunning = false
		local best = tonumber(payload.bestLapTime)
		timerLabel.Text = string.format("Race Finished | Best Lap: %s", formatTime(best))
	end
end)

RunService.RenderStepped:Connect(function()
	if raceFinished then
		refreshRewardVisibility()
		return
	end
	local displayElapsed = lapElapsedServer
	if lapRunning then
		displayElapsed += os.clock() - lapTickReceived
	end
	timerLabel.Text = "Lap Time: " .. formatTime(displayElapsed)
	refreshRewardVisibility()
end)

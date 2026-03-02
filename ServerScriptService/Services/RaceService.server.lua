--!strict
-- Tickets 3-5: server-authoritative checkpoints, laps, timer truth, and leaderboard feed.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("RemoteNames"))
local RaceConfig = require(modulesFolder:WaitForChild("RaceConfig"))

local raceStateRemote = remotesFolder:WaitForChild(RemoteNames.RaceStateUpdate) :: RemoteEvent
local checkpointRemote = remotesFolder:WaitForChild(RemoteNames.CheckpointProgress) :: RemoteEvent
local lapTimerRemote = remotesFolder:WaitForChild(RemoteNames.LapTimerUpdate) :: RemoteEvent
local leaderboardRemote = remotesFolder:WaitForChild(RemoteNames.LeaderboardUpdate) :: RemoteEvent

local serviceEventsFolder = ServerScriptService:WaitForChild("ServiceEvents")
local awardCurrencyEvent = serviceEventsFolder:WaitForChild("AwardCurrency") :: BindableEvent

type PlayerRaceState = {
	currentLap: number,
	nextCheckpointIndex: number,
	lapStartTime: number?,
	lastLapTime: number?,
	bestLapTime: number?,
	finished: boolean,
	lastHitTime: number,
	participationAwarded: boolean,
}

local raceByPlayer: {[number]: PlayerRaceState} = {}
local orderedCheckpoints: {BasePart} = {}
local finishLine: BasePart? = nil

local function parseCheckpointIndex(name: string): number?
	local digits = string.match(name, "(%d+)$")
	if not digits then
		return nil
	end
	return tonumber(digits)
end

local function rebuildCheckpointCache()
	orderedCheckpoints = {}
	finishLine = nil

	local folder = Workspace:FindFirstChild(RaceConfig.Checkpoints.FolderName)
	if folder then
		local indexed: {[number]: BasePart} = {}
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("BasePart") then
				local checkpointIndex = parseCheckpointIndex(child.Name)
				if checkpointIndex then
					indexed[checkpointIndex] = child
				end
			end
		end

		local maxIndex = 0
		for index in pairs(indexed) do
			if index > maxIndex then
				maxIndex = index
			end
		end

		for index = 1, maxIndex do
			local part = indexed[index]
			if part then
				table.insert(orderedCheckpoints, part)
			end
		end
	end

	local finish = Workspace:FindFirstChild(RaceConfig.Checkpoints.FinishLineName)
	if finish and finish:IsA("BasePart") then
		finishLine = finish
	end
end

local function getPlayerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	if model then
		local ownerUserId = model:GetAttribute("OwnerUserId")
		if typeof(ownerUserId) == "number" then
			return Players:GetPlayerByUserId(ownerUserId)
		end
	end

	return nil
end

local function ensureState(player: Player): PlayerRaceState
	local existing = raceByPlayer[player.UserId]
	if existing then
		return existing
	end

	local newState: PlayerRaceState = {
		currentLap = 0,
		nextCheckpointIndex = 1,
		lapStartTime = nil,
		lastLapTime = nil,
		bestLapTime = nil,
		finished = false,
		lastHitTime = 0,
		participationAwarded = false,
	}
	raceByPlayer[player.UserId] = newState
	return newState
end

local function setPlayerLapAttributes(player: Player, state: PlayerRaceState)
	player:SetAttribute("CurrentLap", state.currentLap)
	local bestMs = 0
	if state.bestLapTime then
		bestMs = math.floor(state.bestLapTime * 1000 + 0.5)
	end
	player:SetAttribute("BestLapMs", bestMs)
end

local function fireCheckpointProgress(player: Player, state: PlayerRaceState)
	checkpointRemote:FireClient(player, {
		currentLap = state.currentLap,
		lapsRequired = RaceConfig.Game.DefaultLaps,
		nextCheckpointIndex = state.nextCheckpointIndex,
		checkpointCount = #orderedCheckpoints,
	})
end

local function grantReward(player: Player, amount: number, reason: string)
	awardCurrencyEvent:Fire(player, amount, reason)
end

local function onCheckpointTouched(checkpointIndex: number, hit: BasePart)
	local player = getPlayerFromHit(hit)
	if not player then
		return
	end

	local state = ensureState(player)
	if state.finished then
		return
	end

	local now = os.clock()
	if now - state.lastHitTime < 0.15 then
		return
	end
	state.lastHitTime = now

	if checkpointIndex ~= state.nextCheckpointIndex then
		return
	end

	if state.lapStartTime == nil then
		state.lapStartTime = now
		if not state.participationAwarded then
			state.participationAwarded = true
			grantReward(player, RaceConfig.Rewards.Participation, "Race start")
		end
	end

	state.nextCheckpointIndex += 1
	fireCheckpointProgress(player, state)
end

local function onFinishTouched(hit: BasePart)
	local player = getPlayerFromHit(hit)
	if not player then
		return
	end

	local state = ensureState(player)
	if state.finished then
		return
	end

	local now = os.clock()
	if now - state.lastHitTime < 0.25 then
		return
	end
	state.lastHitTime = now

	if #orderedCheckpoints == 0 or state.nextCheckpointIndex <= #orderedCheckpoints then
		return
	end

	if state.lapStartTime == nil then
		return
	end

	local lapTime = now - state.lapStartTime
	state.lastLapTime = lapTime
	if state.bestLapTime == nil or lapTime < state.bestLapTime then
		state.bestLapTime = lapTime
	end

	state.currentLap += 1
	state.nextCheckpointIndex = 1
	state.lapStartTime = now

	setPlayerLapAttributes(player, state)
	grantReward(player, RaceConfig.Rewards.LapComplete, "Lap complete")

	lapTimerRemote:FireClient(player, {
		event = "lapComplete",
		lap = state.currentLap,
		lapTime = lapTime,
		bestLapTime = state.bestLapTime,
	})

	fireCheckpointProgress(player, state)

	if state.currentLap >= RaceConfig.Game.DefaultLaps then
		state.finished = true
		state.lapStartTime = nil
		grantReward(player, RaceConfig.Rewards.RaceWin, "Race win")

		raceStateRemote:FireClient(player, {
			phase = "Finished",
			lapsRequired = RaceConfig.Game.DefaultLaps,
			currentLap = state.currentLap,
			bestLapTime = state.bestLapTime,
		})
	end
end

local function broadcastLeaderboard()
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local state = raceByPlayer[player.UserId]
		local best = nil
		local currentLap = 0
		if state then
			best = state.bestLapTime
			currentLap = state.currentLap
		end

		table.insert(rows, {
			name = player.Name,
			userId = player.UserId,
			currentLap = currentLap,
			bestLapTime = best,
		})
	end

	table.sort(rows, function(a, b)
		if a.currentLap ~= b.currentLap then
			return a.currentLap > b.currentLap
		end
		local aBest = a.bestLapTime or math.huge
		local bBest = b.bestLapTime or math.huge
		if aBest ~= bBest then
			return aBest < bBest
		end
		return a.name < b.name
	end)

	leaderboardRemote:FireAllClients({
		rows = rows,
	})
end

local function bindTrackParts()
	rebuildCheckpointCache()

	for index, checkpoint in ipairs(orderedCheckpoints) do
		checkpoint.Touched:Connect(function(hit: BasePart)
			onCheckpointTouched(index, hit)
		end)
	end

	if finishLine then
		finishLine.Touched:Connect(onFinishTouched)
	end
end

local function onPlayerAdded(player: Player)
	local state = ensureState(player)
	setPlayerLapAttributes(player, state)

	raceStateRemote:FireClient(player, {
		phase = "Racing",
		lapsRequired = RaceConfig.Game.DefaultLaps,
		currentLap = state.currentLap,
	})
	fireCheckpointProgress(player, state)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	raceByPlayer[player.UserId] = nil
end)

bindTrackParts()

local raceStateAccumulator = 0
local leaderboardAccumulator = 0
RunService.Heartbeat:Connect(function(dt)
	raceStateAccumulator += dt
	leaderboardAccumulator += dt

	if raceStateAccumulator >= RaceConfig.Game.RaceStateBroadcastRate then
		raceStateAccumulator = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local state = raceByPlayer[player.UserId]
			if not state then
				continue
			end

			local elapsed = 0
			if state.lapStartTime then
				elapsed = os.clock() - state.lapStartTime
			end

			lapTimerRemote:FireClient(player, {
				event = "tick",
				lap = state.currentLap,
				elapsed = elapsed,
				isRunning = state.lapStartTime ~= nil and not state.finished,
				bestLapTime = state.bestLapTime,
			})
		end
	end

	if leaderboardAccumulator >= RaceConfig.Game.LeaderboardBroadcastRate then
		leaderboardAccumulator = 0
		broadcastLeaderboard()
	end
end)

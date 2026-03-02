--!strict
-- Ticket 5 rewards service.
-- Award requests are accepted only from server-owned bindable events.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local RemoteNames = require(modulesFolder:WaitForChild("RemoteNames"))

local rewardRemote = remotesFolder:WaitForChild(RemoteNames.RewardUpdate) :: RemoteEvent

local serviceEventsFolder = ServerScriptService:FindFirstChild("ServiceEvents")
if not serviceEventsFolder then
	serviceEventsFolder = Instance.new("Folder")
	serviceEventsFolder.Name = "ServiceEvents"
	serviceEventsFolder.Parent = ServerScriptService
end

local awardCurrencyEvent = serviceEventsFolder:FindFirstChild("AwardCurrency")
if not awardCurrencyEvent then
	awardCurrencyEvent = Instance.new("BindableEvent")
	awardCurrencyEvent.Name = "AwardCurrency"
	awardCurrencyEvent.Parent = serviceEventsFolder
end

local function clampMoney(raw: number): number
	if raw < 0 then
		return 0
	end
	return math.floor(raw)
end

(awardCurrencyEvent :: BindableEvent).Event:Connect(function(player: Player, amount: number, reason: string)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
		return
	end

	if typeof(amount) ~= "number" or amount <= 0 then
		return
	end

	local previousCash = player:GetAttribute("Cash")
	local old = if typeof(previousCash) == "number" then previousCash else 0
	local nextValue = clampMoney(old + amount)
	player:SetAttribute("Cash", nextValue)

	rewardRemote:FireClient(player, {
		amount = math.floor(amount),
		reason = reason,
		cashAfter = nextValue,
	})
end)

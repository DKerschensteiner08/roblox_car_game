--!strict
-- Server-authoritative rewards scaffold.
-- Ticket 5+ should only grant rewards from validated race outcomes.

local RewardService = {}

function RewardService.GrantParticipationReward(_player: Player)
	-- TODO(Ticket 5): Wire to player data/currency service.
end

return RewardService

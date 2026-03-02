--!strict

local Util = {}

function Util.ClampNumber(value: number, minValue: number, maxValue: number): number
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

function Util.SafeFloor(value: number): number
	if value ~= value or value == math.huge or value == -math.huge then
		return 0
	end
	return math.floor(value)
end

return Util

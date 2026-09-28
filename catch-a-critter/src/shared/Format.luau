--!strict
-- Number and time formatting for the UI and billboards.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.Number(n: number): string
	local negative = n < 0
	n = math.abs(n)
	if n < 1000 then
		return (if negative then "-" else "") .. tostring(math.floor(n))
	end
	local index = 1
	while n >= 1000 and index < #SUFFIXES do
		n /= 1000
		index += 1
	end
	local text
	if n < 10 then
		text = string.format("%.2f", math.floor(n * 100) / 100)
	elseif n < 100 then
		text = string.format("%.1f", math.floor(n * 10) / 10)
	else
		text = tostring(math.floor(n))
	end
	return (if negative then "-" else "") .. text .. SUFFIXES[index]
end

function Format.Money(n: number): string
	return "$" .. Format.Number(n)
end

function Format.Time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	local secs = seconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

function Format.Percent(fraction: number): string
	local pct = fraction * 100
	if pct >= 1 then
		return string.format("%.1f%%", pct)
	elseif pct >= 0.01 then
		return string.format("%.2f%%", pct)
	end
	return string.format("%.3f%%", pct)
end

return Format

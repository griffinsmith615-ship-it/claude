--!strict
-- Scheduled live moments: the Critter Storm (on a global clock, so every
-- server storms together), weekend double cash, and purchased server luck.
-- State is mirrored onto Workspace attributes so the client can show timers.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Notifier = require(script.Parent.Notifier)

local EventService = {}

local serverLuckEndsAt = 0
local forcedStormEndsAt = 0

local function now(): number
	return os.time()
end

-- Returns: active, endsAt (if active), nextStartAt
function EventService.StormInfo(): (boolean, number, number)
	local t = now()
	if t < forcedStormEndsAt then
		return true, forcedStormEndsAt, forcedStormEndsAt + Config.StormEvery
	end
	local cycleStart = t - t % Config.StormEvery
	local endsAt = cycleStart + Config.StormDuration
	if t < endsAt then
		return true, endsAt, cycleStart + Config.StormEvery
	end
	return false, 0, cycleStart + Config.StormEvery
end

function EventService.IsWeekend(): boolean
	local weekday = os.date("!*t", now()).wday -- 1 = Sunday, 7 = Saturday
	return weekday == 1 or weekday == 7
end

function EventService.ServerLuckActive(): boolean
	return now() < serverLuckEndsAt
end

function EventService.GetLuck(): number
	local luck = 1
	if EventService.StormInfo() then
		luck *= Config.StormLuck
	end
	if EventService.ServerLuckActive() then
		luck *= Config.ServerLuckMultiplier
	end
	return luck
end

function EventService.GetSpawnMultiplier(): number
	return if EventService.StormInfo() then Config.StormSpawnMultiplier else 1
end

function EventService.GetCashMultiplier(): number
	return if EventService.IsWeekend() then Config.WeekendCashMultiplier else 1
end

function EventService.AddServerLuck(seconds: number)
	serverLuckEndsAt = math.max(now(), serverLuckEndsAt) + seconds
	Workspace:SetAttribute("ServerLuckEndsAt", serverLuckEndsAt)
end

function EventService.ForceStorm(seconds: number)
	forcedStormEndsAt = now() + seconds
end

local calm = {
	ClockTime = 14,
	OutdoorAmbient = Color3.fromRGB(150, 150, 160),
}
local stormy = {
	ClockTime = 17.6,
	OutdoorAmbient = Color3.fromRGB(120, 90, 170),
}

local function setMood(storm: boolean)
	TweenService:Create(Lighting, TweenInfo.new(4), if storm then stormy else calm):Play()
end

function EventService.Init()
	local wasStorm = false
	task.spawn(function()
		while true do
			local active, endsAt, nextAt = EventService.StormInfo()
			Workspace:SetAttribute("StormActive", active)
			Workspace:SetAttribute("StormEndsAt", endsAt)
			Workspace:SetAttribute("NextStormAt", nextAt)
			Workspace:SetAttribute("WeekendActive", EventService.IsWeekend())
			Workspace:SetAttribute("ServerLuckEndsAt", serverLuckEndsAt)

			if active and not wasStorm then
				Notifier.Announce(string.format("CRITTER STORM! %dx luck and double spawns!", Config.StormLuck), Color3.fromRGB(190, 120, 255))
				setMood(true)
			elseif not active and wasStorm then
				Notifier.Announce("The storm has passed... next one in " .. math.floor(Config.StormEvery / 60) .. " minutes!", Color3.fromRGB(150, 200, 255))
				setMood(false)
			end
			wasStorm = active
			task.wait(1)
		end
	end)
end

return EventService

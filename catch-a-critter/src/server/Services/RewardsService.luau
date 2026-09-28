--!strict
-- Handles UI requests from the client: buying slots, rebirthing,
-- the daily streak, and codes. Everything is validated on the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Critters = require(ReplicatedStorage.Shared.Critters)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Analytics = require(script.Parent.Analytics)
local DataService = require(script.Parent.DataService)
local Economy = require(script.Parent.Economy)
local Notifier = require(script.Parent.Notifier)
local PlotService = require(script.Parent.PlotService)

type Result = { Ok: boolean, Message: string }

local RewardsService = {}

local lastRequest: { [Player]: number } = {}

local function result(ok: boolean, message: string): Result
	return { Ok = ok, Message = message }
end

local function today(): number
	return os.time() // 86400
end

local function buySlot(player: Player, profile: DataService.Profile): Result
	if profile.BoughtSlots >= Config.MaxBoughtSlots then
		return result(false, "You've bought every slot!")
	end
	local cost = Config.SlotCost(profile.BoughtSlots)
	if not Economy.Spend(player, cost, Enum.AnalyticsEconomyTransactionType.Shop, "Slot" .. (profile.BoughtSlots + 1)) then
		return result(false, "You need " .. Format.Money(cost) .. " for this slot.")
	end
	profile.BoughtSlots += 1
	PlotService.UpdatePedestals(player)
	Economy.Refresh(player)
	Analytics.Funnel(player, 4, "Bought first slot")
	return result(true, "New slot unlocked!")
end

local function rebirth(player: Player, profile: DataService.Profile): Result
	local cost = Config.RebirthCost(profile.Rebirths)
	if profile.Cash < cost then
		return result(false, "You need " .. Format.Money(cost) .. " to rebirth.")
	end
	Analytics.Economy(player, false, profile.Cash, 0, Enum.AnalyticsEconomyTransactionType.Gameplay, "Rebirth" .. (profile.Rebirths + 1))
	profile.Cash = 0
	profile.Rebirths += 1
	Economy.Refresh(player)
	Notifier.Announce(string.format("%s reached Rebirth %d!", player.DisplayName, profile.Rebirths), Color3.fromRGB(255, 220, 90))
	Analytics.Custom(player, "Rebirth", profile.Rebirths)
	return result(true, string.format("Rebirth %d! Income is now x%.1f from rebirths.", profile.Rebirths, 1 + profile.Rebirths * Config.RebirthIncomeBonus))
end

local function claimDaily(player: Player, profile: DataService.Profile): Result
	local day = today()
	if profile.DailyDay == day then
		return result(false, "Already claimed today. Come back tomorrow!")
	end
	profile.DailyStreak = if profile.DailyDay == day - 1 then profile.DailyStreak + 1 else 1
	profile.DailyDay = day

	local rewardIndex = (profile.DailyStreak - 1) % #Config.DailyRewards + 1
	local reward = Config.DailyRewards[rewardIndex]
	local cash = math.max(reward.Min, Economy.Income(player, profile, false) * reward.Seconds)
	local extra = ""
	if reward.Legendary then
		local pool = Critters.OfRarity("Legendary")
		local def = pool[math.random(1, #pool)]
		if PlotService.AddCritter(player, def.Id, "Normal") then
			extra = " and a Legendary " .. def.Name .. "!"
		else
			cash *= 2
			extra = " (base full, so double cash instead of a Legendary)"
		end
	end
	Economy.Add(player, cash, Enum.AnalyticsEconomyTransactionType.TimedReward, "Daily" .. rewardIndex)
	return result(true, string.format("Day %d streak! +%s%s", profile.DailyStreak, Format.Money(cash), extra))
end

local function redeem(player: Player, profile: DataService.Profile, code: any): Result
	if type(code) ~= "string" or #code > 30 then
		return result(false, "Invalid code.")
	end
	local key = string.upper((string.gsub(code, "%s", "")))
	local reward = Config.Codes[key]
	if not reward then
		return result(false, "That code doesn't exist (or expired).")
	end
	if profile.Codes[key] then
		return result(false, "You already used that code.")
	end
	profile.Codes[key] = true
	Economy.Add(player, reward.Cash, Enum.AnalyticsEconomyTransactionType.Gameplay, "Code_" .. key)
	return result(true, "Code redeemed! +" .. Format.Money(reward.Cash))
end

local handlers: { [string]: (Player, DataService.Profile, any) -> Result } = {
	BuySlot = buySlot,
	Rebirth = rebirth,
	ClaimDaily = claimDaily,
	Redeem = redeem,
}

function RewardsService.Init()
	Remotes.Function("Request").OnServerInvoke = function(player: Player, action: any, arg: any): Result
		local clock = os.clock()
		if clock - (lastRequest[player] or 0) < 0.25 then
			return result(false, "Slow down!")
		end
		lastRequest[player] = clock

		local profile = DataService.Get(player)
		local handler = if type(action) == "string" then handlers[action] else nil
		if not profile or not handler then
			return result(false, "Not ready yet.")
		end
		return handler(player, profile, arg)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return RewardsService

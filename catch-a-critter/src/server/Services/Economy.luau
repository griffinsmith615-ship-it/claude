--!strict
-- Income math and the single place that updates a player's cash.
-- Player state is mirrored onto player attributes for the client UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Critters = require(ReplicatedStorage.Shared.Critters)
local Analytics = require(script.Parent.Analytics)
local DataService = require(script.Parent.DataService)
local EventService = require(script.Parent.EventService)

type Profile = DataService.Profile

local Economy = {}

function Economy.SlotCount(player: Player, profile: Profile): number
	local bonus = if player:GetAttribute("Pass_ExtraSlots") then Config.PassBonusSlots else 0
	return Config.StartSlots + profile.BoughtSlots + bonus
end

function Economy.IndexCount(profile: Profile): number
	local count = 0
	for id in profile.Index do
		if Critters.Get(id) then
			count += 1
		end
	end
	return count
end

function Economy.BaseIncome(profile: Profile): number
	local total = 0
	for _, entry in profile.Critters do
		total += Critters.Income(entry.Id, entry.Mut)
	end
	return total
end

function Economy.Multiplier(player: Player, profile: Profile, includeEvents: boolean): number
	local multiplier = 1 + profile.Rebirths * Config.RebirthIncomeBonus
	multiplier *= 1 + Economy.IndexCount(profile) * Config.IndexBonusPerCritter
	multiplier *= 1 + ((player:GetAttribute("FriendBoost") :: number?) or 0)
	if player:GetAttribute("Pass_DoubleCash") then
		multiplier *= 2
	end
	if includeEvents then
		multiplier *= EventService.GetCashMultiplier()
	end
	return multiplier
end

function Economy.Income(player: Player, profile: Profile, includeEvents: boolean): number
	return Economy.BaseIncome(profile) * Economy.Multiplier(player, profile, includeEvents)
end

function Economy.Refresh(player: Player)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	player:SetAttribute("Cash", profile.Cash)
	player:SetAttribute("Income", Economy.Income(player, profile, true))
	player:SetAttribute("Multiplier", Economy.Multiplier(player, profile, true))
	player:SetAttribute("Rebirths", profile.Rebirths)
	player:SetAttribute("BoughtSlots", profile.BoughtSlots)
	player:SetAttribute("Slots", Economy.SlotCount(player, profile))
	player:SetAttribute("UsedSlots", #profile.Critters)
	player:SetAttribute("DailyDay", profile.DailyDay)
	player:SetAttribute("DailyStreak", profile.DailyStreak)

	local found = {}
	for id in profile.Index do
		table.insert(found, id)
	end
	player:SetAttribute("Index", table.concat(found, ","))

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local cash = leaderstats:FindFirstChild("Cash")
		if cash and cash:IsA("NumberValue") then
			cash.Value = math.floor(profile.Cash)
		end
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths and rebirths:IsA("IntValue") then
			rebirths.Value = profile.Rebirths
		end
	end
end

function Economy.Add(player: Player, amount: number, transactionType: Enum.AnalyticsEconomyTransactionType?, sku: string?)
	local profile = DataService.Get(player)
	if not profile or amount <= 0 then
		return
	end
	profile.Cash += amount
	if transactionType then
		Analytics.Economy(player, true, amount, profile.Cash, transactionType, sku or "Unknown")
	end
	Economy.Refresh(player)
end

function Economy.Spend(player: Player, amount: number, transactionType: Enum.AnalyticsEconomyTransactionType, sku: string): boolean
	local profile = DataService.Get(player)
	if not profile or profile.Cash < amount then
		return false
	end
	profile.Cash -= amount
	Analytics.Economy(player, false, amount, profile.Cash, transactionType, sku)
	Economy.Refresh(player)
	return true
end

return Economy

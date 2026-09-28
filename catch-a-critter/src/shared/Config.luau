--!strict
-- Game-wide tuning. Most balance changes should only need edits in this file
-- and in Critters.luau.

local Config = {}

Config.GameName = "Catch a Critter"
Config.MaxPlots = 8 -- set the place's Max Players to 8 in Game Settings

-- Movement
Config.WalkSpeed = 22
Config.CarrySpeed = 14
Config.CarrySpeedWithPass = 21

-- Base slots
Config.StartSlots = 6
Config.MaxBoughtSlots = 14
Config.PassBonusSlots = 4
Config.MaxSlots = Config.StartSlots + Config.MaxBoughtSlots + Config.PassBonusSlots -- 24 pedestals per plot

function Config.SlotCost(bought: number): number
	return math.floor(250 * 3 ^ bought)
end

-- Rebirth: resets cash only (critters stay) for a permanent income boost.
Config.RebirthIncomeBonus = 0.5

function Config.RebirthCost(rebirths: number): number
	return 100000 * 5 ^ rebirths
end

-- Permanent bonuses
Config.IndexBonusPerCritter = 0.02 -- +2% income per unique critter discovered
Config.FriendBonus = 0.1 -- +10% income per friend in the server...
Config.FriendBonusMax = 0.3 -- ...up to +30%
Config.SellSeconds = 30 -- a critter sells for 30 seconds of its income

-- Offline earnings (the "grows while you're away" hook)
Config.OfflineCapHours = 4
Config.OfflineCapHoursVIP = 12
Config.OfflineMinSeconds = 60

-- Meadow and field critters
Config.MeadowRadius = 75
Config.PlotRingRadius = 160
Config.BaseFieldCritters = 16
Config.FieldCrittersPerPlayer = 3
Config.MaxFieldCritters = 44
Config.SpawnInterval = 1.5 -- seconds between spawns (divided during storms)

-- Critter Storm: a scheduled event on a fixed global clock, so every server
-- storms at the same time and players can plan to be online for it.
Config.StormEvery = 15 * 60
Config.StormDuration = 3 * 60
Config.StormLuck = 3
Config.StormSpawnMultiplier = 2

Config.WeekendCashMultiplier = 2 -- Saturday and Sunday (UTC)

-- Server luck (developer product, benefits the whole server)
Config.ServerLuckMultiplier = 2
Config.ServerLuckSeconds = 15 * 60

-- Bonk bat
Config.BonkCooldown = 1.2
Config.BonkRange = 10
Config.BonkKnockback = 55

-- Daily streak rewards: cash = max(Min, income * Seconds). Day 7 also grants a Legendary.
Config.DailyRewards = {
	{ Seconds = 120, Min = 100 },
	{ Seconds = 180, Min = 250 },
	{ Seconds = 300, Min = 500 },
	{ Seconds = 480, Min = 1000 },
	{ Seconds = 600, Min = 2000 },
	{ Seconds = 900, Min = 4000 },
	{ Seconds = 1800, Min = 10000, Legendary = true },
}

-- Codes: announce new ones with each update (in your Discord / group / game description).
Config.Codes = {
	LAUNCH = { Cash = 500 },
	CRITTERS = { Cash = 1500 },
	STORMY = { Cash = 5000 },
} :: { [string]: { Cash: number } }

-- Monetization. Create these in the Creator Dashboard and paste the IDs here.
-- An Id of 0 means "not set up yet": the shop shows it as "Coming soon".
export type ShopItem = { Key: string, Id: number, Name: string, Description: string }

Config.GamePasses = {
	{ Key = "DoubleCash", Id = 0, Name = "2x Cash", Description = "Double all critter income, forever." },
	{ Key = "SpeedyCarry", Id = 0, Name = "Speedy Carry", Description = "Run at almost full speed while carrying critters." },
	{ Key = "ExtraSlots", Id = 0, Name = "+4 Base Slots", Description = "Room for 4 more critters in your base." },
	{ Key = "VIP", Id = 0, Name = "VIP", Description = "12 hours of offline earnings (instead of 4) and a VIP chat tag." },
} :: { ShopItem }

Config.Products = {
	{ Key = "ServerLuck", Id = 0, Name = "Server Luck x2", Description = "EVERYONE in the server gets 2x luck for 15 minutes!" },
	{ Key = "CashSmall", Id = 0, Name = "Cash Pack", Description = "10 minutes of income (at least $1K)." },
	{ Key = "CashBig", Id = 0, Name = "Mega Cash Pack", Description = "1 hour of income (at least $10K)." },
} :: { ShopItem }

Config.CashPacks = {
	CashSmall = { Seconds = 600, Min = 1000 },
	CashBig = { Seconds = 3600, Min = 10000 },
} :: { [string]: { Seconds: number, Min: number } }

-- Extra admins (the game's creator is always an admin). Admins can run
-- "admin abuse" chat commands, e.g. /spawn Secret Galaxy, /storm, /luck 10
Config.AdminUserIds = {} :: { number }

return Config

--!strict
-- Critter, rarity, and mutation definitions plus the random rolls.
-- Rarer critters earn more, run faster, take longer to catch, and wander off sooner.

export type Rarity = {
	Name: string,
	Order: number,
	Color: Color3,
	Weight: number,
	CatchTime: number, -- seconds the Catch prompt must be held
	Speed: number, -- wander speed in the meadow (studs/sec)
	Lifetime: number, -- seconds before it wanders off
	Announce: boolean, -- tell the whole server when one appears or is caught
}

export type Critter = {
	Id: string,
	Name: string,
	Rarity: string,
	Income: number, -- cash per second before multipliers
	Color: Color3,
	Accent: Color3,
	Size: number,
	Feature: string, -- "None" | "Ears" | "Antennae" | "Wings" | "Horns" | "Cap" | "Mane"
	Neon: boolean,
}

export type Mutation = {
	Name: string,
	Multiplier: number,
	Chance: number, -- base chance per spawn, multiplied by luck
	Color: Color3?,
}

local Critters = {}

local rgb = Color3.fromRGB

Critters.Rarities = {
	{ Name = "Common", Order = 1, Color = rgb(190, 190, 190), Weight = 60, CatchTime = 0, Speed = 4, Lifetime = 120, Announce = false },
	{ Name = "Uncommon", Order = 2, Color = rgb(85, 210, 95), Weight = 25, CatchTime = 0.3, Speed = 5, Lifetime = 100, Announce = false },
	{ Name = "Rare", Order = 3, Color = rgb(60, 145, 255), Weight = 10, CatchTime = 0.6, Speed = 6.5, Lifetime = 90, Announce = false },
	{ Name = "Epic", Order = 4, Color = rgb(175, 85, 255), Weight = 3.5, CatchTime = 0.9, Speed = 8, Lifetime = 75, Announce = false },
	{ Name = "Legendary", Order = 5, Color = rgb(255, 200, 40), Weight = 1.2, CatchTime = 1.2, Speed = 10, Lifetime = 60, Announce = true },
	{ Name = "Mythic", Order = 6, Color = rgb(255, 70, 70), Weight = 0.25, CatchTime = 1.5, Speed = 12, Lifetime = 50, Announce = true },
	{ Name = "Secret", Order = 7, Color = rgb(255, 90, 210), Weight = 0.05, CatchTime = 2, Speed = 14, Lifetime = 40, Announce = true },
} :: { Rarity }

local function critter(id: string, name: string, rarity: string, income: number, color: Color3, accent: Color3, size: number, feature: string, neon: boolean?): Critter
	return {
		Id = id,
		Name = name,
		Rarity = rarity,
		Income = income,
		Color = color,
		Accent = accent,
		Size = size,
		Feature = feature,
		Neon = neon == true,
	}
end

Critters.List = {
	critter("pebblepup", "Pebblepup", "Common", 1, rgb(150, 150, 150), rgb(105, 105, 105), 2.2, "Ears"),
	critter("mossmouse", "Mossmouse", "Common", 2, rgb(120, 170, 90), rgb(215, 175, 155), 2, "Ears"),
	critter("blobbit", "Blobbit", "Common", 3, rgb(120, 200, 255), rgb(80, 150, 220), 2.4, "None"),
	critter("puddlefrog", "Puddlefrog", "Uncommon", 7, rgb(90, 200, 110), rgb(240, 240, 120), 2.4, "None"),
	critter("twigbug", "Twigbug", "Uncommon", 9, rgb(140, 100, 60), rgb(90, 160, 60), 2, "Antennae"),
	critter("bunbun", "Bunbun", "Uncommon", 12, rgb(255, 225, 235), rgb(255, 150, 185), 2.4, "Ears"),
	critter("honeybear", "Honeybear", "Rare", 25, rgb(230, 170, 60), rgb(120, 80, 40), 2.8, "Ears"),
	critter("sparkfly", "Sparkfly", "Rare", 32, rgb(255, 240, 120), rgb(180, 220, 255), 2, "Wings"),
	critter("cactoad", "Cactoad", "Rare", 40, rgb(80, 160, 80), rgb(255, 120, 160), 2.6, "Horns"),
	critter("lavapup", "Lavapup", "Epic", 90, rgb(255, 90, 30), rgb(60, 30, 30), 2.8, "Horns"),
	critter("frostfox", "Frostfox", "Epic", 120, rgb(200, 235, 255), rgb(120, 190, 255), 2.8, "Ears"),
	critter("mushmallow", "Mushmallow", "Epic", 150, rgb(240, 230, 220), rgb(230, 60, 60), 2.6, "Cap"),
	critter("thunderhog", "Thunderhog", "Legendary", 400, rgb(255, 220, 60), rgb(60, 60, 120), 3.2, "Mane"),
	critter("moonmoth", "Moonmoth", "Legendary", 550, rgb(200, 200, 255), rgb(120, 100, 220), 2.8, "Wings"),
	critter("crystalwyrm", "Crystalwyrm", "Mythic", 1500, rgb(120, 255, 230), rgb(60, 120, 255), 3.4, "Horns", true),
	critter("solarlion", "Solarlion", "Mythic", 2200, rgb(255, 170, 40), rgb(255, 90, 20), 3.6, "Mane", true),
	critter("voidkitty", "Voidkitty", "Secret", 8000, rgb(35, 20, 55), rgb(175, 80, 255), 3, "Ears"),
	critter("glitchy", "Glitchy", "Secret", 15000, rgb(0, 255, 120), rgb(255, 0, 200), 3, "Antennae", true),
}

-- Checked in the order listed (rarest first). Normal is the fallback.
Critters.Mutations = {
	{ Name = "Galaxy", Multiplier = 10, Chance = 0.0015, Color = rgb(45, 20, 95) },
	{ Name = "Rainbow", Multiplier = 5, Chance = 0.008, Color = rgb(255, 80, 80) },
	{ Name = "Golden", Multiplier = 2, Chance = 0.04, Color = rgb(255, 200, 50) },
	{ Name = "Normal", Multiplier = 1, Chance = 1 },
} :: { Mutation }

local byId: { [string]: Critter } = {}
local rarityByName: { [string]: Rarity } = {}
local mutationByName: { [string]: Mutation } = {}
local byRarity: { [string]: { Critter } } = {}

for _, rarity in Critters.Rarities do
	rarityByName[rarity.Name] = rarity
	byRarity[rarity.Name] = {}
end
for _, def in Critters.List do
	byId[def.Id] = def
	table.insert(byRarity[def.Rarity], def)
end
for _, mutation in Critters.Mutations do
	mutationByName[mutation.Name] = mutation
end

function Critters.Get(id: string): Critter?
	return byId[id]
end

function Critters.GetRarity(name: string): Rarity
	return rarityByName[name] or Critters.Rarities[1]
end

function Critters.GetMutation(name: string): Mutation
	return mutationByName[name] or mutationByName.Normal
end

function Critters.OfRarity(name: string): { Critter }
	return byRarity[name] or {}
end

function Critters.Income(id: string, mutation: string): number
	local def = byId[id]
	if not def then
		return 0
	end
	return def.Income * Critters.GetMutation(mutation).Multiplier
end

-- Luck multiplies the weight of every rarity above Common.
function Critters.RollRarity(luck: number, rng: Random): Rarity
	local total = 0
	for _, rarity in Critters.Rarities do
		total += if rarity.Order == 1 then rarity.Weight else rarity.Weight * luck
	end
	local roll = rng:NextNumber() * total
	for _, rarity in Critters.Rarities do
		roll -= if rarity.Order == 1 then rarity.Weight else rarity.Weight * luck
		if roll <= 0 then
			return rarity
		end
	end
	return Critters.Rarities[1]
end

function Critters.RollCritter(luck: number, rng: Random): Critter
	local pool = Critters.OfRarity(Critters.RollRarity(luck, rng).Name)
	return pool[rng:NextInteger(1, #pool)]
end

function Critters.RollMutation(luck: number, rng: Random): string
	for _, mutation in Critters.Mutations do
		if mutation.Name ~= "Normal" and rng:NextNumber() < mutation.Chance * luck then
			return mutation.Name
		end
	end
	return "Normal"
end

-- Chance (0-1) of each rarity at a given luck, for showing odds in the Index.
function Critters.RarityChance(name: string, luck: number): number
	local total = 0
	local mine = 0
	for _, rarity in Critters.Rarities do
		local weight = if rarity.Order == 1 then rarity.Weight else rarity.Weight * luck
		total += weight
		if rarity.Name == name then
			mine = weight
		end
	end
	return mine / total
end

return Critters

--!strict
-- Spawns critters in the meadow and makes them wander. Rarer critters are
-- faster and leave sooner, which creates the "everyone chase the Mythic!" moments.
-- A critter freezes while someone is holding its Catch prompt, so catching is fair.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Critters = require(ReplicatedStorage.Shared.Critters)
local CritterFactory = require(script.Parent.CritterFactory)
local EventService = require(script.Parent.EventService)
local MapBuilder = require(script.Parent.MapBuilder)
local Notifier = require(script.Parent.Notifier)

export type Entry = {
	Model: Model,
	Id: string,
	Mut: string,
	Position: Vector3, -- ground position
	Target: Vector3,
	Facing: CFrame,
	Speed: number,
	Size: number,
	ExpiresAt: number,
	PauseUntil: number,
	HeldSince: number?,
	Prompt: ProximityPrompt?,
}

local Spawner = {}

local entries: { [Model]: Entry } = {}
local count = 0
local rng = Random.new()
local catchHandler: ((Player, Model) -> ())? = nil

local function randomMeadowPoint(): Vector3
	local r = math.sqrt(rng:NextNumber()) * (Config.MeadowRadius - 6)
	local a = rng:NextNumber() * math.pi * 2
	return Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

local function maxDistanceFor(rarity: Critters.Rarity): number
	return if rarity.Order >= 5 then 400 else 90
end

local function attachPrompt(entry: Entry)
	local def = assert(Critters.Get(entry.Id))
	local rarity = Critters.GetRarity(def.Rarity)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Catch"
	prompt.ObjectText = def.Name .. " (" .. rarity.Name .. ")"
	prompt.HoldDuration = rarity.CatchTime
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.PromptButtonHoldBegan:Connect(function()
		entry.HeldSince = os.clock()
	end)
	prompt.PromptButtonHoldEnded:Connect(function()
		entry.HeldSince = nil
	end)
	prompt.Triggered:Connect(function(player)
		if catchHandler then
			catchHandler(player, entry.Model)
		end
	end)
	prompt.Parent = entry.Model.PrimaryPart
	entry.Prompt = prompt
end

local function track(model: Model, id: string, mut: string, position: Vector3, lifetime: number)
	local def = assert(Critters.Get(id))
	local rarity = Critters.GetRarity(def.Rarity)
	local entry: Entry = {
		Model = model,
		Id = id,
		Mut = mut,
		Position = position,
		Target = randomMeadowPoint(),
		Facing = CFrame.new(),
		Speed = rarity.Speed,
		Size = def.Size,
		ExpiresAt = os.clock() + lifetime,
		PauseUntil = 0,
		HeldSince = nil,
		Prompt = nil,
	}
	model:PivotTo(CFrame.new(position + Vector3.new(0, def.Size / 2 + 0.4, 0)))
	model.Parent = MapBuilder.FieldFolder
	attachPrompt(entry)
	entries[model] = entry
	count += 1
end

function Spawner.SetCatchHandler(handler: (Player, Model) -> ())
	catchHandler = handler
end

function Spawner.Count(): number
	return count
end

-- Spawns a critter. Everything is rolled unless given (admin commands pass them in).
function Spawner.Spawn(forcedId: string?, forcedMutation: string?)
	local luck = EventService.GetLuck()
	local def = if forcedId then assert(Critters.Get(forcedId)) else Critters.RollCritter(luck, rng)
	local mut: string = forcedMutation or Critters.RollMutation(luck, rng)
	local rarity = Critters.GetRarity(def.Rarity)
	local model = CritterFactory.Build(def.Id, mut, maxDistanceFor(rarity))
	track(model, def.Id, mut, randomMeadowPoint(), rarity.Lifetime)

	local label = (if mut ~= "Normal" then mut .. " " else "") .. def.Name
	if rarity.Announce or mut == "Galaxy" or mut == "Rainbow" then
		Notifier.Announce(string.format("A %s %s appeared in the meadow!", string.upper(rarity.Name), label), rarity.Color)
	end
end

-- Removes a critter from the field so it can be carried. Returns nil if it's gone already.
function Spawner.Take(model: Model): Entry?
	local entry = entries[model]
	if not entry then
		return nil
	end
	entries[model] = nil
	count -= 1
	if entry.Prompt then
		entry.Prompt:Destroy()
		entry.Prompt = nil
	end
	return entry
end

-- Puts a dropped critter back in the field (it wanders back into the meadow).
function Spawner.Return(model: Model, id: string, mut: string, position: Vector3)
	local body = model.PrimaryPart
	if not body then
		model:Destroy()
		return
	end
	body.Anchored = true
	track(model, id, mut, Vector3.new(position.X, 0, position.Z), 45)
end

local function targetCount(): number
	local target = Config.BaseFieldCritters + #Players:GetPlayers() * Config.FieldCrittersPerPlayer
	if EventService.StormInfo() then
		target = math.floor(target * 1.5)
	end
	return math.min(target, Config.MaxFieldCritters)
end

local function step(dt: number)
	local clock = os.clock()
	for model, entry in entries do
		if clock >= entry.ExpiresAt or not model.Parent then
			entries[model] = nil
			count -= 1
			model:Destroy()
			continue
		end

		local held = entry.HeldSince ~= nil and clock - entry.HeldSince < 3
		if not held and clock >= entry.PauseUntil then
			local offset = entry.Target - entry.Position
			local distance = offset.Magnitude
			local move = entry.Speed * dt
			if distance <= move then
				entry.Position = entry.Target
				entry.Target = randomMeadowPoint()
				-- Common critters dawdle; rare ones barely stop.
				entry.PauseUntil = clock + rng:NextNumber(0.5, 3) * (6 / (entry.Speed + 2))
			else
				entry.Position += offset.Unit * move
				entry.Facing = CFrame.lookAt(Vector3.zero, Vector3.new(offset.X, 0, offset.Z))
			end
		end

		local moving = not held and clock >= entry.PauseUntil
		local hop = if moving then math.abs(math.sin(clock * entry.Speed * 1.2)) * 0.6 else 0
		local height = entry.Size / 2 + 0.4 + hop
		model:PivotTo(CFrame.new(entry.Position + Vector3.new(0, height, 0)) * entry.Facing)
	end
end

function Spawner.Init()
	for _ = 1, Config.BaseFieldCritters do
		Spawner.Spawn()
	end

	task.spawn(function()
		while true do
			local dt = task.wait(0.1)
			step(dt)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.SpawnInterval / EventService.GetSpawnMultiplier())
			if count < targetCount() then
				Spawner.Spawn()
			end
		end
	end)
end

return Spawner

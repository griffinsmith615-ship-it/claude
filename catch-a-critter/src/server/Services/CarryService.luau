--!strict
-- Catching, carrying critters home, and the Bonk Bat.
-- Carriers are slowed down and can be bonked by other players, which makes
-- them drop the critter back into the world for anyone to grab.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Critters = require(ReplicatedStorage.Shared.Critters)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Analytics = require(script.Parent.Analytics)
local DataService = require(script.Parent.DataService)
local Notifier = require(script.Parent.Notifier)
local PlotService = require(script.Parent.PlotService)
local Spawner = require(script.Parent.Spawner)

type Carry = {
	Model: Model,
	Id: string,
	Mut: string,
	Weld: WeldConstraint,
	FullWarnedAt: number,
}

local CarryService = {}

local carrying: { [Player]: Carry } = {}
local lastBonk: { [Player]: number } = {}

local celebrateEvent = Remotes.Event("Celebrate")
local knockbackEvent = Remotes.Event("Knockback")

local function getCharacter(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil, nil
	end
	return root, humanoid
end

local function critterLabel(id: string, mut: string): string
	local def = Critters.Get(id)
	local name = if def then def.Name else "critter"
	return if mut ~= "Normal" then mut .. " " .. name else name
end

function CarryService.IsCarrying(player: Player): boolean
	return carrying[player] ~= nil
end

function CarryService.UpdateSpeed(player: Player)
	local _, humanoid = getCharacter(player)
	if not humanoid then
		return
	end
	if carrying[player] then
		humanoid.WalkSpeed = if player:GetAttribute("Pass_SpeedyCarry") then Config.CarrySpeedWithPass else Config.CarrySpeed
	else
		humanoid.WalkSpeed = Config.WalkSpeed
	end
end

local function setCarryAttributes(player: Player, carry: Carry?)
	if carry then
		local def = Critters.Get(carry.Id)
		player:SetAttribute("Carrying", critterLabel(carry.Id, carry.Mut))
		player:SetAttribute("CarryingRarity", if def then def.Rarity else nil)
	else
		player:SetAttribute("Carrying", nil)
		player:SetAttribute("CarryingRarity", nil)
	end
end

function CarryService.TryPickup(player: Player, model: Model)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	if carrying[player] then
		Notifier.Notify(player, "You're already carrying a critter! Take it home first.")
		return
	end
	local root = getCharacter(player)
	if not root or (root.Position - model:GetPivot().Position).Magnitude > 18 then
		return
	end
	local body = model.PrimaryPart
	local entry = Spawner.Take(model)
	if not entry or not body then
		return
	end

	model:PivotTo(root.CFrame * CFrame.new(0, 3.3 + entry.Size / 2, 0))
	body.Anchored = false
	body.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = body
	weld.Parent = body
	model.Parent = player.Character

	local carry: Carry = { Model = model, Id = entry.Id, Mut = entry.Mut, Weld = weld, FullWarnedAt = 0 }
	carrying[player] = carry
	setCarryAttributes(player, carry)
	CarryService.UpdateSpeed(player)

	local def = assert(Critters.Get(entry.Id))
	local rarity = Critters.GetRarity(def.Rarity)
	profile.Caught += 1
	celebrateEvent:FireClient(player, rarity.Name, entry.Mut)
	Notifier.Notify(player, "You caught a " .. critterLabel(entry.Id, entry.Mut) .. "! Bring it home!", rarity.Color)
	if rarity.Order >= 5 or entry.Mut == "Galaxy" or entry.Mut == "Rainbow" then
		Notifier.Announce(string.format("%s caught a %s %s!", player.DisplayName, string.upper(rarity.Name), critterLabel(entry.Id, entry.Mut)), rarity.Color)
	end
	Analytics.Funnel(player, 2, "Caught first critter")
	Analytics.Custom(player, "Catch_" .. rarity.Name)
	if player:GetAttribute("TutorialStep") == 1 then
		player:SetAttribute("TutorialStep", 2)
	end
end

-- Drops whatever the player is carrying back into the world.
function CarryService.Drop(player: Player)
	local carry = carrying[player]
	if not carry then
		return
	end
	carrying[player] = nil
	carry.Weld:Destroy()
	local position = carry.Model:GetPivot().Position
	Spawner.Return(carry.Model, carry.Id, carry.Mut, position)
	setCarryAttributes(player, nil)
	CarryService.UpdateSpeed(player)
	if player:GetAttribute("TutorialStep") == 2 then
		player:SetAttribute("TutorialStep", 1)
	end
end

local function deliver(player: Player)
	local carry = carrying[player]
	local profile = DataService.Get(player)
	if not carry or not profile then
		return
	end
	local placed, isNew = PlotService.AddCritter(player, carry.Id, carry.Mut)
	if not placed then
		if os.clock() - carry.FullWarnedAt > 5 then
			carry.FullWarnedAt = os.clock()
			Notifier.Notify(player, "Your base is full! Sell a critter (hold E on it) or buy more slots in the Shop.", Color3.fromRGB(255, 120, 120))
		end
		return
	end
	carrying[player] = nil
	carry.Model:Destroy()
	setCarryAttributes(player, nil)
	CarryService.UpdateSpeed(player)

	Notifier.Notify(player, string.format("%s is home! +%s/s", critterLabel(carry.Id, carry.Mut), Format.Money(Critters.Income(carry.Id, carry.Mut))), Color3.fromRGB(120, 255, 120))
	if isNew then
		Notifier.Notify(player, "New critter discovered! +2% income forever (see Index)", Color3.fromRGB(255, 220, 90))
	end
	if not profile.TutorialDone then
		profile.TutorialDone = true
		Analytics.Funnel(player, 3, "Placed first critter")
	end
	player:SetAttribute("TutorialStep", 3)
end

local function swing(tool: Tool)
	local rest = CFrame.new(0, -1.3, 0)
	tool.Grip = rest * CFrame.Angles(math.rad(-80), 0, 0)
	task.delay(0.15, function()
		if tool.Parent then
			tool.Grip = rest
		end
	end)
end

local function onBonk(player: Player, tool: Tool)
	local clock = os.clock()
	if clock - (lastBonk[player] or 0) < Config.BonkCooldown then
		return
	end
	lastBonk[player] = clock
	swing(tool)

	local root = getCharacter(player)
	if not root then
		return
	end
	for other, carry in carrying do
		if other == player then
			continue
		end
		local otherRoot = getCharacter(other)
		if not otherRoot or (otherRoot.Position - root.Position).Magnitude > Config.BonkRange then
			continue
		end
		if PlotService.IsInOwnPlot(other) then
			continue -- safe at home
		end
		local label = critterLabel(carry.Id, carry.Mut)
		CarryService.Drop(other)
		local away = otherRoot.Position - root.Position
		local flat = Vector3.new(away.X, 0, away.Z)
		local direction = if flat.Magnitude > 0.01 then flat.Unit else Vector3.new(0, 0, 1)
		knockbackEvent:FireClient(other, direction * Config.BonkKnockback + Vector3.new(0, 30, 0))
		Notifier.Notify(other, player.DisplayName .. " bonked you! You dropped your " .. label .. "!", Color3.fromRGB(255, 120, 120))
		Notifier.Notify(player, "BONK! " .. other.DisplayName .. " dropped a " .. label .. "!", Color3.fromRGB(255, 200, 90))
		Analytics.Custom(player, "Bonk")
		break -- one bonk per swing
	end
end

local function giveBat(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or backpack:FindFirstChild("Bonk Bat") then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "Bonk Bat"
	tool.ToolTip = "Bonk players carrying critters to make them drop it!"
	tool.CanBeDropped = false
	tool.Grip = CFrame.new(0, -1.3, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 3.5, 0.5)
	handle.Color = Color3.fromRGB(200, 140, 80)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.one * 1.5
	head.Color = Color3.fromRGB(255, 110, 90)
	head.CanCollide = false
	head.Massless = true
	head.CFrame = handle.CFrame * CFrame.new(0, 1.9, 0)
	head.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = head
	weld.Parent = head

	tool.Activated:Connect(function()
		onBonk(player, tool)
	end)
	tool.Parent = backpack
end

function CarryService.OnCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	giveBat(player)
	CarryService.UpdateSpeed(player)
	humanoid.Died:Connect(function()
		CarryService.Drop(player)
	end)
end

function CarryService.OnPlayerAdded(player: Player)
	player.CharacterRemoving:Connect(function()
		CarryService.Drop(player)
	end)
end

function CarryService.Init()
	Spawner.SetCatchHandler(CarryService.TryPickup)

	Players.PlayerRemoving:Connect(function(player)
		CarryService.Drop(player)
		lastBonk[player] = nil
	end)

	-- Auto-deliver when a carrier steps onto their own base.
	task.spawn(function()
		while true do
			task.wait(0.2)
			for player in carrying do
				if PlotService.IsInOwnPlot(player) then
					deliver(player)
				end
			end
		end
	end)
end

return CarryService

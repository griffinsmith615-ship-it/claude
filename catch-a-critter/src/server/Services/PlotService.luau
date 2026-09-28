--!strict
-- Player bases: assigning plots, showing owned critters on pedestals, selling.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Critters = require(ReplicatedStorage.Shared.Critters)
local Format = require(ReplicatedStorage.Shared.Format)
local CritterFactory = require(script.Parent.CritterFactory)
local DataService = require(script.Parent.DataService)
local Economy = require(script.Parent.Economy)
local MapBuilder = require(script.Parent.MapBuilder)
local Notifier = require(script.Parent.Notifier)

type Plot = MapBuilder.Plot

local PlotService = {}

local ownerPlot: { [Player]: Plot } = {}

local LOCKED_COLOR = Color3.fromRGB(90, 90, 90)

function PlotService.Get(player: Player): Plot?
	return ownerPlot[player]
end

function PlotService.Assign(player: Player): boolean
	for _, plot in MapBuilder.Plots do
		if not plot.Owner then
			plot.Owner = player
			ownerPlot[player] = plot
			plot.SignLabel.Text = player.DisplayName .. "'s Critters"
			player:SetAttribute("PlotIndex", plot.Index)
			return true
		end
	end
	return false
end

function PlotService.Release(player: Player)
	local plot = ownerPlot[player]
	if not plot then
		return
	end
	ownerPlot[player] = nil
	plot.Owner = nil
	plot.SignLabel.Text = "Empty Plot"
	plot.CritterFolder:ClearAllChildren()
	for _, pedestal in plot.Pedestals do
		pedestal.Color = LOCKED_COLOR
		pedestal.Transparency = 0.6
		pedestal.Material = Enum.Material.SmoothPlastic
	end
end

function PlotService.UpdatePedestals(player: Player)
	local plot = ownerPlot[player]
	local profile = DataService.Get(player)
	if not plot or not profile then
		return
	end
	local slots = Economy.SlotCount(player, profile)
	for i, pedestal in plot.Pedestals do
		local unlocked = i <= slots
		pedestal.Color = if unlocked then plot.Color else LOCKED_COLOR
		pedestal.Transparency = if unlocked then 0 else 0.6
		pedestal.Material = if unlocked then Enum.Material.SmoothPlastic else Enum.Material.Glass
	end
end

local function placeModel(player: Player, plot: Plot, slot: number, entry: DataService.CritterEntry)
	local pedestal = plot.Pedestals[slot]
	local def = Critters.Get(entry.Id)
	if not pedestal or not def then
		return
	end
	local model = CritterFactory.Build(entry.Id, entry.Mut, 60)
	model.Name = "Slot" .. slot
	model:PivotTo(pedestal.CFrame * CFrame.new(0, 0.5 + def.Size / 2 + 0.1, 0))

	local sellValue = Critters.Income(entry.Id, entry.Mut) * Config.SellSeconds
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Sell"
	prompt.ObjectText = Format.Money(sellValue)
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OwnerUserId", player.UserId) -- the client hides other players' sell prompts
	prompt.Triggered:Connect(function(who)
		if who == player then
			PlotService.Sell(player, slot)
		end
	end)
	prompt.Parent = model.PrimaryPart
	model.Parent = plot.CritterFolder
end

function PlotService.Render(player: Player)
	local plot = ownerPlot[player]
	local profile = DataService.Get(player)
	if not plot or not profile then
		return
	end
	plot.CritterFolder:ClearAllChildren()
	for slot, entry in profile.Critters do
		placeModel(player, plot, slot, entry)
	end
	PlotService.UpdatePedestals(player)
end

-- Returns: placed, isNewDiscovery
function PlotService.AddCritter(player: Player, id: string, mut: string): (boolean, boolean)
	local profile = DataService.Get(player)
	local plot = ownerPlot[player]
	if not profile or not plot then
		return false, false
	end
	if #profile.Critters >= Economy.SlotCount(player, profile) then
		return false, false
	end
	local entry = { Id = id, Mut = mut }
	table.insert(profile.Critters, entry)
	local isNew = not profile.Index[id]
	profile.Index[id] = true
	placeModel(player, plot, #profile.Critters, entry)
	Economy.Refresh(player)
	return true, isNew
end

function PlotService.Sell(player: Player, slot: number)
	local profile = DataService.Get(player)
	if not profile then
		return
	end
	local entry = profile.Critters[slot]
	if not entry then
		return
	end
	local def = Critters.Get(entry.Id)
	local value = Critters.Income(entry.Id, entry.Mut) * Config.SellSeconds
	table.remove(profile.Critters, slot)
	PlotService.Render(player) -- slots shift down, so redraw
	Economy.Add(player, value, Enum.AnalyticsEconomyTransactionType.Gameplay, "SellCritter")
	Notifier.Notify(player, string.format("Sold %s for %s", if def then def.Name else "critter", Format.Money(value)))
end

function PlotService.IsInOwnPlot(player: Player): boolean
	local plot = ownerPlot[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not plot or not root or not root:IsA("BasePart") then
		return false
	end
	local offset = plot.CFrame:PointToObjectSpace(root.Position)
	return math.abs(offset.X) <= 22 and math.abs(offset.Z) <= 22 and offset.Y < 30
end

function PlotService.SpawnCFrame(player: Player): CFrame?
	local plot = ownerPlot[player]
	if not plot then
		return nil
	end
	return plot.CFrame * CFrame.new(0, 4, -17)
end

function PlotService.Init()
	Players.PlayerRemoving:Connect(PlotService.Release)
end

return PlotService

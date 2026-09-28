-- Modal panels: Shop, Rebirth, Daily, Codes, Index.
-- Each builder fills the panel once and returns an update function that
-- refreshes numbers when player attributes change.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Critters = require(ReplicatedStorage.Shared.Critters)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Theme)
local Toasts = require(script.Parent.Toasts)

local New = Theme.New
local Colors = Theme.Colors
local player = Players.LocalPlayer
local requestFunction = Remotes.Function("Request")

local Panels = {}

local modal: Frame
local titleLabel: TextLabel
local content: ScrollingFrame
local current: string? = nil
local updater: (() -> ())? = nil
local order = 0

local function attr(name: string): any
	return player:GetAttribute(name)
end

local function cash(): number
	return attr("Cash") or 0
end

local function today(): number
	return math.floor(Workspace:GetServerTimeNow()) // 86400
end

local function request(action: string, arg: any?)
	local ok, response = pcall(function()
		return requestFunction:InvokeServer(action, arg)
	end)
	if ok and type(response) == "table" then
		Toasts.Notify(response.Message, if response.Ok then Colors.Green else Colors.Red)
	end
	if updater then
		updater()
	end
end

local function nextOrder(): number
	order += 1
	return order
end

local function header(text: string)
	Theme.Label({
		Size = UDim2.new(1, -8, 0, 30),
		Text = text,
		TextColor3 = Colors.Cash,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = nextOrder(),
		Parent = content,
	})
end

type Row = { Frame: Frame, Button: TextButton, Title: TextLabel, Description: TextLabel }

local function row(title: string, description: string, buttonText: string, buttonColor: Color3, onClick: () -> ()): Row
	local frame = New("Frame", {
		Size = UDim2.new(1, -8, 0, 76),
		BackgroundColor3 = Colors.PanelLight,
		LayoutOrder = nextOrder(),
		Parent = content,
	}, { Theme.Corner(10) })
	local titleText = Theme.Label({
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(0.65, -12, 0, 30),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	local descriptionText = Theme.Label({
		Position = UDim2.fromOffset(12, 38),
		Size = UDim2.new(0.65, -12, 0, 32),
		Text = description,
		TextColor3 = Colors.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextScaled = false,
		TextSize = 15,
		TextWrapped = true,
		Parent = frame,
	})
	local button = Theme.Button(buttonText, buttonColor, onClick, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.33, 0, 0, 50),
		Parent = frame,
	})
	return { Frame = frame, Button = button, Title = titleText, Description = descriptionText }
end

local function fetchPrice(button: TextButton, id: number, infoType: Enum.InfoType)
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(id, infoType)
		end)
		if ok and info and info.PriceInRobux and button.Parent then
			if button.Text == "..." then
				button.Text = "R$ " .. tostring(info.PriceInRobux)
			end
		end
	end)
end

-- Shop ------------------------------------------------------------------------

local function buildShop(): () -> ()
	header("Base Upgrades")
	local slotRow = row("+1 Base Slot", "Room for one more critter.", "", Colors.Green, function()
		request("BuySlot")
	end)

	header("Passes (forever)")
	local passButtons: { { Item: Config.ShopItem, Button: TextButton } } = {}
	for _, pass in Config.GamePasses do
		local r = row(pass.Name, pass.Description, if pass.Id == 0 then "Soon" else "...", Colors.Blue, function()
			if pass.Id ~= 0 and not attr("Pass_" .. pass.Key) then
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end
		end)
		if pass.Id ~= 0 then
			fetchPrice(r.Button, pass.Id, Enum.InfoType.GamePass)
		end
		table.insert(passButtons, { Item = pass, Button = r.Button })
	end

	header("Boosts")
	for _, product in Config.Products do
		local r = row(product.Name, product.Description, if product.Id == 0 then "Soon" else "...", Colors.Purple, function()
			if product.Id ~= 0 then
				MarketplaceService:PromptProductPurchase(player, product.Id)
			end
		end)
		if product.Id ~= 0 then
			fetchPrice(r.Button, product.Id, Enum.InfoType.Product)
		end
	end

	return function()
		local bought = attr("BoughtSlots") or 0
		if bought >= Config.MaxBoughtSlots then
			slotRow.Button.Text = "MAX"
			slotRow.Button.BackgroundColor3 = Colors.Gray
		else
			local cost = Config.SlotCost(bought)
			slotRow.Button.Text = Format.Money(cost)
			slotRow.Button.BackgroundColor3 = if cash() >= cost then Colors.Green else Colors.Gray
		end
		slotRow.Description.Text = string.format("Room for one more critter. (%d/%d used)", attr("UsedSlots") or 0, attr("Slots") or Config.StartSlots)
		for _, info in passButtons do
			if attr("Pass_" .. info.Item.Key) then
				info.Button.Text = "Owned"
				info.Button.BackgroundColor3 = Colors.Gray
			end
		end
	end
end

-- Rebirth ---------------------------------------------------------------------

local function buildRebirth(): () -> ()
	local info = Theme.Label({
		Size = UDim2.new(1, -8, 0, 110),
		TextScaled = false,
		TextSize = 22,
		TextWrapped = true,
		LayoutOrder = nextOrder(),
		Parent = content,
	})
	local bar = New("Frame", {
		Size = UDim2.new(1, -8, 0, 26),
		BackgroundColor3 = Colors.PanelLight,
		LayoutOrder = nextOrder(),
		Parent = content,
	}, { Theme.Corner(13) })
	local fill = New("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Colors.Cash, Parent = bar }, { Theme.Corner(13) })
	local barText = Theme.Label({ Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = bar })
	local holder = New("Frame", {
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Parent = content,
	})
	local button = Theme.Button("REBIRTH", Colors.Purple, function()
		request("Rebirth")
	end, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.6, 0, 0, 56),
		Parent = holder,
	})

	return function()
		local rebirths = attr("Rebirths") or 0
		local cost = Config.RebirthCost(rebirths)
		info.Text = string.format(
			"Rebirth %d  ->  %d\nIncome boost: x%.1f  ->  x%.1f\nYour cash resets, but your critters stay!",
			rebirths,
			rebirths + 1,
			1 + rebirths * Config.RebirthIncomeBonus,
			1 + (rebirths + 1) * Config.RebirthIncomeBonus
		)
		local progress = math.clamp(cash() / cost, 0, 1)
		fill.Size = UDim2.fromScale(progress, 1)
		barText.Text = Format.Money(cash()) .. " / " .. Format.Money(cost)
		button.BackgroundColor3 = if progress >= 1 then Colors.Purple else Colors.Gray
	end
end

-- Daily -----------------------------------------------------------------------

local function nextDailyIndex(): (number, boolean)
	local lastDay = attr("DailyDay") or 0
	local streak = attr("DailyStreak") or 0
	local count = #Config.DailyRewards
	if lastDay == today() then
		return (streak - 1) % count + 1, false -- already claimed; show today's tile
	elseif lastDay == today() - 1 then
		return streak % count + 1, true
	end
	return 1, true
end

local function buildDaily(): () -> ()
	local grid = New("Frame", {
		Size = UDim2.new(1, -8, 0, 190),
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Parent = content,
	}, {
		New("UIGridLayout", {
			CellSize = UDim2.new(0.23, 0, 0, 88),
			CellPadding = UDim2.fromOffset(8, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local tiles = {}
	for day, reward in Config.DailyRewards do
		local tile = New("Frame", { BackgroundColor3 = Colors.PanelLight, LayoutOrder = day, Parent = grid }, { Theme.Corner(10) })
		Theme.Label({ Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0.4, 0), Text = "Day " .. day, Parent = tile })
		Theme.Label({
			Position = UDim2.new(0, 4, 0.45, 0),
			Size = UDim2.new(1, -8, 0.5, 0),
			Text = if reward.Legendary then "Cash +\nLegendary!" else "Cash",
			TextColor3 = if reward.Legendary then Colors.Cash else Colors.Green,
			Parent = tile,
		})
		tiles[day] = tile
	end
	local status = Theme.Label({ Size = UDim2.new(1, -8, 0, 30), LayoutOrder = nextOrder(), Parent = content })
	local holder = New("Frame", { Size = UDim2.new(1, -8, 0, 64), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = content })
	local button = Theme.Button("CLAIM", Colors.Green, function()
		request("ClaimDaily")
	end, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.6, 0, 0, 56),
		Parent = holder,
	})

	return function()
		local index, ready = nextDailyIndex()
		for day, tile in tiles do
			tile.BackgroundColor3 = if day == index then (if ready then Colors.Green else Colors.Blue) else Colors.PanelLight
		end
		if ready then
			status.Text = "Your reward is ready!"
			button.BackgroundColor3 = Colors.Green
			button.Text = "CLAIM"
		else
			local secondsLeft = (today() + 1) * 86400 - Workspace:GetServerTimeNow()
			status.Text = "Next reward in " .. Format.Time(secondsLeft)
			button.BackgroundColor3 = Colors.Gray
			button.Text = "CLAIMED"
		end
	end
end

-- Codes -----------------------------------------------------------------------

local function buildCodes(): () -> ()
	Theme.Label({
		Size = UDim2.new(1, -8, 0, 50),
		Text = "New codes drop with every update and at like milestones!",
		TextScaled = false,
		TextSize = 18,
		TextWrapped = true,
		TextColor3 = Colors.Muted,
		LayoutOrder = nextOrder(),
		Parent = content,
	})
	local box = New("TextBox", {
		Size = UDim2.new(1, -8, 0, 56),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Font = Theme.Font,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(30, 30, 40),
		PlaceholderText = "Enter code",
		Text = "",
		ClearTextOnFocus = false,
		LayoutOrder = nextOrder(),
		Parent = content,
	}, { Theme.Corner(10), Theme.Stroke(2) })
	local holder = New("Frame", { Size = UDim2.new(1, -8, 0, 64), BackgroundTransparency = 1, LayoutOrder = nextOrder(), Parent = content })
	Theme.Button("REDEEM", Colors.Green, function()
		request("Redeem", box.Text)
	end, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.6, 0, 0, 56),
		Parent = holder,
	})
	return function() end
end

-- Index -----------------------------------------------------------------------

local function currentLuck(): number
	local luck = 1
	if Workspace:GetAttribute("StormActive") then
		luck *= Config.StormLuck
	end
	if (Workspace:GetAttribute("ServerLuckEndsAt") or 0) > Workspace:GetServerTimeNow() then
		luck *= Config.ServerLuckMultiplier
	end
	return luck
end

local function buildIndex(): () -> ()
	local summary = Theme.Label({ Size = UDim2.new(1, -8, 0, 32), LayoutOrder = nextOrder(), Parent = content })
	local grid = New("Frame", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = nextOrder(),
		Parent = content,
	}, {
		New("UIGridLayout", {
			CellSize = UDim2.new(0.31, 0, 0, 58),
			CellPadding = UDim2.fromOffset(6, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	local tiles: { [string]: TextLabel } = {}
	for i, def in Critters.List do
		local rarity = Critters.GetRarity(def.Rarity)
		local tile = New("Frame", { BackgroundColor3 = Colors.PanelLight, LayoutOrder = i, Parent = grid }, { Theme.Corner(8), Theme.Stroke(2, rarity.Color) })
		tiles[def.Id] = Theme.Label({ Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), Parent = tile })
	end

	header("Odds right now (every spawn)")
	local oddsLabels: { [string]: TextLabel } = {}
	for _, rarity in Critters.Rarities do
		oddsLabels[rarity.Name] = Theme.Label({
			Size = UDim2.new(1, -8, 0, 24),
			TextColor3 = rarity.Color,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = nextOrder(),
			Parent = content,
		})
	end

	return function()
		local found = {}
		for _, id in string.split(attr("Index") or "", ",") do
			found[id] = true
		end
		local count = 0
		for _, def in Critters.List do
			local rarity = Critters.GetRarity(def.Rarity)
			local label = tiles[def.Id]
			if found[def.Id] then
				count += 1
				label.Text = def.Name .. "\n" .. Format.Money(def.Income) .. "/s"
				label.TextColor3 = rarity.Color
			else
				label.Text = "???\n" .. rarity.Name
				label.TextColor3 = Colors.Muted
			end
		end
		summary.Text = string.format("Discovered %d/%d  (+%d%% income)", count, #Critters.List, math.floor(count * Config.IndexBonusPerCritter * 100 + 0.5))
		local luck = currentLuck()
		for _, rarity in Critters.Rarities do
			oddsLabels[rarity.Name].Text = string.format("%s: %s", rarity.Name, Format.Percent(Critters.RarityChance(rarity.Name, luck)))
		end
	end
end

-- Panel shell -----------------------------------------------------------------

local builders: { [string]: () -> () -> () } = {
	Shop = buildShop,
	Rebirth = buildRebirth,
	Daily = buildDaily,
	Codes = buildCodes,
	Index = buildIndex,
}

function Panels.Init(gui: ScreenGui)
	modal = New("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.6, 0.72),
		BackgroundColor3 = Colors.Panel,
		Visible = false,
		ZIndex = 3,
		Parent = gui,
	}, {
		Theme.Corner(16),
		Theme.Stroke(3),
		New("UISizeConstraint", { MaxSize = Vector2.new(620, 520), MinSize = Vector2.new(330, 280) }),
	})
	titleLabel = Theme.Label({
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -90, 0, 44),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Colors.Cash,
		Parent = modal,
	})
	Theme.Button("X", Colors.Red, function()
		Panels.Close()
	end, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(44, 44),
		Parent = modal,
	})
	content = New("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 60),
		Size = UDim2.new(1, -24, 1, -72),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Parent = modal,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		New("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8) }),
	})
end

function Panels.Close()
	current = nil
	updater = nil
	modal.Visible = false
end

function Panels.Toggle(name: string)
	if current == name then
		Panels.Close()
		return
	end
	for _, child in content:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	order = 0
	current = name
	titleLabel.Text = name
	content.CanvasPosition = Vector2.zero
	updater = builders[name]()
	modal.Visible = true
	Panels.Update()
end

function Panels.Update()
	if updater then
		updater()
	end
end

function Panels.DailyReady(): boolean
	local _, ready = nextDailyIndex()
	return ready
end

return Panels

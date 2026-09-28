-- Always-on HUD: cash and income, event timers, menu buttons, base capacity,
-- and what you're carrying.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)
local Critters = require(ReplicatedStorage.Shared.Critters)
local Format = require(ReplicatedStorage.Shared.Format)
local Panels = require(script.Parent.Panels)
local Theme = require(script.Parent.Theme)

local New = Theme.New
local Colors = Theme.Colors
local player = Players.LocalPlayer

local Hud = {}

function Hud.Init(gui: ScreenGui)
	-- Cash --------------------------------------------------------------------
	local cashFrame = New("Frame", {
		Name = "Cash",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(290, 74),
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, { Theme.Corner(14), Theme.Stroke(2) })
	local pop = New("UIScale", { Parent = cashFrame })
	local cashLabel = Theme.Label({
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -20, 0, 42),
		Text = "$0",
		TextColor3 = Colors.Cash,
		Parent = cashFrame,
	})
	local incomeLabel = Theme.Label({
		Position = UDim2.fromOffset(10, 46),
		Size = UDim2.new(1, -20, 0, 24),
		Text = "+$0/s",
		TextColor3 = Colors.Green,
		Parent = cashFrame,
	})

	-- Event timers (top right) ---------------------------------------------------
	local events = New("Frame", {
		Name = "Events",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 58),
		Size = UDim2.fromOffset(250, 130),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function pill(order: number, color: Color3): (TextLabel, Frame)
		local frame = New("Frame", {
			Size = UDim2.fromOffset(250, 36),
			BackgroundColor3 = color,
			BackgroundTransparency = 0.1,
			LayoutOrder = order,
			Parent = events,
		}, { Theme.Corner(18), Theme.Stroke(2) })
		return Theme.Label({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 1, -8), Parent = frame }), frame
	end
	local stormPill = pill(1, Color3.fromRGB(110, 70, 180))
	local luckPill, luckFrame = pill(2, Color3.fromRGB(50, 160, 80))
	local weekendPill, weekendFrame = pill(3, Color3.fromRGB(200, 140, 30))
	weekendPill.Text = "Weekend: 2x Cash!"

	-- Menu buttons (left) ---------------------------------------------------------
	local menu = New("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(84, 440),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		New("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local dailyDot: Frame
	local buttons = {
		{ Name = "Shop", Color = Colors.Green },
		{ Name = "Rebirth", Color = Colors.Purple },
		{ Name = "Daily", Color = Colors.Blue },
		{ Name = "Codes", Color = Color3.fromRGB(230, 120, 60) },
		{ Name = "Index", Color = Color3.fromRGB(60, 170, 190) },
	}
	for i, info in buttons do
		local button = Theme.Button(info.Name, info.Color, function()
			Panels.Toggle(info.Name)
		end, { Size = UDim2.fromOffset(84, 70), LayoutOrder = i, Parent = menu })
		if info.Name == "Daily" then
			dailyDot = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, -2, 0, 2),
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = Colors.Red,
				Visible = false,
				ZIndex = 2,
				Parent = button,
			}, { Theme.Corner(9), Theme.Stroke(2) })
		end
	end

	-- Base capacity (bottom right) ------------------------------------------------
	local baseLabel = Theme.Label({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -96),
		Size = UDim2.fromOffset(240, 32),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = gui,
	})

	-- Carrying banner (bottom centre) -----------------------------------------------
	local carryLabel = Theme.Label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -150),
		Size = UDim2.fromOffset(520, 38),
		Visible = false,
		Parent = gui,
	})

	-- Updates ---------------------------------------------------------------------
	local lastCash = 0
	local function updateStats()
		local cash = player:GetAttribute("Cash") or 0
		local income = player:GetAttribute("Income") or 0
		cashLabel.Text = Format.Money(cash)
		incomeLabel.Text = "+" .. Format.Money(income) .. "/s"
		-- Bounce the cash counter on big gains (sales, rewards), not every tick.
		if cash - lastCash > math.max(income * 1.5, 10) then
			pop.Scale = 1.12
			TweenService:Create(pop, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
		lastCash = cash

		local used = player:GetAttribute("UsedSlots") or 0
		local slots = player:GetAttribute("Slots") or Config.StartSlots
		baseLabel.Text = string.format("Base: %d/%d critters", used, slots)
		baseLabel.TextColor3 = if used >= slots then Colors.Red else Colors.Text

		local carrying = player:GetAttribute("Carrying")
		carryLabel.Visible = carrying ~= nil
		if carrying then
			local rarity = Critters.GetRarity(player:GetAttribute("CarryingRarity") or "Common")
			carryLabel.Text = "Carrying " .. carrying .. ": take it home!"
			carryLabel.TextColor3 = rarity.Color
		end
	end
	player.AttributeChanged:Connect(updateStats)
	updateStats()

	task.spawn(function()
		while true do
			local now = Workspace:GetServerTimeNow()
			if Workspace:GetAttribute("StormActive") then
				stormPill.Text = "STORM! " .. Config.StormLuck .. "x luck " .. Format.Time((Workspace:GetAttribute("StormEndsAt") or now) - now)
			else
				stormPill.Text = "Critter Storm in " .. Format.Time((Workspace:GetAttribute("NextStormAt") or now) - now)
			end
			local luckLeft = (Workspace:GetAttribute("ServerLuckEndsAt") or 0) - now
			luckFrame.Visible = luckLeft > 0
			luckPill.Text = "Server Luck x" .. Config.ServerLuckMultiplier .. " " .. Format.Time(luckLeft)
			weekendFrame.Visible = Workspace:GetAttribute("WeekendActive") == true
			dailyDot.Visible = player:GetAttribute("Loaded") == true and Panels.DailyReady()
			Panels.Update() -- keeps countdowns in open panels ticking
			task.wait(0.5)
		end
	end)
end

return Hud

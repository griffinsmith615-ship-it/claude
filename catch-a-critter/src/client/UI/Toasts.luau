-- Small notifications, big server-wide banners, modal popups, and screen flashes.

local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local New = Theme.New
local Colors = Theme.Colors

local Toasts = {}

local holder: Frame
local banner: TextLabel
local popup: Frame
local popupTitle: TextLabel
local popupBody: TextLabel
local flash: Frame

local bannerQueue: { { Text: string, Color: Color3 } } = {}
local bannerBusy = false

function Toasts.Init(gui: ScreenGui)
	holder = New("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 118),
		Size = UDim2.fromOffset(460, 220),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, 4),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	banner = Theme.Label({
		Name = "Banner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.new(0.9, 0, 0, 58),
		Visible = false,
		ZIndex = 5,
		Parent = gui,
	})

	flash = New("Frame", {
		Name = "Flash",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = gui,
	})

	popup = New("Frame", {
		Name = "Popup",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 250),
		BackgroundColor3 = Colors.Panel,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	}, { Theme.Corner(16), Theme.Stroke(3) })
	popupTitle = Theme.Label({
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -32, 0, 48),
		TextColor3 = Colors.Cash,
		ZIndex = 11,
		Parent = popup,
	})
	popupBody = Theme.Label({
		Position = UDim2.fromOffset(20, 68),
		Size = UDim2.new(1, -40, 0, 100),
		TextScaled = false,
		TextSize = 22,
		TextWrapped = true,
		ZIndex = 11,
		Parent = popup,
	})
	Theme.Button("Awesome!", Colors.Green, function()
		popup.Visible = false
	end, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(200, 52),
		ZIndex = 11,
		Parent = popup,
	})
end

function Toasts.Notify(text: string, color: Color3?)
	local toast = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = Colors.Panel,
		BackgroundTransparency = 0.2,
		Font = Theme.Font,
		TextScaled = true,
		TextColor3 = color or Colors.Text,
		Text = text,
		LayoutOrder = math.floor(os.clock() * 1000),
		Parent = holder,
	}, {
		Theme.Corner(8),
		New("UIStroke", { Thickness = 1.5 }),
		New("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }),
	})

	local toasts = {}
	for _, child in holder:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(toasts, child)
		end
	end
	if #toasts > 4 then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end

	task.delay(3.5, function()
		if toast.Parent then
			local fade = TweenInfo.new(0.4)
			TweenService:Create(toast, fade, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			task.wait(0.4)
			toast:Destroy()
		end
	end)
end

local function showNextBanner()
	if bannerBusy or #bannerQueue == 0 then
		return
	end
	bannerBusy = true
	local item = table.remove(bannerQueue, 1)
	banner.Text = item.Text
	banner.TextColor3 = item.Color
	banner.TextTransparency = 1
	banner.Size = UDim2.new(0.6, 0, 0, 40)
	banner.Visible = true
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), { TextTransparency = 0, Size = UDim2.new(0.9, 0, 0, 58) }):Play()
	task.delay(3.2, function()
		TweenService:Create(banner, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		task.wait(0.3)
		banner.Visible = false
		bannerBusy = false
		showNextBanner()
	end)
end

function Toasts.Announce(text: string, color: Color3?)
	table.insert(bannerQueue, { Text = text, Color = color or Colors.Cash })
	while #bannerQueue > 3 do
		table.remove(bannerQueue, 1)
	end
	showNextBanner()
end

function Toasts.Popup(title: string, body: string)
	popupTitle.Text = title
	popupBody.Text = body
	popup.Visible = true
end

function Toasts.Flash(color: Color3)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.5
	TweenService:Create(flash, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
end

return Toasts

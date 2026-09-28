-- Shared look and UI helpers. Sized for phones first (~80% of Roblox play is on mobile).

local Workspace = game:GetService("Workspace")

local Theme = {}

Theme.Font = Enum.Font.FredokaOne
Theme.Colors = {
	Panel = Color3.fromRGB(34, 38, 58),
	PanelLight = Color3.fromRGB(52, 58, 88),
	Text = Color3.new(1, 1, 1),
	Muted = Color3.fromRGB(180, 185, 210),
	Cash = Color3.fromRGB(255, 214, 70),
	Green = Color3.fromRGB(80, 210, 100),
	Red = Color3.fromRGB(235, 80, 80),
	Blue = Color3.fromRGB(70, 150, 255),
	Purple = Color3.fromRGB(170, 100, 255),
	Gray = Color3.fromRGB(110, 115, 135),
}

function Theme.New(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				(instance :: any)[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

function Theme.Corner(radius: number?): UICorner
	return Theme.New("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function Theme.Stroke(thickness: number?, color: Color3?): UIStroke
	return Theme.New("UIStroke", {
		Thickness = thickness or 2,
		Color = color or Color3.new(0, 0, 0),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.Label(props: { [string]: any }): TextLabel
	local label = Theme.New("TextLabel", {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextScaled = true,
		TextColor3 = Theme.Colors.Text,
		Text = "",
	})
	for key, value in props do
		if key ~= "Parent" then
			label[key] = value
		end
	end
	Theme.New("UIStroke", { Thickness = 2, Parent = label })
	label.Parent = props.Parent
	return label
end

function Theme.Button(text: string, color: Color3, onClick: () -> (), props: { [string]: any }?): TextButton
	local button = Theme.New("TextButton", {
		BackgroundColor3 = color,
		Font = Theme.Font,
		TextScaled = true,
		TextColor3 = Theme.Colors.Text,
		Text = text,
		AutoButtonColor = true,
	}, {
		Theme.Corner(10),
		Theme.Stroke(2),
		Theme.New("UIPadding", {
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
	})
	local textStroke = Theme.New("UIStroke", { Thickness = 1.5 })
	textStroke.Parent = button
	if props then
		for key, value in props do
			if key ~= "Parent" then
				button[key] = value
			end
		end
	end
	button.Activated:Connect(onClick)
	if props and props.Parent then
		button.Parent = props.Parent
	end
	return button
end

-- Scales the whole UI to the screen so it's readable on phones and not huge on PC.
function Theme.AttachScale(gui: ScreenGui)
	local scale = Theme.New("UIScale", { Parent = gui })
	local function update()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local viewport = camera.ViewportSize
		scale.Scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720) * 1.05, 0.62, 1.2)
	end
	update()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(update)
	if Workspace.CurrentCamera then
		Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	end
end

return Theme

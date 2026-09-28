-- Builds the whole map in code: a meadow in the middle where critters spawn,
-- ringed by 8 player bases. No uploaded assets needed.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Shared.Config)

export type Plot = {
	Index: number,
	CFrame: CFrame, -- centre of the plot floor; -Z (LookVector) faces the meadow
	Folder: Folder,
	CritterFolder: Folder,
	Floor: BasePart,
	SignLabel: TextLabel,
	Pedestals: { BasePart },
	Color: Color3,
	Owner: Player?,
}

local MapBuilder = {}
MapBuilder.Plots = {} :: { Plot }
MapBuilder.FieldFolder = (nil :: any) :: Folder

local PLOT_SIZE = 44
local PLOT_COLORS = {
	Color3.fromRGB(255, 110, 110),
	Color3.fromRGB(255, 170, 70),
	Color3.fromRGB(255, 225, 80),
	Color3.fromRGB(110, 215, 110),
	Color3.fromRGB(80, 200, 220),
	Color3.fromRGB(90, 140, 255),
	Color3.fromRGB(170, 110, 255),
	Color3.fromRGB(255, 120, 200),
}

local rng = Random.new(1234) -- fixed seed so decorations are the same every server

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

local function buildTree(parent: Instance, position: Vector3)
	local height = rng:NextNumber(8, 13)
	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, 2, 2),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(120, 85, 55),
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	local leafColor = Color3.fromHSV(rng:NextNumber(0.25, 0.36), 0.6, rng:NextNumber(0.6, 0.8))
	for i = 1, 3 do
		local size = rng:NextNumber(6, 9)
		part({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * size,
			CFrame = CFrame.new(position + Vector3.new(rng:NextNumber(-2, 2), height + i * 1.5, rng:NextNumber(-2, 2))),
			Color = leafColor,
			Material = Enum.Material.Grass,
			CanCollide = false,
			Parent = parent,
		})
	end
end

local function buildPlot(index: number, plotsFolder: Folder): Plot
	local angle = (index - 1) / Config.MaxPlots * math.pi * 2
	local center = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Config.PlotRingRadius
	local cf = CFrame.lookAt(center, Vector3.zero)
	local color = PLOT_COLORS[(index - 1) % #PLOT_COLORS + 1]

	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index

	local floor = part({
		Name = "Floor",
		Size = Vector3.new(PLOT_SIZE, 1, PLOT_SIZE),
		CFrame = cf * CFrame.new(0, 0.5, 0),
		Color = color:Lerp(Color3.new(1, 1, 1), 0.55),
		Parent = folder,
	})

	-- Low rails on the sides and back; the front (facing the meadow) stays open.
	local railColor = color:Lerp(Color3.new(0, 0, 0), 0.15)
	local half = PLOT_SIZE / 2
	for _, offset in { CFrame.new(-half, 2, 0), CFrame.new(half, 2, 0) } do
		part({ Name = "Rail", Size = Vector3.new(1, 3, PLOT_SIZE), CFrame = cf * offset, Color = railColor, Parent = folder })
	end
	part({ Name = "Rail", Size = Vector3.new(PLOT_SIZE, 3, 1), CFrame = cf * CFrame.new(0, 2, half), Color = railColor, Parent = folder })

	-- Sign on posts at the back, facing the meadow.
	for _, x in { -12, 12 } do
		part({ Name = "Post", Size = Vector3.new(1, 12, 1), CFrame = cf * CFrame.new(x, 6, half - 1), Color = railColor, Parent = folder })
	end
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(28, 6, 1),
		CFrame = cf * CFrame.new(0, 11, half - 1),
		Color = color,
		Parent = folder,
	})
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 30
	surface.LightInfluence = 0
	surface.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = "Empty Plot"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Parent = label
	label.Parent = surface

	-- 24 pedestals: 6 columns x 4 rows, front row first.
	local pedestals = {}
	for row = 0, 3 do
		for col = 0, 5 do
			local pedestal = part({
				Name = "Pedestal",
				Size = Vector3.new(4.5, 1, 4.5),
				CFrame = cf * CFrame.new(-15 + col * 6, 1.5, -3 + row * 6.5),
				Color = Color3.fromRGB(90, 90, 90),
				Transparency = 0.6,
				Parent = folder,
			})
			table.insert(pedestals, pedestal)
		end
	end

	local critterFolder = Instance.new("Folder")
	critterFolder.Name = "Critters"
	critterFolder.Parent = folder
	folder.Parent = plotsFolder

	return {
		Index = index,
		CFrame = cf,
		Folder = folder,
		CritterFolder = critterFolder,
		Floor = floor,
		SignLabel = label,
		Pedestals = pedestals,
		Color = color,
		Owner = nil,
	}
end

function MapBuilder.Build()
	-- The default Baseplate template's parts would overlap the map.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local existing = Workspace:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end

	local map = Instance.new("Folder")
	map.Name = "Map"

	local groundSize = (Config.PlotRingRadius + 60) * 2
	part({
		Name = "Ground",
		Size = Vector3.new(groundSize, 4, groundSize),
		CFrame = CFrame.new(0, -2, 0),
		Color = Color3.fromRGB(105, 185, 85),
		Material = Enum.Material.Grass,
		Parent = map,
	})

	part({
		Name = "Meadow",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, Config.MeadowRadius * 2, Config.MeadowRadius * 2),
		CFrame = CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 215, 95),
		Material = Enum.Material.Grass,
		Parent = map,
	})

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = map

	-- Flowers in the meadow
	local flowerColors = {
		Color3.fromRGB(255, 120, 160),
		Color3.fromRGB(255, 230, 90),
		Color3.fromRGB(160, 130, 255),
		Color3.new(1, 1, 1),
	}
	for _ = 1, 90 do
		local r = math.sqrt(rng:NextNumber()) * (Config.MeadowRadius - 2)
		local a = rng:NextNumber() * math.pi * 2
		part({
			Name = "Flower",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.9,
			CFrame = CFrame.new(math.cos(a) * r, 0.6, math.sin(a) * r),
			Color = flowerColors[rng:NextInteger(1, #flowerColors)],
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Parent = decor,
		})
	end

	-- Trees between the plots and around the edge
	for i = 1, Config.MaxPlots do
		local angle = (i - 0.5) / Config.MaxPlots * math.pi * 2
		buildTree(decor, Vector3.new(math.cos(angle), 0, math.sin(angle)) * Config.PlotRingRadius)
		buildTree(decor, Vector3.new(math.cos(angle), 0, math.sin(angle)) * (Config.MeadowRadius + 14))
	end
	for i = 1, 24 do
		local angle = i / 24 * math.pi * 2
		buildTree(decor, Vector3.new(math.cos(angle), 0, math.sin(angle)) * (Config.PlotRingRadius + 42))
	end

	-- Invisible walls so nobody walks off the world
	local half = groundSize / 2
	for _, info in {
		{ Vector3.new(half, 40, 0), Vector3.new(2, 80, groundSize) },
		{ Vector3.new(-half, 40, 0), Vector3.new(2, 80, groundSize) },
		{ Vector3.new(0, 40, half), Vector3.new(groundSize, 80, 2) },
		{ Vector3.new(0, 40, -half), Vector3.new(groundSize, 80, 2) },
	} do
		part({ Name = "Wall", Size = info[2], CFrame = CFrame.new(info[1]), Transparency = 1, Parent = map })
	end

	-- Fallback spawn in the meadow; players are moved to their base on spawn.
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.5, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = map
	for index = 1, Config.MaxPlots do
		table.insert(MapBuilder.Plots, buildPlot(index, plotsFolder))
	end

	local field = Instance.new("Folder")
	field.Name = "FieldCritters"
	field.Parent = map
	MapBuilder.FieldFolder = field

	map.Parent = Workspace

	-- Bright, friendly lighting
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 160)
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.25
		atmosphere.Haze = 0.5
		atmosphere.Parent = Lighting
	end
end

return MapBuilder

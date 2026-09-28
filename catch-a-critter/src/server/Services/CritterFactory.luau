--!strict
-- Builds critter models out of simple parts: a round body, big eyes, and a
-- feature (ears, wings, horns...). Rarity and mutation add glow and effects.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Critters = require(ReplicatedStorage.Shared.Critters)
local Format = require(ReplicatedStorage.Shared.Format)

local CritterFactory = {}

local function addPart(model: Model, body: BasePart, shape: Enum.PartType, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CFrame = body.CFrame * offset
	p.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = p
	weld.Parent = p
	return p
end

local function addFeature(model: Model, body: BasePart, def: Critters.Critter, accentMaterial: Enum.Material)
	local s = def.Size
	local accent = def.Accent
	local block = Enum.PartType.Block
	local ball = Enum.PartType.Ball
	if def.Feature == "Ears" then
		for _, side in { -1, 1 } do
			addPart(model, body, block, Vector3.new(0.28, 0.4, 0.14) * s, CFrame.new(side * s * 0.28, s * 0.48, 0) * CFrame.Angles(0, 0, -side * 0.35), accent, accentMaterial)
		end
	elseif def.Feature == "Antennae" then
		for _, side in { -1, 1 } do
			addPart(model, body, block, Vector3.new(0.07, 0.45, 0.07) * s, CFrame.new(side * s * 0.18, s * 0.62, -s * 0.1) * CFrame.Angles(0, 0, -side * 0.3), accent, accentMaterial)
			addPart(model, body, ball, Vector3.one * 0.16 * s, CFrame.new(side * s * 0.25, s * 0.85, -s * 0.1), accent, accentMaterial)
		end
	elseif def.Feature == "Wings" then
		for _, side in { -1, 1 } do
			addPart(model, body, block, Vector3.new(0.05, 0.55, 0.7) * s, CFrame.new(side * s * 0.55, s * 0.2, s * 0.1) * CFrame.Angles(0, 0, -side * 0.6), accent, Enum.Material.Neon).Transparency = 0.3
		end
	elseif def.Feature == "Horns" then
		for _, side in { -1, 1 } do
			addPart(model, body, block, Vector3.new(0.12, 0.4, 0.12) * s, CFrame.new(side * s * 0.22, s * 0.55, -s * 0.12) * CFrame.Angles(-0.3, 0, -side * 0.25), accent, accentMaterial)
		end
	elseif def.Feature == "Cap" then
		addPart(model, body, Enum.PartType.Cylinder, Vector3.new(0.3, 1.35, 1.35) * s, CFrame.new(0, s * 0.45, 0) * CFrame.Angles(0, 0, math.rad(90)), accent, accentMaterial)
	elseif def.Feature == "Mane" then
		addPart(model, body, ball, Vector3.one * 1.18 * s, CFrame.new(0, s * 0.05, s * 0.14), accent, accentMaterial)
	end
end

local function addBillboard(body: BasePart, def: Critters.Critter, rarity: Critters.Rarity, mutation: Critters.Mutation, maxDistance: number)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Info"
	billboard.Size = UDim2.fromOffset(200, 64)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, def.Size / 2 + 2, 0)
	billboard.MaxDistance = maxDistance
	billboard.LightInfluence = 0
	billboard.Parent = body

	local lines = {
		{ Text = (if mutation.Name ~= "Normal" then mutation.Name .. " " else "") .. def.Name, Color = mutation.Color or Color3.new(1, 1, 1), Height = 0.4 },
		{ Text = rarity.Name, Color = rarity.Color, Height = 0.3 },
		{ Text = Format.Money(Critters.Income(def.Id, mutation.Name)) .. "/s", Color = Color3.fromRGB(120, 255, 120), Height = 0.3 },
	}
	local y = 0
	for _, line in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Position = UDim2.fromScale(0, y)
		label.Size = UDim2.fromScale(1, line.Height)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = line.Text
		label.TextColor3 = line.Color
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = label
		label.Parent = billboard
		y += line.Height
	end
end

-- Returns a model whose PrimaryPart ("Body") is anchored at the origin.
function CritterFactory.Build(id: string, mutationName: string, maxDistance: number): Model
	local def = assert(Critters.Get(id), "Unknown critter " .. id)
	local rarity = Critters.GetRarity(def.Rarity)
	local mutation = Critters.GetMutation(mutationName)
	local s = def.Size

	local model = Instance.new("Model")
	model.Name = def.Name
	model:SetAttribute("CritterId", id)
	model:SetAttribute("Mutation", mutation.Name)
	model:SetAttribute("Rarity", rarity.Name)

	local material = if def.Neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	if mutation.Name == "Golden" then
		material = Enum.Material.Metal
	elseif mutation.Name == "Galaxy" then
		material = Enum.Material.Neon
	end

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.one * s
	body.Color = mutation.Color or def.Color
	body.Material = material
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.CFrame = CFrame.new()
	body.Parent = model
	model.PrimaryPart = body

	-- Big eyes sell "cute"
	for _, side in { -1, 1 } do
		addPart(model, body, Enum.PartType.Ball, Vector3.one * 0.3 * s, CFrame.new(side * s * 0.2, s * 0.12, -s * 0.36), Color3.new(1, 1, 1))
		addPart(model, body, Enum.PartType.Ball, Vector3.one * 0.15 * s, CFrame.new(side * s * 0.2, s * 0.12, -s * 0.5), Color3.new(0.05, 0.05, 0.05))
	end
	addFeature(model, body, def, if def.Neon then Enum.Material.Neon else Enum.Material.SmoothPlastic)

	if mutation.Name == "Rainbow" then
		CollectionService:AddTag(body, "RainbowPart") -- the client cycles its colour
	elseif mutation.Name == "Galaxy" then
		local stars = Instance.new("ParticleEmitter")
		stars.Rate = 10
		stars.Lifetime = NumberRange.new(1, 2)
		stars.Speed = NumberRange.new(1, 2)
		stars.SpreadAngle = Vector2.new(180, 180)
		stars.Size = NumberSequence.new(0.3, 0)
		stars.LightEmission = 1
		stars.Color = ColorSequence.new(Color3.fromRGB(150, 120, 255), Color3.fromRGB(120, 255, 255))
		stars.Parent = body
	end

	if rarity.Order >= 5 then
		local light = Instance.new("PointLight")
		light.Color = rarity.Color
		light.Range = 12
		light.Brightness = 2
		light.Parent = body
	end
	if rarity.Name == "Secret" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = rarity.Color
		sparkles.Parent = body
	end

	addBillboard(body, def, rarity, mutation, maxDistance)
	return model
end

return CritterFactory

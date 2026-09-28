-- First-time guidance: a glowing beam points at the nearest critter, then at
-- your base while you carry one. Hints only show up when they're needed.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local Onboarding = {}

local STUCK_SECONDS = 25

function Onboarding.Init(gui: ScreenGui)
	local hint = Theme.Label({
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -196),
		Size = UDim2.fromOffset(600, 40),
		TextColor3 = Theme.Colors.Cash,
		Visible = false,
		Parent = gui,
	})

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "GuideTarget"
	local beam = Instance.new("Beam")
	beam.Width0 = 0.8
	beam.Width1 = 0.8
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 230, 90))
	beam.Transparency = NumberSequence.new(0.25)
	beam.Segments = 12
	beam.Attachment1 = targetAttachment

	local stepStarted = os.clock()
	local lastStep = player:GetAttribute("TutorialStep")
	local celebrateUntil = 0

	local function nearestCritter(from: Vector3): BasePart?
		local map = Workspace:FindFirstChild("Map")
		local field = map and map:FindFirstChild("FieldCritters")
		if not field then
			return nil
		end
		local best, bestDistance = nil, math.huge
		for _, model in field:GetChildren() do
			if model:IsA("Model") and model.PrimaryPart then
				local distance = (model.PrimaryPart.Position - from).Magnitude
				-- Prefer commons for the first catch: they're slow and instant to grab.
				if model:GetAttribute("Rarity") ~= "Common" then
					distance += 60
				end
				if distance < bestDistance then
					best, bestDistance = model.PrimaryPart, distance
				end
			end
		end
		return best
	end

	local function ownFloor(): BasePart?
		local index = player:GetAttribute("PlotIndex")
		local map = Workspace:FindFirstChild("Map")
		local plots = map and map:FindFirstChild("Plots")
		local plot = plots and index and plots:FindFirstChild("Plot" .. index)
		local floor = plot and plot:FindFirstChild("Floor")
		return if floor and floor:IsA("BasePart") then floor else nil
	end

	while true do
		task.wait(0.2)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local step = player:GetAttribute("TutorialStep")
		if step ~= lastStep then
			if lastStep == 2 and step == 3 then
				celebrateUntil = os.clock() + 7
			end
			lastStep = step
			stepStarted = os.clock()
		end

		local target: BasePart? = nil
		local text: string? = nil
		if not root or not root:IsA("BasePart") then
			text = nil
		elseif player:GetAttribute("Carrying") then
			target = ownFloor()
			text = "Bring it home to your base! (Watch out for Bonk Bats!)"
		elseif step == 1 then
			target = nearestCritter(root.Position)
			text = if os.clock() - stepStarted > STUCK_SECONDS
				then "Tip: Commons are slow and instant to catch. Walk up and press E / tap Catch!"
				else "Catch a critter! Walk up to one and press E (or tap Catch)"
		elseif os.clock() < celebrateUntil then
			text = "Nice! Critters earn cash every second, even offline. Buy more slots in the Shop!"
		end

		hint.Text = text or ""
		hint.Visible = text ~= nil

		if target and root and root:IsA("BasePart") then
			local rootAttachment = root:FindFirstChild("RootAttachment") or root:FindFirstChildOfClass("Attachment")
			if rootAttachment and rootAttachment:IsA("Attachment") then
				targetAttachment.Parent = target
				beam.Attachment0 = rootAttachment
				beam.Parent = root
			end
		else
			beam.Parent = nil
			targetAttachment.Parent = nil
		end
	end
end

return Onboarding

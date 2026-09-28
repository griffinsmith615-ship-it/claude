-- Visual juice and small client-side jobs:
-- rainbow critters, catch celebrations, bonk knockback, hiding other
-- players' Sell prompts, and the VIP chat tag.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Critters = require(ReplicatedStorage.Shared.Critters)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Toasts = require(script.Parent.Toasts)

local player = Players.LocalPlayer

local Effects = {}

local function hideIfNotMine(instance: Instance)
	if instance:IsA("ProximityPrompt") then
		local owner = instance:GetAttribute("OwnerUserId")
		if owner ~= nil and owner ~= player.UserId then
			instance.Enabled = false
		end
	end
end

function Effects.Init()
	RunService.RenderStepped:Connect(function()
		local hue = (os.clock() * 0.3) % 1
		for _, part in CollectionService:GetTagged("RainbowPart") do
			if part:IsA("BasePart") then
				part.Color = Color3.fromHSV(hue, 0.75, 1)
			end
		end
	end)

	for _, descendant in Workspace:GetDescendants() do
		hideIfNotMine(descendant)
	end
	Workspace.DescendantAdded:Connect(hideIfNotMine)

	Remotes.Event("Celebrate").OnClientEvent:Connect(function(rarityName: string, mutation: string)
		local rarity = Critters.GetRarity(rarityName)
		if rarity.Order >= 3 or mutation ~= "Normal" then
			Toasts.Flash(rarity.Color)
		end
		local camera = Workspace.CurrentCamera
		if camera and rarity.Order >= 4 then
			local base = camera.FieldOfView
			camera.FieldOfView = base + 10
			TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { FieldOfView = base }):Play()
		end
	end)

	Remotes.Event("Knockback").OnClientEvent:Connect(function(velocity: Vector3)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid then
			return
		end
		humanoid.PlatformStand = true
		root.AssemblyLinearVelocity = velocity
		task.delay(0.7, function()
			humanoid.PlatformStand = false
		end)
	end)

	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local speaker = source and Players:GetPlayerByUserId(source.UserId)
		if speaker and speaker:GetAttribute("Pass_VIP") then
			properties.PrefixText = "<font color='#FFD24A'>[VIP]</font> " .. message.PrefixText
		end
		return properties
	end
end

return Effects

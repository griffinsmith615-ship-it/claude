-- Catch a Critter: client entry point.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local UI = script:WaitForChild("UI")
local Effects = require(UI.Effects)
local Hud = require(UI.Hud)
local Onboarding = require(UI.Onboarding)
local Panels = require(UI.Panels)
local Theme = require(UI.Theme)
local Toasts = require(UI.Toasts)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "CritterUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
Theme.AttachScale(gui)

Toasts.Init(gui)
Panels.Init(gui)
Hud.Init(gui)
Effects.Init()

Remotes.Event("Notify").OnClientEvent:Connect(Toasts.Notify)
Remotes.Event("Announce").OnClientEvent:Connect(Toasts.Announce)
Remotes.Event("Popup").OnClientEvent:Connect(Toasts.Popup)

player.AttributeChanged:Connect(Panels.Update)
Workspace.AttributeChanged:Connect(Panels.Update)

Onboarding.Init(gui) -- runs forever, so it goes last

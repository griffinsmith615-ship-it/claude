--!strict
-- Thin wrappers around the UI remotes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local notifyEvent = Remotes.Event("Notify")
local announceEvent = Remotes.Event("Announce")
local popupEvent = Remotes.Event("Popup")

local Notifier = {}

function Notifier.Notify(player: Player, text: string, color: Color3?)
	notifyEvent:FireClient(player, text, color)
end

function Notifier.Announce(text: string, color: Color3?)
	announceEvent:FireAllClients(text, color)
end

function Notifier.Popup(player: Player, title: string, body: string)
	popupEvent:FireClient(player, title, body)
end

return Notifier

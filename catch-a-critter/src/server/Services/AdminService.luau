--!strict
-- "Admin abuse" commands for live events (and handy for testing in Studio).
--   /spawn <rarity or critter id> [mutation]   e.g. /spawn Secret Galaxy
--   /storm [minutes]                           start a Critter Storm now
--   /luck [minutes]                            server luck boost
--   /cash <amount>                             give yourself cash (Studio only)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Critters = require(ReplicatedStorage.Shared.Critters)
local Economy = require(script.Parent.Economy)
local EventService = require(script.Parent.EventService)
local Notifier = require(script.Parent.Notifier)
local Spawner = require(script.Parent.Spawner)

local AdminService = {}

local function isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return table.find(Config.AdminUserIds, player.UserId) ~= nil
end

local function capitalize(word: string): string
	return string.upper(string.sub(word, 1, 1)) .. string.lower(string.sub(word, 2))
end

local function runCommand(player: Player, message: string)
	local args = string.split(message, " ")
	local command = string.lower(args[1] or "")

	if command == "/spawn" then
		local what = args[2] or "Legendary"
		local mutation = if args[3] then capitalize(args[3]) else "Normal"
		if Critters.GetMutation(mutation).Name ~= mutation then
			mutation = "Normal"
		end
		local id: string? = nil
		if Critters.Get(string.lower(what)) then
			id = string.lower(what)
		else
			local pool = Critters.OfRarity(capitalize(what))
			if #pool > 0 then
				id = pool[math.random(1, #pool)].Id
			end
		end
		if id then
			Spawner.Spawn(id, mutation)
		else
			Notifier.Notify(player, "Unknown rarity or critter: " .. what)
		end
	elseif command == "/storm" then
		local minutes = tonumber(args[2]) or Config.StormDuration / 60
		EventService.ForceStorm(minutes * 60)
	elseif command == "/luck" then
		local minutes = tonumber(args[2]) or 15
		EventService.AddServerLuck(minutes * 60)
		Notifier.Announce(string.format("ADMIN LUCK! x%d luck for %d minutes!", Config.ServerLuckMultiplier, minutes), Color3.fromRGB(120, 255, 140))
	elseif command == "/cash" and RunService:IsStudio() then
		Economy.Add(player, tonumber(args[2]) or 1000000)
	end
end

function AdminService.OnPlayerAdded(player: Player)
	player.Chatted:Connect(function(message)
		if string.sub(message, 1, 1) == "/" and isAdmin(player) then
			runCommand(player, message)
		end
	end)
end

return AdminService

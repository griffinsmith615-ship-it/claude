--!strict
-- Catch a Critter: server entry point.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local Services = script:WaitForChild("Services")
local AdminService = require(Services.AdminService)
local Analytics = require(Services.Analytics)
local CarryService = require(Services.CarryService)
local DataService = require(Services.DataService)
local Economy = require(Services.Economy)
local EventService = require(Services.EventService)
local MapBuilder = require(Services.MapBuilder)
local MonetizationService = require(Services.MonetizationService)
local Notifier = require(Services.Notifier)
local PlotService = require(Services.PlotService)
local RewardsService = require(Services.RewardsService)
local Spawner = require(Services.Spawner)

MapBuilder.Build()
DataService.Init()
EventService.Init()
PlotService.Init()
Spawner.Init()
CarryService.Init()
RewardsService.Init()
MonetizationService.Init()

-- Friend boost: +10% income per friend in the server (up to +30%).
-- Playing with friends is the strongest retention driver, so reward it.
local friendCache: { [string]: boolean } = {}

local function areFriends(a: Player, b: Player): boolean
	local low, high = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
	local key = low .. ":" .. high
	if friendCache[key] == nil then
		local ok, isFriend = pcall(function()
			return a:IsFriendsWithAsync(b.UserId)
		end)
		friendCache[key] = ok and isFriend == true
	end
	return friendCache[key]
end

local function updateFriendBoosts()
	local list = Players:GetPlayers()
	for _, player in list do
		local friends = 0
		for _, other in list do
			if other ~= player and areFriends(player, other) then
				friends += 1
			end
		end
		local boost = math.min(friends * Config.FriendBonus, Config.FriendBonusMax)
		local previous = (player:GetAttribute("FriendBoost") :: number?) or 0
		player:SetAttribute("FriendBoost", boost)
		if boost > previous then
			Notifier.Notify(player, string.format("Friend boost! +%d%% income while playing with friends", math.floor(boost * 100 + 0.5)), Color3.fromRGB(120, 200, 255))
		end
		Economy.Refresh(player)
	end
end

local function teleportHome(player: Player, character: Model)
	local spawnCFrame = PlotService.SpawnCFrame(player)
	if spawnCFrame then
		character:PivotTo(spawnCFrame)
	end
end

local function onCharacterAdded(player: Player, character: Model)
	task.defer(function()
		character:WaitForChild("HumanoidRootPart", 10)
		teleportHome(player, character)
	end)
	CarryService.OnCharacterAdded(player, character)
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("NumberValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats
	leaderstats.Parent = player

	if not PlotService.Assign(player) then
		player:Kick("This server is full. Please join another one!")
		return
	end

	CarryService.OnPlayerAdded(player)
	AdminService.OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end

	MonetizationService.LoadPasses(player)
	local profile, offlineSeconds, isNew = DataService.Load(player)
	if not player.Parent then
		DataService.Release(player)
		return
	end

	if isNew then
		Analytics.MarkNewPlayer(player)
		Analytics.Funnel(player, 1, "Joined")
	end
	player:SetAttribute("TutorialStep", if profile.TutorialDone then 3 else 1)
	PlotService.Render(player)
	Economy.Refresh(player)

	-- Offline earnings: critters keep earning while you're away.
	if offlineSeconds >= Config.OfflineMinSeconds and #profile.Critters > 0 then
		local capHours = if player:GetAttribute("Pass_VIP") then Config.OfflineCapHoursVIP else Config.OfflineCapHours
		local seconds = math.min(offlineSeconds, capHours * 3600)
		local earned = Economy.Income(player, profile, false) * seconds
		Economy.Add(player, earned, Enum.AnalyticsEconomyTransactionType.TimedReward, "Offline")
		Notifier.Popup(
			player,
			"Welcome back!",
			string.format("While you were away (%s), your critters earned %s!", Format.Time(seconds), Format.Money(earned))
		)
	elseif isNew then
		Notifier.Popup(player, "Welcome to Catch a Critter!", "Catch critters in the meadow, bring them home, and they earn cash every second, even while you're offline!")
	end

	player:SetAttribute("Loaded", true)
	updateFriendBoosts()
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerRemoving:Connect(function()
	task.defer(updateFriendBoosts)
end)

-- Passive income, once per second.
task.spawn(function()
	while true do
		task.wait(1)
		for player, profile in DataService.All() do
			if player.Parent then
				profile.Cash += Economy.Income(player, profile, true)
				Economy.Refresh(player)
			end
		end
	end
end)

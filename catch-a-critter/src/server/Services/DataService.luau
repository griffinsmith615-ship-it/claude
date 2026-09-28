--!strict
-- Loads and saves player data with DataStoreService.
-- Uses a simple session lock so two servers never overwrite each other's data,
-- autosaves every minute, and saves everyone on shutdown.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local STORE_NAME = "CatchACritter_v1"
local AUTOSAVE_INTERVAL = 60
local LOCK_TIMEOUT = 300 -- a lock older than this is treated as abandoned
local MAX_RECEIPTS = 50

export type CritterEntry = { Id: string, Mut: string }

export type Profile = {
	Cash: number,
	Rebirths: number,
	BoughtSlots: number,
	Critters: { CritterEntry },
	Index: { [string]: boolean },
	LastOnline: number,
	DailyDay: number, -- day number (os.time() // 86400) of the last daily claim
	DailyStreak: number,
	Codes: { [string]: boolean },
	Receipts: { string },
	Caught: number,
	TutorialDone: boolean,
}

local function defaultProfile(): Profile
	return {
		Cash = 0,
		Rebirths = 0,
		BoughtSlots = 0,
		Critters = {},
		Index = {},
		LastOnline = 0,
		DailyDay = 0,
		DailyStreak = 0,
		Codes = {},
		Receipts = {},
		Caught = 0,
		TutorialDone = false,
	}
end

-- Fill in any fields added after a player's data was first saved.
local function reconcile(saved: any): Profile
	local profile = defaultProfile() :: any
	if type(saved) == "table" then
		for key, value in saved do
			if profile[key] ~= nil and type(profile[key]) == type(value) then
				profile[key] = value
			end
		end
	end
	return profile :: Profile
end

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStores unavailable:", result)
	end
end

local DataService = {}

local profiles: { [Player]: Profile } = {}
local canSave: { [Player]: boolean } = {}

local function keyFor(player: Player): string
	return "u_" .. player.UserId
end

-- Returns the profile, how many seconds the player was offline, and whether they're new.
function DataService.Load(player: Player): (Profile, number, boolean)
	local profile: Profile? = nil
	local loadedFromStore = false

	if store then
		for attempt = 1, 5 do
			local forceLock = attempt == 5
			local ok, result = pcall(function()
				return store:UpdateAsync(keyFor(player), function(old: any)
					old = if type(old) == "table" then old else {}
					local lock = old.Lock
					if not forceLock and type(lock) == "table" and lock.JobId ~= game.JobId and os.time() - (lock.Time or 0) < LOCK_TIMEOUT then
						return nil -- still locked by another server; don't write
					end
					old.Lock = { JobId = game.JobId, Time = os.time() }
					return old
				end)
			end)
			if ok then
				local data = result :: any
				if type(data) == "table" and type(data.Lock) == "table" and data.Lock.JobId == game.JobId then
					profile = reconcile(data.Profile)
					loadedFromStore = true
					break
				end
				-- Locked by a server that's still saving this player; wait and retry.
			else
				warn("[DataService] Load failed for", player.Name, result)
				if RunService:IsStudio() then
					break -- usually "Studio access to API services" is off; don't wait
				end
			end
			task.wait(attempt * 1.5)
			if not player.Parent then
				break
			end
		end
	end

	local final = profile or defaultProfile()
	local isNew = final.LastOnline == 0
	local offlineSeconds = if isNew then 0 else math.max(0, os.time() - final.LastOnline)
	final.LastOnline = os.time()

	profiles[player] = final
	canSave[player] = loadedFromStore
	if not loadedFromStore then
		warn("[DataService] Playing without saving for", player.Name)
	end
	return final, offlineSeconds, isNew
end

function DataService.Get(player: Player): Profile?
	return profiles[player]
end

function DataService.All(): { [Player]: Profile }
	return profiles
end

function DataService.CanSave(player: Player): boolean
	return canSave[player] == true
end

function DataService.Save(player: Player, release: boolean?): boolean
	local profile = profiles[player]
	if not profile or not canSave[player] or not store then
		return false
	end
	profile.LastOnline = os.time()
	while #profile.Receipts > MAX_RECEIPTS do
		table.remove(profile.Receipts, 1)
	end
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function(old: any)
			old = if type(old) == "table" then old else {}
			local lock = old.Lock
			if type(lock) == "table" and lock.JobId ~= game.JobId then
				return nil -- another server took over this player; never overwrite its data
			end
			old.Profile = profile
			old.Lock = if release then nil else { JobId = game.JobId, Time = os.time() }
			return old
		end)
	end)
	if not ok then
		warn("[DataService] Save failed for", player.Name, err)
	end
	return ok
end

function DataService.Release(player: Player)
	DataService.Save(player, true)
	profiles[player] = nil
	canSave[player] = nil
end

function DataService.Init()
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.Save(player, true)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		DataService.Release(player)
	end)
end

return DataService

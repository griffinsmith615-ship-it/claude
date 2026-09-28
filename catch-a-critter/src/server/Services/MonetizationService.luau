--!strict
-- Game passes and developer products. Receipts are recorded in the player's
-- data so a purchase is never granted twice.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Analytics = require(script.Parent.Analytics)
local CarryService = require(script.Parent.CarryService)
local DataService = require(script.Parent.DataService)
local Economy = require(script.Parent.Economy)
local EventService = require(script.Parent.EventService)
local Notifier = require(script.Parent.Notifier)
local PlotService = require(script.Parent.PlotService)

local MonetizationService = {}

local passKeyById: { [number]: string } = {}
for _, pass in Config.GamePasses do
	if pass.Id ~= 0 then
		passKeyById[pass.Id] = pass.Key
	end
end

local function applyPass(player: Player, key: string)
	player:SetAttribute("Pass_" .. key, true)
	if key == "SpeedyCarry" then
		CarryService.UpdateSpeed(player)
	elseif key == "ExtraSlots" then
		PlotService.UpdatePedestals(player)
	end
	Economy.Refresh(player)
end

-- Checks pass ownership on join. Yields.
function MonetizationService.LoadPasses(player: Player)
	for _, pass in Config.GamePasses do
		if pass.Id == 0 then
			continue
		end
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
		end)
		if ok and owns then
			player:SetAttribute("Pass_" .. pass.Key, true)
		end
	end
end

type ProductHandler = (Player, DataService.Profile) -> ()

local productHandlers: { [string]: ProductHandler } = {
	ServerLuck = function(player)
		EventService.AddServerLuck(Config.ServerLuckSeconds)
		Notifier.Announce(string.format("%s gave the whole server x%d LUCK for %d minutes!", player.DisplayName, Config.ServerLuckMultiplier, Config.ServerLuckSeconds // 60), Color3.fromRGB(120, 255, 140))
	end,
	CashSmall = function(player, profile)
		local pack = Config.CashPacks.CashSmall
		local amount = math.max(pack.Min, Economy.Income(player, profile, false) * pack.Seconds)
		Economy.Add(player, amount, Enum.AnalyticsEconomyTransactionType.IAP, "CashSmall")
		Notifier.Notify(player, "+" .. Format.Money(amount) .. "! Thanks for supporting the game!")
	end,
	CashBig = function(player, profile)
		local pack = Config.CashPacks.CashBig
		local amount = math.max(pack.Min, Economy.Income(player, profile, false) * pack.Seconds)
		Economy.Add(player, amount, Enum.AnalyticsEconomyTransactionType.IAP, "CashBig")
		Notifier.Notify(player, "+" .. Format.Money(amount) .. "! Thanks for supporting the game!")
	end,
}

local handlerById: { [number]: ProductHandler } = {}
for _, product in Config.Products do
	if product.Id ~= 0 and productHandlers[product.Key] then
		handlerById[product.Id] = productHandlers[product.Key]
	end
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local profile = player and DataService.Get(player)
	if not player or not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries next time they join
	end
	local purchaseId = tostring(receipt.PurchaseId)
	if table.find(profile.Receipts, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local handler = handlerById[receipt.ProductId]
	if not handler then
		warn("[Monetization] No handler for product", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(function()
		handler(player, profile)
	end)
	if not ok then
		warn("[Monetization] Product grant failed:", err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(profile.Receipts, purchaseId)
	Analytics.Custom(player, "Purchase_" .. tostring(receipt.ProductId), receipt.CurrencySpent)
	-- Save right away so the receipt can't be lost if the server crashes.
	if DataService.CanSave(player) and not DataService.Save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local key = passKeyById[passId]
		if purchased and key then
			applyPass(player, key)
			Notifier.Notify(player, "Thanks! Your pass is active.", Color3.fromRGB(120, 255, 120))
		end
	end)
end

return MonetizationService

--!strict
-- Wraps AnalyticsService so a failure never breaks gameplay.
-- Onboarding funnel steps are only logged for brand-new players, so the
-- Creator Dashboard funnel shows exactly where first-timers drop off.

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Analytics = {}

local newPlayers: { [Player]: { [number]: boolean } } = {}

function Analytics.MarkNewPlayer(player: Player)
	newPlayers[player] = {}
end

function Analytics.Funnel(player: Player, step: number, name: string)
	local done = newPlayers[player]
	if not done or done[step] then
		return
	end
	done[step] = true
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, name)
	end)
end

function Analytics.Economy(player: Player, isSource: boolean, amount: number, balance: number, transactionType: Enum.AnalyticsEconomyTransactionType, sku: string)
	pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			if isSource then Enum.AnalyticsEconomyFlowType.Source else Enum.AnalyticsEconomyFlowType.Sink,
			"Cash",
			math.floor(amount),
			math.floor(balance),
			transactionType.Name,
			sku
		)
	end)
end

function Analytics.Custom(player: Player, name: string, value: number?)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, name, value or 1)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	newPlayers[player] = nil
end)

return Analytics

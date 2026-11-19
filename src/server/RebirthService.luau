-- RebirthService: reset money and brainrots for a permanent income
-- multiplier. Cost doubles every rebirth and the multiplier doubles too,
-- so the ladder never ends — but each rung costs twice the last. A stolen
-- brainrot being carried is never yours to burn: it goes home first.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local RebirthService = {}

function RebirthService.tryRebirth(player)
	local data = State.getPlayer(player)
	if not data then
		return false
	end
	local cost = Config.rebirthCost(data.rebirths)
	if data.money < cost then
		Remotes.notify(player, "Rebirth costs " .. BrainrotData.formatMoney(cost) .. " — you have " .. BrainrotData.formatMoney(data.money) .. ". Keep earning!", "bad")
		return false
	end

	if data.carrying then
		local StealService = require(script.Parent.StealService)
		StealService.returnToOwner(data.carrying)
		data.carrying = nil
	end
	for id, entry in pairs(State.owned) do
		if entry.ownerId == player.UserId then
			entry.model:Destroy()
			State.owned[id] = nil
		end
	end

	data.money = Config.StartingMoney
	data.rebirths += 1
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirthValue = leaderstats:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = data.rebirths
		end
	end
	local QuestService = require(script.Parent.QuestService)
	QuestService.addProgress(player, "rebirth", 1)
	Remotes.MoneyUpdate:FireClient(player, math.floor(data.money), 0)
	Remotes.notify(player, "REBIRTH " .. data.rebirths .. "! All income is now x" .. Config.rebirthMultiplier(data.rebirths) .. " forever.", "good")
	return true
end

function RebirthService.start()
	-- Wired from init: Remotes.Rebirth -> tryRebirth. Kept as a start() so
	-- every service has the same lifecycle shape.
end

return RebirthService

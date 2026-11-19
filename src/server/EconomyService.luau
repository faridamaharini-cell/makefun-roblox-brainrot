-- EconomyService: buying brainrots off the conveyor and the money tick.
-- Every owned brainrot earns its $/sec every second, times the rebirth
-- multiplier; buying checks money, a free slot, and the walker still being
-- on the conveyor.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local State = require(script.Parent.State)
local BaseService = require(script.Parent.BaseService)
local Remotes = require(script.Parent.Remotes)

local EconomyService = {}

local ownedFolder

function EconomyService.start()
	ownedFolder = Instance.new("Folder")
	ownedFolder.Name = "OwnedBrainrots"
	ownedFolder.Parent = game:GetService("Workspace")
end

function EconomyService.tryBuy(player, brainrotId)
	local data = State.getPlayer(player)
	local walker = State.walkers[brainrotId]
	if not data or not walker then
		return false
	end
	if walker.model:GetAttribute("State") ~= "walking" then
		return false
	end
	if data.money < walker.price then
		Remotes.notify(player, "Need " .. BrainrotData.formatMoney(walker.price) .. " for " .. walker.def.name .. " — you have " .. BrainrotData.formatMoney(data.money), "bad")
		return false
	end
	local slotIndex = BaseService.freeSlotIndex(data.baseIndex)
	if not slotIndex then
		Remotes.notify(player, "Your base is full! Sell or rebirth to make room.", "bad")
		return false
	end

	data.money -= walker.price
	State.walkers[brainrotId] = nil
	local entry = {
		model = walker.model,
		def = walker.def,
		mutation = walker.mutation,
		price = walker.price,
		income = walker.income,
		ownerId = player.UserId,
		baseIndex = data.baseIndex,
		slotIndex = slotIndex,
	}
	State.owned[brainrotId] = entry
	walker.model.Parent = ownedFolder
	BaseService.placeInSlot(entry, data.baseIndex, slotIndex)
	local StealService = require(script.Parent.StealService)
	StealService.registerPrompt(entry, brainrotId)
	Remotes.notify(player, "Bought " .. walker.def.name .. " (" .. walker.mutation.name .. ") for " .. BrainrotData.formatMoney(walker.price) .. " — earns " .. BrainrotData.formatMoney(walker.income) .. "/s!", "good")
	return true
end

-- Nearest walker to a player, for the E key buy shortcut.
function EconomyService.nearestWalker(player, maxDistance)
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best = nil
	local bestDist = maxDistance
	for id, walker in pairs(State.walkers) do
		local pos = walker.model:GetPivot().Position
		local dist = (pos - root.Position).Magnitude
		if dist < bestDist then
			bestDist = dist
			best = id
		end
	end
	return best
end

-- One money tick: every owned brainrot pays its $/sec into its owner's pocket.
function EconomyService.tick()
	for _, data in pairs(State.players) do
		local income = State.incomePerSecond(data.player)
		if income > 0 then
			data.money += income
		end
		local leaderstats = data.player:FindFirstChild("leaderstats")
		if leaderstats then
			local moneyValue = leaderstats:FindFirstChild("Money")
			if moneyValue then
				moneyValue.Value = math.floor(data.money)
			end
			local incomeValue = leaderstats:FindFirstChild("Income")
			if incomeValue then
				incomeValue.Value = income
			end
			local rebirthValue = leaderstats:FindFirstChild("Rebirths")
			if rebirthValue then
				rebirthValue.Value = data.rebirths
			end
		end
	end
	BaseService.refreshLocks()
end

return EconomyService

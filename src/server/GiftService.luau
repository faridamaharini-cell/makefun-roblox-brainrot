-- GiftService: give a brainrot to another player through the GiftBrainrot
-- remote. The gift is the brainrot the giver is carrying (a steal in
-- progress can be passed on), or otherwise their nearest owned brainrot.
-- The recipient needs a free slot; the giver earns "gift" quest progress.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local State = require(script.Parent.State)
local BaseService = require(script.Parent.BaseService)
local Remotes = require(script.Parent.Remotes)

local GiftService = {}

local function playerRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- The brainrot to gift: the carried one first, else the nearest owned one.
local function giftCandidate(data)
	if data.carrying then
		return data.carrying
	end
	local root = playerRoot(data.player)
	if not root then
		return nil
	end
	local best = nil
	local bestDist = math.huge
	for id, entry in pairs(State.owned) do
		if entry.ownerId == data.player.UserId and entry.model:GetAttribute("State") == "owned" then
			local dist = (entry.model:GetPivot().Position - root.Position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = id
			end
		end
	end
	return best
end

local function nearestOtherPlayer(player)
	local root = playerRoot(player)
	if not root then
		return nil
	end
	local best = nil
	local bestDist = Config.GiftRange
	for _, other in pairs(State.players) do
		if other.player ~= player then
			local otherRoot = playerRoot(other.player)
			if otherRoot then
				local dist = (otherRoot.Position - root.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					best = other.player
				end
			end
		end
	end
	return best
end

function GiftService.tryGift(player)
	local data = State.getPlayer(player)
	if not data then
		return false
	end
	local brainrotId = giftCandidate(data)
	local entry = brainrotId and State.owned[brainrotId] or nil
	if not entry then
		Remotes.notify(player, "You have no brainrot to gift — buy or steal one first!", "bad")
		return false
	end
	local recipient = nearestOtherPlayer(player)
	if not recipient then
		Remotes.notify(player, "No other player within " .. Config.GiftRange .. " studs to gift to. Get closer!", "bad")
		return false
	end
	local recipientData = State.getPlayer(recipient)
	if not recipientData or recipientData.baseIndex == 0 then
		Remotes.notify(player, recipient.Name .. " doesn't have a base yet.", "bad")
		return false
	end
	local slotIndex = BaseService.freeSlotIndex(recipientData.baseIndex)
	if not slotIndex then
		Remotes.notify(player, recipient.Name .. "'s base is full!", "bad")
		return false
	end

	if data.carrying == brainrotId then
		data.carrying = nil
	end
	entry.ownerId = recipient.UserId
	BaseService.placeInSlot(entry, recipientData.baseIndex, slotIndex)
	data.giftsGiven += 1
	local QuestService = require(script.Parent.QuestService)
	QuestService.addProgress(player, "gift", 1)
	Remotes.notify(player, "You gifted " .. entry.def.name .. " to " .. recipient.Name .. "! How generous!", "good")
	Remotes.notify(recipient, player.Name .. " gifted you " .. entry.def.name .. "! It earns " .. entry.income .. "/s on your base now.", "good")
	return true
end

function GiftService.start()
	Remotes.GiftBrainrot.OnServerEvent:Connect(function(player)
		GiftService.tryGift(player)
	end)
end

return GiftService

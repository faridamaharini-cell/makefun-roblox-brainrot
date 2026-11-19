-- RebirthService: reset money and brainrots for a permanent income multiplier.
-- Cost doubles every rebirth, multiplier doubles too: the ladder never ends,
-- but each rung costs twice the last.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
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
		Remotes.notify(player, "Rebirth costs " .. tostring(cost) .. " — you have " .. tostring(math.floor(data.money)) .. ". Keep earning!", "bad")
		return false
	end

	-- Clear every brainrot this player owns, and anything they are carrying.
	for id, entry in pairs(State.owned) do
		if entry.ownerId == player.UserId then
			entry.model:Destroy()
			State.owned[id] = nil
		end
	end
	if data.carrying then
		local entry = State.owned[data.carrying]
		if entry then
			-- A stolen brainrot is not yours to burn: send it home first.
			entry.model:SetAttribute("State", "owned")
			local StealService = require(script.Parent.StealService)
			StealService.returnToOwner(data.carrying)
		end
		data.carrying = nil
	end

	data.money = 0
	data.rebirths += 1
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirthValue = leaderstats:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = data.rebirths
		end
	end
	Remotes.notify(player, "REBIRTH " .. data.rebirths .. "! All income is now x" .. Config.rebirthMultiplier(data.rebirths) .. " forever.", "good")
	return true
end

return RebirthService

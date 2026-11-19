-- State: Brainrot Bay's single source of truth.
-- Every server service reads and writes through this module, so money,
-- bases, walkers, owned brainrots, quests, upgrades and live events can
-- never disagree with each other. Nothing here touches the game world
-- directly; it only holds data and the pure math over that data.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Remotes = require(script.Parent.Remotes)

local State = {}

State.players = {} -- [userId] = player data (see newPlayerData)
State.walkers = {} -- [brainrotId] = { model, def, mutation, price, income }
State.owned = {} -- [brainrotId] = { model, def, mutation, price, income, ownerId, baseIndex, slotIndex }
State.bases = {} -- [baseIndex] = { index, center, spawnPos, slots, ownerUserId, color, folder, signLabel, lockField }
State.nextBrainrotId = 1
State.waveActive = false
State.waveEndsAt = 0
State.goldenHourActive = false
State.meteorActive = false
State.eventEndsAt = 0

-- A fresh record for a player who just joined. Quests start unclaimed with
-- zero progress; upgrades start at level 0 in every kind.
function State.newPlayerData(player)
	return {
		player = player,
		money = Config.StartingMoney,
		rebirths = 0,
		baseIndex = 0,
		lockUntil = 0,
		lockCooldownUntil = 0,
		slapCooldownUntil = 0,
		carrying = nil, -- brainrotId being carried home, or nil
		quests = {}, -- [questId] = { progress, claimed }
		upgrades = { capacity = 0, income = 0, lock = 0 },
		found = {}, -- Baydex: [defId] = true, survives rebirth (lives here, not on owned entries)
		giftsGiven = 0,
	}
end

function State.getPlayer(player)
	if not player then
		return nil
	end
	return State.players[player.UserId]
end

-- Push the player's Baydex found set to their client.
function State.sendIndex(player)
	local data = State.getPlayer(player)
	if not data then
		return
	end
	Remotes.IndexUpdate:FireClient(player, data.found)
end

-- Mark a brainrot def as found for a player and push the update, but
-- only when it is actually new, so banking the same def twice stays quiet.
function State.markFound(player, defId)
	local data = State.getPlayer(player)
	if not data or not defId or data.found[defId] then
		return
	end
	data.found[defId] = true
	State.sendIndex(player)
end

-- Cash per second from everything this player owns: base income, doubled
-- per rebirth, boosted by the income upgrade, doubled again in Golden Hour.
function State.incomePerSecond(player)
	local data = State.getPlayer(player)
	if not data then
		return 0
	end
	local total = 0
	for _, entry in pairs(State.owned) do
		if entry.ownerId == player.UserId then
			total += entry.income
		end
	end
	local multiplier = Config.rebirthMultiplier(data.rebirths)
	multiplier *= Economy.incomeMultiplier(data.upgrades.income)
	if State.goldenHourActive then
		multiplier *= 2
	end
	return total * multiplier
end

-- A base is locked while its owner's lock timer is still running. The lock
-- lasts the base duration plus 15 seconds per lock upgrade the owner owns.
function State.isBaseLocked(baseIndex)
	local base = State.bases[baseIndex]
	if not base or not base.ownerUserId then
		return false
	end
	local owner = State.players[base.ownerUserId]
	if not owner then
		return false
	end
	return os.clock() < owner.lockUntil
end

-- How many brainrot slots a base has: 12 by default, +2 per capacity level.
function State.slotCount(baseIndex)
	local base = State.bases[baseIndex]
	if not base or not base.ownerUserId then
		return Config.SlotsPerBase
	end
	local owner = State.players[base.ownerUserId]
	if not owner then
		return Config.SlotsPerBase
	end
	return Economy.slotsForLevel(owner.upgrades.capacity, Config.SlotsPerBase)
end

return State

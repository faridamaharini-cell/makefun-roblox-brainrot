-- State: the one place all server state lives. Every service reads and writes
-- through this module, so there is a single source of truth for money, bases,
-- walkers and owned brainrots.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local State = {}

State.players = {} -- [userId] = { player, money, rebirths, baseIndex, lockUntil, lockCooldownUntil, slapCooldownUntil, carrying }
State.walkers = {} -- [brainrotId] = { model, def, mutation, price, income }
State.owned = {} -- [brainrotId] = { model, def, mutation, price, income, ownerId, baseIndex, slotIndex }
State.bases = {} -- [baseIndex] = { index, center, spawnPos, slots = {Vector3}, ownerUserId, color }
State.nextBrainrotId = 1
State.waveActive = false
State.waveEndsAt = 0

function State.newPlayerData(player)
	return {
		player = player,
		money = Config.StartingMoney,
		rebirths = 0,
		baseIndex = 0,
		lockUntil = 0,
		lockCooldownUntil = 0,
		slapCooldownUntil = 0,
		carrying = nil, -- brainrotId being carried, or nil
	}
end

function State.getPlayer(player)
	return State.players[player.UserId]
end

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
	return total * Config.rebirthMultiplier(data.rebirths)
end

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

return State

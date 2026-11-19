-- BaseService: owns base assignment, slots and the base lock defence.
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local BaseService = {}

function BaseService.assignBase(player)
	local data = State.getPlayer(player)
	if not data then
		return 0
	end
	if data.baseIndex ~= 0 then
		return data.baseIndex
	end
	-- First free base; with more players than bases, share the emptiest one.
	for _, base in ipairs(State.bases) do
		if not base.ownerUserId then
			base.ownerUserId = player.UserId
			data.baseIndex = base.index
			return base.index
		end
	end
	local shared = State.bases[(#State.players % Config.MaxBases) + 1]
	data.baseIndex = shared.index
	return shared.index
end

function BaseService.freeSlotIndex(baseIndex)
	for slotIndex = 1, Config.SlotsPerBase do
		local taken = false
		for _, entry in pairs(State.owned) do
			if entry.baseIndex == baseIndex and entry.slotIndex == slotIndex then
				taken = true
				break
			end
		end
		if not taken then
			return slotIndex
		end
	end
	return nil
end

function BaseService.slotPosition(baseIndex, slotIndex)
	local base = State.bases[baseIndex]
	if not base then
		return Vector3.new(0, 1, 0)
	end
	return base.slots[slotIndex] or base.center
end

-- Places a brainrot model on a slot pad, facing the conveyor.
function BaseService.placeInSlot(entry, baseIndex, slotIndex)
	local pos = BaseService.slotPosition(baseIndex, slotIndex)
	entry.model:PivotTo(CFrame.new(pos + Vector3.new(0, 0.1, 0)))
	entry.model:SetAttribute("State", "owned")
	entry.model:SetAttribute("OwnerUserId", entry.ownerId)
	entry.baseIndex = baseIndex
	entry.slotIndex = slotIndex
	local prompt = entry.model:FindFirstChild("InteractPrompt", true)
	if prompt then
		prompt.ActionText = "Steal"
		prompt.ObjectText = entry.def.name
		prompt.Enabled = not State.isBaseLocked(baseIndex)
	end
end

function BaseService.lockBase(player)
	local data = State.getPlayer(player)
	if not data or data.baseIndex == 0 then
		return false
	end
	local now = os.clock()
	if now < data.lockCooldownUntil then
		Remotes.notify(player, "Lock recharging: " .. math.ceil(data.lockCooldownUntil - now) .. "s left", "bad")
		return false
	end
	data.lockUntil = now + Config.LockDuration
	data.lockCooldownUntil = now + Config.LockCooldown
	-- Steal prompts on this base switch off while locked.
	for _, entry in pairs(State.owned) do
		if entry.baseIndex == data.baseIndex then
			local prompt = entry.model:FindFirstChild("InteractPrompt", true)
			if prompt then
				prompt.Enabled = false
			end
		end
	end
	Remotes.notify(player, "Base locked for " .. Config.LockDuration .. "s! Nobody can steal now.", "good")
	return true
end

-- Called every second: re-enable steal prompts whose lock just expired.
function BaseService.refreshLocks()
	for _, entry in pairs(State.owned) do
		local prompt = entry.model:FindFirstChild("InteractPrompt", true)
		if prompt then
			prompt.Enabled = not State.isBaseLocked(entry.baseIndex)
		end
	end
end

return BaseService

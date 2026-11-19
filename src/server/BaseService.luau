-- BaseService: owns base assignment, slots and the base lock defence.
-- A base has 12 slots by default and +2 per capacity upgrade (up to 20);
-- the lock lasts 30 seconds plus 15 per lock upgrade, then recharges.
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local BrainrotFactory = require(Shared:WaitForChild("BrainrotFactory"))
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local BaseService = {}

-- First free base. If all ten are taken the player waits with baseIndex 0
-- (no base sharing: a shared base would let strangers steal each other).
function BaseService.assignBase(player)
	local data = State.getPlayer(player)
	if not data then
		return 0
	end
	if data.baseIndex ~= 0 then
		return data.baseIndex
	end
	for _, base in ipairs(State.bases) do
		if not base.ownerUserId then
			base.ownerUserId = player.UserId
			data.baseIndex = base.index
			if base.signLabel then
				base.signLabel.Text = player.Name .. "'s BAY"
			end
			return base.index
		end
	end
	Remotes.notify(player, "All 10 bases are taken right now — you'll get one as soon as a player leaves.", "bad")
	return 0
end

-- First free slot on a base, honouring the owner's capacity upgrades.
function BaseService.freeSlotIndex(baseIndex)
	local base = State.bases[baseIndex]
	if not base then
		return nil
	end
	local maxSlots = State.slotCount(baseIndex)
	local taken = {}
	for _, entry in pairs(State.owned) do
		if entry.baseIndex == baseIndex and entry.slotIndex then
			taken[entry.slotIndex] = true
		end
	end
	for i = 1, maxSlots do
		if not taken[i] then
			return i
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

-- Places a brainrot model on a slot pad, facing the conveyor, and retargets
-- its prompt to "Steal" (disabled while the base is locked).
function BaseService.placeInSlot(entry, baseIndex, slotIndex)
	local pos = BaseService.slotPosition(baseIndex, slotIndex)
	entry.baseIndex = baseIndex
	entry.slotIndex = slotIndex
	entry.model:SetAttribute("State", "owned")
	entry.model:SetAttribute("OwnerUserId", entry.ownerId)
	-- pos.Y is the pad top; pivot is the Body centre, PIVOT_ABOVE_FEET
	-- above the feet, so the model stands on the pad instead of sinking.
	entry.model:PivotTo(CFrame.new(pos + Vector3.new(0, 0.1 + BrainrotFactory.PIVOT_ABOVE_FEET, 0)))
	local folder = Workspace:FindFirstChild("OwnedBrainrots")
	if folder then
		entry.model.Parent = folder
	end
	local prompt = entry.model:FindFirstChild("InteractPrompt", true)
	if prompt then
		prompt.ActionText = "Steal"
		prompt.ObjectText = entry.def.name
		prompt.Enabled = not State.isBaseLocked(baseIndex)
	end
	-- Banking a brainrot on a base marks its def as found in the owner's
	-- Baydex. This one spot covers buy, gift received and steal banked,
	-- because all three bank through here; return-to-owner re-marks a def
	-- the owner already found, which markFound ignores.
	local ownerData = State.players[entry.ownerId]
	if ownerData then
		State.markFound(ownerData.player, entry.def.id)
	end
end

function BaseService.lockBase(player)
	local data = State.getPlayer(player)
	if not data or data.baseIndex == 0 then
		return false
	end
	local now = os.clock()
	if now < data.lockCooldownUntil then
		Remotes.notify(player, "Lock recharging: " .. math.ceil(data.lockCooldownUntil - now) .. "s left.", "bad")
		return false
	end
	local duration = Economy.lockDuration(data.upgrades.lock, Config.LockDuration)
	data.lockUntil = now + duration
	data.lockCooldownUntil = now + Config.LockCooldown
	BaseService.refreshLocks()
	Remotes.notify(player, "Base locked for " .. duration .. "s! Nobody can steal from you now.", "good")
	return true
end

-- Called every second from the money tick: the lock force-field shows while
-- a base is locked, and steal prompts switch off and on with the lock.
function BaseService.refreshLocks()
	for index, base in ipairs(State.bases) do
		local locked = State.isBaseLocked(index)
		if base.lockField then
			base.lockField.Transparency = locked and 0.55 or 1
		end
	end
	for _, entry in pairs(State.owned) do
		if entry.model:GetAttribute("State") == "owned" then
			local prompt = entry.model:FindFirstChild("InteractPrompt", true)
			if prompt then
				prompt.Enabled = not State.isBaseLocked(entry.baseIndex)
			end
		end
	end
end

return BaseService

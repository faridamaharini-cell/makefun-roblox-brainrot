-- StealService: the threat. Steal a brainrot off a rival's unlocked base,
-- carry it home on your head, and bank it on your own base to make it earn
-- for you. A locked base can't be stolen from; a slap (F key) knocks a
-- stolen brainrot out of a carrier's hands and sends it straight home.
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local State = require(script.Parent.State)
local BaseService = require(script.Parent.BaseService)
local Remotes = require(script.Parent.Remotes)

local StealService = {}

-- Wire the steal prompt of one owned brainrot.
function StealService.registerPrompt(entry, brainrotId)
	local prompt = entry.model:FindFirstChild("InteractPrompt", true)
	if not prompt then
		return
	end
	prompt.Triggered:Connect(function(player)
		StealService.trySteal(player, brainrotId)
	end)
end

function StealService.trySteal(player, brainrotId)
	local data = State.getPlayer(player)
	local entry = State.owned[brainrotId]
	if not data or not entry then
		return false
	end
	if entry.ownerId == player.UserId then
		return false
	end
	if entry.model:GetAttribute("State") ~= "owned" then
		return false
	end
	if data.carrying then
		Remotes.notify(player, "You're already carrying a brainrot — bank it first!", "bad")
		return false
	end
	if State.isBaseLocked(entry.baseIndex) then
		Remotes.notify(player, "That base is LOCKED! Wait for the lock to run out.", "bad")
		return false
	end

	entry.model:SetAttribute("State", "carried")
	entry.slotIndex = nil -- frees the victim's slot while it is carried
	data.carrying = brainrotId
	local prompt = entry.model:FindFirstChild("InteractPrompt", true)
	if prompt then
		prompt.Enabled = false
	end
	Remotes.notify(player, "You stole " .. entry.def.name .. "! RUN home to your base!", "good")
	for _, other in pairs(State.players) do
		if other.player.UserId == entry.ownerId then
			Remotes.notify(other.player, player.Name .. " stole your " .. entry.def.name .. "! Slap them (F) to get it back!", "bad")
			break
		end
	end
	return true
end

-- Send a brainrot back to its owner's base (slap, wave, carrier left/died).
function StealService.returnToOwner(brainrotId)
	local entry = State.owned[brainrotId]
	if not entry then
		return
	end
	local slotIndex = BaseService.freeSlotIndex(entry.baseIndex) or 1
	BaseService.placeInSlot(entry, entry.baseIndex, slotIndex)
end

function StealService.slap(player)
	local data = State.getPlayer(player)
	if not data then
		return false
	end
	local now = os.clock()
	if now < data.slapCooldownUntil then
		return false
	end
	data.slapCooldownUntil = now + Config.SlapCooldown

	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	for _, victim in pairs(State.players) do
		if victim.player ~= player and victim.carrying then
			local victimChar = victim.player.Character
			local victimRoot = victimChar and victimChar:FindFirstChild("HumanoidRootPart")
			if victimRoot and (victimRoot.Position - root.Position).Magnitude <= Config.SlapRange then
				local brainrotId = victim.carrying
				victim.carrying = nil
				StealService.returnToOwner(brainrotId)
				local humanoid = victimChar:FindFirstChildOfClass("Humanoid")
				if humanoid then
					local dir = (victimRoot.Position - root.Position).Unit
					victimRoot.AssemblyLinearVelocity = dir * 40 + Vector3.new(0, 25, 0)
					humanoid:ChangeState(Enum.HumanoidStateType.Physics)
					task.delay(0.5, function()
						if humanoid.Parent then
							humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
						end
					end)
				end
				Remotes.notify(player, "SLAP! You knocked the brainrot out of " .. victim.player.Name .. "'s hands!", "good")
				Remotes.notify(victim.player, player.Name .. " slapped you! Your stolen brainrot ran home.", "bad")
				return true
			end
		end
	end
	return false
end

function StealService.start()
	RunService.Heartbeat:Connect(function(_dt)
		-- Carried brainrots ride above their carrier's head.
		for _, data in pairs(State.players) do
			if data.carrying then
				local entry = State.owned[data.carrying]
				local character = data.player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not entry or not root then
					-- Carrier left or died mid-theft: the brainrot goes home.
					if entry then
						StealService.returnToOwner(data.carrying)
					end
					data.carrying = nil
				else
					entry.model:PivotTo(CFrame.new(root.Position + Vector3.new(0, Config.CarryHeight, 0)))
					-- Bank it: carrier reached their own base with a free slot.
					local base = State.bases[data.baseIndex]
					if base and (root.Position - base.center).Magnitude <= Config.BaseSafeRadius then
						local slotIndex = BaseService.freeSlotIndex(data.baseIndex)
						if slotIndex then
							data.carrying = nil
							entry.ownerId = data.player.UserId
							BaseService.placeInSlot(entry, data.baseIndex, slotIndex)
							local QuestService = require(script.Parent.QuestService)
							QuestService.addProgress(data.player, "steal", 1)
							Remotes.notify(data.player, "Banked " .. entry.def.name .. "! It now earns for YOU: " .. entry.income .. "/s.", "good")
						end
					end
				end
			end
		end
	end)
end

return StealService

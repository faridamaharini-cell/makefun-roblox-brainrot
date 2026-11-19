-- SpawnService: rolls a random brainrot, builds it, and walks it down the
-- conveyor. Rarity, character and mutation are rolled fresh per spawn; the
-- walker despawns at the end of the line if nobody buys it.
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotFactory = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotFactory"))
local State = require(script.Parent.State)
local EconomyService = require(script.Parent.EconomyService)

local SpawnService = {}

local walkersFolder
local spawnAccumulator = 0

local function countWalkers()
	local n = 0
	for _ in pairs(State.walkers) do
		n += 1
	end
	return n
end

function SpawnService.spawnOne(forceRarity)
	local rarityName = forceRarity or BrainrotData.rollRarity()
	local def = BrainrotData.rollCharacter(rarityName)
	local mutation = BrainrotData.rollMutation()
	local model = BrainrotFactory.build(def, mutation)
	model.Parent = walkersFolder
	model:PivotTo(CFrame.new(0, 1, Config.ConveyorStartZ))

	local id = State.nextBrainrotId
	State.nextBrainrotId += 1
	model:SetAttribute("BrainrotId", id)
	State.walkers[id] = {
		model = model,
		def = def,
		mutation = mutation,
		price = BrainrotData.priceFor(def, mutation),
		income = BrainrotData.incomeFor(def, mutation),
	}

	local prompt = model:FindFirstChild("InteractPrompt", true)
	if prompt then
		prompt.ActionText = "Buy " .. BrainrotData.formatMoney(BrainrotData.priceFor(def, mutation))
		prompt.ObjectText = def.name
		prompt.Triggered:Connect(function(player)
			EconomyService.tryBuy(player, id)
		end)
	end
	return id
end

function SpawnService.start()
	walkersFolder = Instance.new("Folder")
	walkersFolder.Name = "Walkers"
	walkersFolder.Parent = game:GetService("Workspace")

	-- Seed the conveyor so the first player sees brainrots at once.
	for _ = 1, 3 do
		SpawnService.spawnOne()
	end

	RunService.Heartbeat:Connect(function(dt)
		spawnAccumulator += dt
		if spawnAccumulator >= Config.SpawnInterval and countWalkers() < Config.MaxWalkers then
			spawnAccumulator = 0
			SpawnService.spawnOne()
		end

		-- Walk every brainrot down the conveyor (+Z); bob while walking.
		local now = os.clock()
		for id, walker in pairs(State.walkers) do
			local model = walker.model
			if not model.Parent then
				State.walkers[id] = nil
			else
				local pivot = model:GetPivot()
				local z = pivot.Position.Z + Config.WalkerSpeed * dt
				if z >= Config.ConveyorEndZ then
					model:Destroy()
					State.walkers[id] = nil
				else
					local bob = math.sin(now * 6 + id) * 0.15
					model:PivotTo(CFrame.new(0, 1 + bob, z))
				end
			end
		end
	end)
end

return SpawnService

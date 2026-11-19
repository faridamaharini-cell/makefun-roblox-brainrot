-- SpawnService: rolls a random brainrot, builds it, and walks it down the
-- conveyor. Rarity, character and mutation are rolled fresh per spawn; the
-- walker despawns at the end of the line if nobody buys it. During a meteor
-- shower, fresh walkers have a real shot at the Shadow and Lava mutations.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local BrainrotFactory = require(Shared:WaitForChild("BrainrotFactory"))
local State = require(script.Parent.State)
local EconomyService = require(script.Parent.EconomyService)

local SpawnService = {}

local walkersFolder = nil

local function countWalkers()
	local n = 0
	for _ in pairs(State.walkers) do
		n += 1
	end
	return n
end

-- During a meteor shower, one in three fresh walkers rolls Shadow or Lava
-- instead of the normal mutation table (their natural weights are tiny).
local function rollMutationForSpawn()
	if State.meteorActive then
		local roll = math.random()
		if roll <= 0.15 then
			local shadow = BrainrotData.getMutation("Shadow")
			if shadow.name == "Shadow" then
				return shadow
			end
		elseif roll <= 0.3 then
			local lava = BrainrotData.getMutation("Lava")
			if lava.name == "Lava" then
				return lava
			end
		end
	end
	return BrainrotData.rollMutation()
end

function SpawnService.spawnOne(forceRarity)
	local rarityName = forceRarity or BrainrotData.rollRarity()
	local def = BrainrotData.rollCharacter(rarityName)
	local mutation = rollMutationForSpawn()

	local id = State.nextBrainrotId
	State.nextBrainrotId += 1

	local model = BrainrotFactory.buildBrainrotModel(def, mutation)
	model:SetAttribute("BrainrotId", id)
	-- Pivot is the Body centre: place it PIVOT_ABOVE_FEET above the
	-- conveyor top (Y=1) so the feet stand on the belt, not under it.
	model:PivotTo(CFrame.new(0, 1 + BrainrotFactory.PIVOT_ABOVE_FEET, Config.ConveyorStartZ))
	model.Parent = walkersFolder

	local prompt = model:FindFirstChild("InteractPrompt", true)
	if prompt then
		prompt.ActionText = "Buy"
		prompt.ObjectText = def.name
		prompt.Triggered:Connect(function(player)
			EconomyService.tryBuy(player, id)
		end)
	end

	State.walkers[id] = {
		model = model,
		def = def,
		mutation = mutation,
		price = BrainrotData.priceFor(def, mutation),
		income = BrainrotData.incomeFor(def, mutation),
	}
	return id
end

function SpawnService.start()
	walkersFolder = Instance.new("Folder")
	walkersFolder.Name = "Walkers"
	walkersFolder.Parent = Workspace

	-- Two walkers on the belt from the first second, so the island is never
	-- empty while the first spawn timer runs.
	SpawnService.spawnOne()
	SpawnService.spawnOne()

	task.spawn(function()
		while true do
			task.wait(Config.SpawnInterval)
			if countWalkers() < Config.MaxWalkers then
				SpawnService.spawnOne()
			end
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		for id, walker in pairs(State.walkers) do
			local model = walker.model
			if not model.Parent then
				State.walkers[id] = nil
			else
				local pos = model:GetPivot().Position
				local newZ = pos.Z + Config.WalkerSpeed * dt
				if newZ >= Config.ConveyorEndZ then
					model:Destroy()
					State.walkers[id] = nil
				else
					-- A gentle waddle: side-to-side sway plus a tiny bob.
					local sway = math.sin(os.clock() * 4 + id) * 0.8
					model:PivotTo(CFrame.new(sway, 1 + BrainrotFactory.PIVOT_ABOVE_FEET + math.abs(math.sin(os.clock() * 6 + id)) * 0.15, newZ))
				end
			end
		end
	end)
end

return SpawnService

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
	-- v4 pivot: placeOnSurface MEASURES the live model's lowest point
	-- (GetBoundingBox) and corrects Y until the feet sit exactly on the
	-- conveyor top (Y=1). The old constant PIVOT_ABOVE_FEET placement
	-- sank bodies under the belt in v3.6. Store the measured offset so
	-- the Heartbeat waddle below reuses it instead of the constant.
	local groundOffset = BrainrotFactory.placeOnSurface(model, 1, 0, Config.ConveyorStartZ)
	BrainrotFactory.staggerLabel(model, id)
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
		groundOffset = groundOffset,
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
					-- v4: pivot Y uses the walker's MEASURED ground offset
					-- (stored at spawn), never the PIVOT_ABOVE_FEET
					-- constant — the bob only ever lifts the feet, it
					-- never re-sinks them.
					local sway = math.sin(os.clock() * 4 + id) * 0.8
					local offset = walker.groundOffset or BrainrotFactory.PIVOT_ABOVE_FEET
					model:PivotTo(CFrame.new(sway, 1 + offset + math.abs(math.sin(os.clock() * 6 + id)) * 0.15, newZ))
				end
			end
		end
	end)
end

return SpawnService

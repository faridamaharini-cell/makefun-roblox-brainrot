-- Brainrot Bazaar server entry point: builds the world, wires the services,
-- and owns the player lifecycle (join, spawn at your base, leave).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local WorldBuilder = require(script.WorldBuilder)
local State = require(script.State)
local Remotes = require(script.Remotes)
local BaseService = require(script.BaseService)
local EconomyService = require(script.EconomyService)
local SpawnService = require(script.SpawnService)
local StealService = require(script.StealService)
local RebirthService = require(script.RebirthService)
local HazardService = require(script.HazardService)

-- Build the world first: bases must exist before any player is assigned one.
State.bases = WorldBuilder.build()
EconomyService.start()
SpawnService.start()
StealService.start()
HazardService.start()

local function setupLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = math.floor(data.money)
	money.Parent = leaderstats
	local income = Instance.new("IntValue")
	income.Name = "Income"
	income.Value = 0
	income.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats
end

local function onCharacterAdded(player, character)
	local data = State.getPlayer(player)
	if not data then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	local base = State.bases[data.baseIndex]
	if base then
		-- Spawn on your own base's green pad, facing the conveyor.
		character:PivotTo(CFrame.new(base.spawnPos + Vector3.new(0, 2, 0)))
	end
end

local function onPlayerAdded(player)
	local data = State.newPlayerData(player)
	State.players[player.UserId] = data
	setupLeaderstats(player, data)
	BaseService.assignBase(player)
	Remotes.notify(player, "Welcome to BRAINROT BAZAAR! Buy brainrots off the conveyor, bank them on your base, and watch out for thieves and tsunamis!", "info")
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player)
	local data = State.getPlayer(player)
	if not data then
		return
	end
	-- A stolen brainrot never leaves with the thief: send it home.
	if data.carrying then
		StealService.returnToOwner(data.carrying)
		data.carrying = nil
	end
	State.players[player.UserId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Remote actions from the client HUD and keybinds.
Remotes.BuyNearest.OnServerEvent:Connect(function(player)
	local id = EconomyService.nearestWalker(player, Config.BuyRange)
	if id then
		EconomyService.tryBuy(player, id)
	end
end)
Remotes.LockBase.OnServerEvent:Connect(function(player)
	BaseService.lockBase(player)
end)
Remotes.Rebirth.OnServerEvent:Connect(function(player)
	RebirthService.tryRebirth(player)
end)
Remotes.Slap.OnServerEvent:Connect(function(player)
	StealService.slap(player)
end)

-- Money tick, once a second.
task.spawn(function()
	while true do
		task.wait(Config.TickInterval)
		EconomyService.tick()
	end
end)

-- Idle bob for brainrots sitting on their base slots.
RunService.Heartbeat:Connect(function(_dt)
	local now = os.clock()
	for id, entry in pairs(State.owned) do
		if entry.model.Parent and entry.model:GetAttribute("State") == "owned" then
			local base = State.bases[entry.baseIndex]
			if base and entry.slotIndex then
				local slotPos = base.slots[entry.slotIndex]
				local bob = math.sin(now * 2 + id) * 0.2
				entry.model:PivotTo(CFrame.new(slotPos + Vector3.new(0, 0.1 + bob, 0)))
			end
		end
	end
end)

print("Brainrot Bazaar server ready: " .. #State.bases .. " bases, conveyor live.")

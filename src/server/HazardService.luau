-- HazardService: the island's three events.
--   Tsunami wave: every 90s a 15s warning goes out, then a wall of water
--     sweeps the map. Players on their own base are safe (and earn a
--     "survive" quest tick); anyone caught outside is sent back to spawn
--     and drops whatever they were carrying.
--   Golden Hour: every 240s, all income is doubled for 60s.
--   Meteor Shower: every 180s for 45s, meteors rain down — touch one for
--     bonus cash — and fresh conveyor walkers can roll Shadow/Lava.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local HazardService = {}

local wavePart = nil
local waveDirection = 1
local waveCycleStart = 0
local goldenCycleStart = 0
local meteorCycleStart = 0
local waveWarned = false
local goldenWarned = false
local meteorWarned = false

local function buildWave()
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(8, 26, Config.WaveWidth)
	wave.Color = Color3.fromRGB(40, 140, 255)
	wave.Material = Enum.Material.Neon
	wave.Transparency = 0.35
	wave.Anchored = true
	wave.CanCollide = false
	wave.TopSurface = Enum.SurfaceType.Smooth
	wave.BottomSurface = Enum.SurfaceType.Smooth
	wave.Parent = Workspace
	return wave
end

-- A player is safe only while standing on their own base.
local function isPlayerSafe(player)
	local data = State.getPlayer(player)
	if not data or data.baseIndex == 0 then
		return false
	end
	local base = State.bases[data.baseIndex]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not base or not root then
		return false
	end
	return (root.Position - base.center).Magnitude <= Config.BaseSafeRadius
end

local function sendBackToSpawn(player)
	local data = State.getPlayer(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	local base = State.bases[data.baseIndex]
	local spawn = (base and base.spawnPos) or Vector3.new(0, 1, -160)
	character:PivotTo(CFrame.new(spawn + Vector3.new(0, 2, 0)))
	root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
end

function HazardService.triggerWave()
	if State.waveActive then
		return
	end
	State.waveActive = true
	State.waveEndsAt = os.clock() + (360 / Config.WaveSpeed)
	waveWarned = false
	waveDirection = -waveDirection
	wavePart = buildWave()
	local startX = -waveDirection * 180
	local endX = waveDirection * 180
	wavePart.Position = Vector3.new(startX, 10, 0)
	Remotes.notify(nil, "TSUNAMI! Run to your base NOW!", "wave")

	local hit = {}
	local QuestService = require(script.Parent.QuestService)
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not wavePart or not wavePart.Parent then
			conn:Disconnect()
			return
		end
		local x = wavePart.Position.X + waveDirection * Config.WaveSpeed * dt
		wavePart.Position = Vector3.new(x, 10, 0)
		for _, data in pairs(State.players) do
			local player = data.player
			if not hit[player.UserId] then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.X - x) <= 6 then
					hit[player.UserId] = true
					if isPlayerSafe(player) then
						QuestService.addProgress(player, "survive", 1)
						Remotes.notify(player, "The wave passed over your base — you survived!", "good")
					else
						if data.carrying then
							local brainrotId = data.carrying
							data.carrying = nil
							local StealService = require(script.Parent.StealService)
							StealService.returnToOwner(brainrotId)
							Remotes.notify(player, "The wave knocked your stolen brainrot away and sent you home!", "bad")
						else
							Remotes.notify(player, "The tsunami caught you outside your base!", "bad")
						end
						sendBackToSpawn(player)
					end
				end
			end
		end
		if (waveDirection > 0 and x >= endX) or (waveDirection < 0 and x <= endX) then
			conn:Disconnect()
			wavePart:Destroy()
			wavePart = nil
			State.waveActive = false
			waveCycleStart = os.clock()
			Remotes.notify(nil, "The wave is gone. Next one in " .. Config.WaveCycle .. "s — keep earning!", "info")
		end
	end)
end

function HazardService.triggerGoldenHour()
	if State.goldenHourActive then
		return
	end
	State.goldenHourActive = true
	goldenCycleStart = os.clock() -- restart the cycle clock so a manual
	-- trigger (tour) does not make the next automatic one fire early
	local endsAt = os.clock() + Config.GoldenHourDuration
	State.eventEndsAt = endsAt
	Remotes.EventUpdate:FireAllClients("golden", true, endsAt)
	Remotes.notify(nil, "GOLDEN HOUR! All income is DOUBLED for " .. Config.GoldenHourDuration .. "s!", "event")
	task.delay(Config.GoldenHourDuration, function()
		State.goldenHourActive = false
		Remotes.EventUpdate:FireAllClients("golden", false, 0)
		Remotes.notify(nil, "Golden Hour is over. Next one in " .. Config.GoldenHourCycle .. "s.", "info")
	end)
end

local function spawnMeteor(meteorsFolder)
	local meteor = Instance.new("Part")
	meteor.Name = "Meteor"
	meteor.Shape = Enum.PartType.Ball
	meteor.Size = Vector3.new(3, 3, 3)
	meteor.Color = Color3.fromRGB(255, 120, 30)
	meteor.Material = Enum.Material.Neon
	meteor.Anchored = true
	meteor.CanCollide = false
	meteor.Position = Vector3.new(math.random(-160, 160), 120, math.random(-140, 150))
	meteor.Parent = meteorsFolder
	local claimed = false
	meteor.Touched:Connect(function(hitPart)
		if claimed then
			return
		end
		local character = hitPart:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local data = player and State.getPlayer(player)
		if not data then
			return
		end
		claimed = true
		local bonus = 250 + 250 * data.rebirths
		data.money += bonus
		Remotes.notify(player, "You caught a meteor! +" .. bonus .. " cash!", "good")
		Remotes.MoneyUpdate:FireClient(player, math.floor(data.money), State.incomePerSecond(player))
		meteor:Destroy()
	end)
	task.spawn(function()
		while meteor.Parent do
			task.wait(0.05)
			meteor.Position -= Vector3.new(0, 3, 0)
			if meteor.Position.Y <= 2 then
				meteor:Destroy()
				break
			end
		end
	end)
end

function HazardService.triggerMeteor()
	if State.meteorActive then
		return
	end
	State.meteorActive = true
	meteorCycleStart = os.clock() -- restart the cycle clock (see Golden Hour)
	local endsAt = os.clock() + Config.MeteorDuration
	State.eventEndsAt = endsAt
	Remotes.EventUpdate:FireAllClients("meteor", true, endsAt)
	Remotes.notify(nil, "METEOR SHOWER! Catch falling meteors for bonus cash — and watch the conveyor for Shadow and Lava brainrots!", "event")
	local meteorsFolder = Instance.new("Folder")
	meteorsFolder.Name = "Meteors"
	meteorsFolder.Parent = Workspace
	task.spawn(function()
		while State.meteorActive do
			spawnMeteor(meteorsFolder)
			task.wait(0.7)
		end
	end)
	task.delay(Config.MeteorDuration, function()
		State.meteorActive = false
		meteorsFolder:Destroy()
		Remotes.EventUpdate:FireAllClients("meteor", false, 0)
		Remotes.notify(nil, "The meteor shower is over.", "info")
	end)
end

function HazardService.start()
	waveCycleStart = os.clock()
	goldenCycleStart = os.clock()
	meteorCycleStart = os.clock()
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			-- Tsunami: warn once 15s before, then fire.
			if not State.waveActive then
				local elapsed = now - waveCycleStart
				if not waveWarned and elapsed >= Config.WaveCycle - Config.WaveWarning then
					waveWarned = true
					Remotes.notify(nil, "TSUNAMI in " .. Config.WaveWarning .. "s! Get ready to run home!", "wave")
				end
				if elapsed >= Config.WaveCycle then
					waveWarned = false
					HazardService.triggerWave()
				end
			end
			-- Golden Hour cycle.
			if not State.goldenHourActive and not goldenWarned and now - goldenCycleStart >= Config.GoldenHourCycle - 10 then
				goldenWarned = true
				Remotes.notify(nil, "Golden Hour in 10s — get your best brainrots earning!", "event")
			end
			if not State.goldenHourActive and now - goldenCycleStart >= Config.GoldenHourCycle then
				goldenWarned = false
				goldenCycleStart = now
				HazardService.triggerGoldenHour()
			end
			-- Meteor shower cycle.
			if not State.meteorActive and not meteorWarned and now - meteorCycleStart >= Config.MeteorCycle - 10 then
				meteorWarned = true
				Remotes.notify(nil, "Meteor shower in 10s — keep your eyes on the sky!", "event")
			end
			if not State.meteorActive and now - meteorCycleStart >= Config.MeteorCycle then
				meteorWarned = false
				meteorCycleStart = now
				HazardService.triggerMeteor()
			end
		end
	end)
end

return HazardService

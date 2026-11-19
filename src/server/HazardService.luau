-- HazardService: the tsunami wave. Every cycle a warning goes out, then a
-- giant wall of water sweeps the map from one side to the other. Players
-- caught outside their own base get flung and drop whatever they are
-- carrying; players standing on their base are safe.
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local HazardService = {}

local wavePart = nil
local waveDirection = 1
local cycleStart = os.clock()

local function buildWave()
	local part = Instance.new("Part")
	part.Name = "TsunamiWave"
	part.Size = Vector3.new(8, 26, Config.WaveWidth)
	part.Color = Color3.fromRGB(40, 140, 255)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.35
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = game:GetService("Workspace")
	return part
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

local function flingPlayer(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	root.AssemblyLinearVelocity = Vector3.new(waveDirection * 50, 35, 0)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	task.delay(0.6, function()
		if humanoid.Parent then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

function HazardService.triggerWave()
	if State.waveActive then
		return
	end
	State.waveActive = true
	waveDirection = -waveDirection
	wavePart = buildWave()
	local startX = -waveDirection * 180
	local endX = waveDirection * 180
	wavePart.Position = Vector3.new(startX, 10, 0)
	Remotes.notify(nil, "🌊 TSUNAMI! Run to your base NOW!", "wave")

	local hit = {}
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
						Remotes.notify(player, "The wave passed over your base — you are safe!", "good")
					else
						flingPlayer(player)
						if data.carrying then
							local brainrotId = data.carrying
							data.carrying = nil
							local StealService = require(script.Parent.StealService)
							StealService.returnToOwner(brainrotId)
							Remotes.notify(player, "The wave knocked your stolen brainrot away!", "bad")
						else
							Remotes.notify(player, "The tsunami caught you outside your base!", "bad")
						end
					end
				end
			end
		end
		if (waveDirection > 0 and x >= endX) or (waveDirection < 0 and x <= endX) then
			conn:Disconnect()
			wavePart:Destroy()
			wavePart = nil
			State.waveActive = false
			cycleStart = os.clock()
			Remotes.notify(nil, "The wave is gone. Next one in " .. Config.WaveCycle .. "s — keep earning!", "info")
		end
	end)
end

function HazardService.start()
	cycleStart = os.clock()
	local warned = false
	task.spawn(function()
		while true do
			task.wait(1)
			local elapsed = os.clock() - cycleStart
			if not State.waveActive and not warned and elapsed >= Config.WaveCycle - Config.WaveWarning then
				warned = true
				Remotes.notify(nil, "⚠️ TSUNAMI in " .. Config.WaveWarning .. "s! Get ready to run home!", "wave")
			end
			if not State.waveActive and elapsed >= Config.WaveCycle then
				warned = false
				HazardService.triggerWave()
			end
		end
	end)
end

return HazardService

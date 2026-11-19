-- RebirthService: reset money and brainrots for a permanent income
-- multiplier. Cost doubles every rebirth and the multiplier doubles too,
-- so the ladder never ends — but each rung costs twice the last. A stolen
-- brainrot being carried is never yours to burn: it goes home first.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local RebirthService = {}

function RebirthService.tryRebirth(player)
	local data = State.getPlayer(player)
	if not data then
		return false
	end
	local cost = Config.rebirthCost(data.rebirths)
	if data.money < cost then
		Remotes.notify(player, "Rebirth costs " .. BrainrotData.formatMoney(cost) .. " — you have " .. BrainrotData.formatMoney(data.money) .. ". Keep earning!", "bad")
		return false
	end

	if data.carrying then
		local StealService = require(script.Parent.StealService)
		StealService.returnToOwner(data.carrying)
		data.carrying = nil
	end
	for id, entry in pairs(State.owned) do
		if entry.ownerId == player.UserId then
			entry.model:Destroy()
			State.owned[id] = nil
		end
	end

	data.money = Config.StartingMoney
	data.rebirths += 1
	-- Poseidon Tier: one small gold pedestal per rebirth, parented into
	-- the player's base folder near the base sign (back edge, z +13, clear
	-- of the slot pads). Four pedestals fit in a row before wrapping to a
	-- second row 4 studs further back, so rebirths 5-8 never land on the
	-- same spot as 1-4.
	local base = State.bases[data.baseIndex]
	if base and base.folder then
		local n = data.rebirths
		local pedestal = Instance.new("Part")
		pedestal.Name = "PoseidonPedestal" .. n
		pedestal.Shape = Enum.PartType.Cylinder
		-- Round in the horizontal plane: with the 90-degree Z-rotation
		-- the cylinder stands upright, so Size.x is its height and
		-- Size.y == Size.z is its diameter (3). Height 3 with the
		-- centre 1.5 above base.center (y=1) puts its base flush on
		-- the platform top.
		pedestal.Size = Vector3.new(3, 3, 3)
		pedestal.Color = Color3.fromRGB(255, 205, 60)
		pedestal.Material = Enum.Material.Neon
		pedestal.Anchored = true
		pedestal.CanCollide = true
		pedestal.TopSurface = Enum.SurfaceType.Smooth
		pedestal.BottomSurface = Enum.SurfaceType.Smooth
		pedestal.CFrame = CFrame.new(base.center + Vector3.new((((n - 1) % 4) * 3.5) - 5.25, 1.5, 13 + math.floor((n - 1) / 4) * 4)) * CFrame.Angles(0, 0, math.rad(90))
		pedestal.Parent = base.folder
	end
	if data.rebirths == 1 then
		Remotes.notify(player, "POSEIDON TIER UNLOCKED — +1 pedestal on your base!", "event")
	else
		Remotes.notify(player, "Poseidon Tier " .. data.rebirths .. " — another gold pedestal on your base!", "event")
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rebirthValue = leaderstats:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = data.rebirths
		end
	end
	local QuestService = require(script.Parent.QuestService)
	QuestService.addProgress(player, "rebirth", 1)
	Remotes.MoneyUpdate:FireClient(player, math.floor(data.money), 0)
	Remotes.notify(player, "REBIRTH " .. data.rebirths .. "! All income is now x" .. Config.rebirthMultiplier(data.rebirths) .. " forever.", "good")
	return true
end

function RebirthService.start()
	-- Wired from init: Remotes.Rebirth -> tryRebirth. Kept as a start() so
	-- every service has the same lifecycle shape.
end

return RebirthService

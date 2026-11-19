-- Brainrot Bazaar client: HUD wiring, keybinds and toasts.
-- Movement stays on Roblox's own controls (WASD / arrow keys). Our actions
-- use ContextActionService so they never fight the camera scripts: E buys
-- the nearest brainrot, F slaps a thief, L locks your base, R rebirths.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local Config = require(Shared:WaitForChild("Config"))
local HUD = require(script.HUD)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyNearest = remotes:WaitForChild("BuyNearest")
local lockBase = remotes:WaitForChild("LockBase")
local rebirth = remotes:WaitForChild("Rebirth")
local slap = remotes:WaitForChild("Slap")
local notify = remotes:WaitForChild("Notify")

local hud = HUD.build(player)

local toastUntil = 0
local function showToast(message, kind)
	local color = Color3.fromRGB(255, 255, 255)
	if kind == "good" then
		color = Color3.fromRGB(120, 255, 140)
	elseif kind == "bad" then
		color = Color3.fromRGB(255, 100, 100)
	elseif kind == "wave" then
		color = Color3.fromRGB(90, 180, 255)
	end
	hud.toastLabel.Text = message
	hud.toastLabel.TextColor3 = color
	toastUntil = os.clock() + 4
end

notify.OnClientEvent:Connect(showToast)

-- Keep the toast visible for 4 seconds, then clear it.
RunService.RenderStepped:Connect(function()
	if hud.toastLabel.Text ~= "" and os.clock() > toastUntil then
		hud.toastLabel.Text = ""
	end
end)

-- Money / income / rebirth readout from leaderstats.
local leaderstats = player:WaitForChild("leaderstats")
local moneyValue = leaderstats:WaitForChild("Money")
local incomeValue = leaderstats:WaitForChild("Income")
local rebirthValue = leaderstats:WaitForChild("Rebirths")

local function refreshMoney()
	hud.moneyLabel.Text = BrainrotData.formatMoney(moneyValue.Value)
	local mult = Config.rebirthMultiplier(rebirthValue.Value)
	hud.incomeLabel.Text = "+" .. BrainrotData.formatMoney(incomeValue.Value) .. "/s  •  Rebirth x" .. mult .. "  •  Next rebirth: " .. BrainrotData.formatMoney(Config.rebirthCost(rebirthValue.Value))
end
moneyValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
incomeValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
rebirthValue:GetPropertyChangedSignal("Value"):Connect(refreshMoney)
refreshMoney()

-- Buttons do exactly what the keys do.
hud.lockButton.MouseButton1Click:Connect(function()
	lockBase:FireServer()
end)
hud.rebirthButton.MouseButton1Click:Connect(function()
	rebirth:FireServer()
end)

local function bindAction(name, key, remote)
	ContextActionService:BindAction(name, function(_actionName, inputState, _inputObject)
		if inputState == Enum.UserInputState.Begin then
			remote:FireServer()
		end
	end, false, key)
end
bindAction("BuyNearest", Enum.KeyCode.E, buyNearest)
bindAction("SlapThief", Enum.KeyCode.F, slap)
bindAction("LockBase", Enum.KeyCode.L, lockBase)
bindAction("Rebirth", Enum.KeyCode.R, rebirth)

-- Context line: name, rarity, price and income of the nearest brainrot.
local function nearestBrainrotModel(maxDistance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, math.huge
	end
	local best = nil
	local bestDist = maxDistance
	for _, folder in ipairs({ game:GetService("Workspace"):FindFirstChild("Walkers"), game:GetService("Workspace"):FindFirstChild("OwnedBrainrots") }) do
		if folder then
			for _, model in ipairs(folder:GetChildren()) do
				if model:IsA("Model") then
					local dist = (model:GetPivot().Position - root.Position).Magnitude
					if dist < bestDist then
						bestDist = dist
						best = model
					end
				end
			end
		end
	end
	return best, bestDist
end

local scanAccumulator = 0
RunService.RenderStepped:Connect(function(dt)
	scanAccumulator += dt
	if scanAccumulator < 0.25 then
		return
	end
	scanAccumulator = 0
	local model, dist = nearestBrainrotModel(16)
	if not model then
		hud.contextLabel.Text = "Walk up to a brainrot on the conveyor — press E to buy it!"
		return
	end
	local defId = model:GetAttribute("DefId")
	local def = defId and BrainrotData.getCharacter(defId)
	local state = model:GetAttribute("State")
	if not def then
		return
	end
	local rarity = BrainrotData.getRarity(def.rarity)
	local line = def.name .. "  •  " .. rarity.name .. " " .. (model:GetAttribute("Mutation") or "")
	if state == "walking" then
		line ..= "  •  " .. BrainrotData.formatMoney(model:GetAttribute("Price") or 0) .. "  •  " .. BrainrotData.formatMoney(model:GetAttribute("Income") or 0) .. "/s  •  Press E to BUY"
	elseif state == "owned" then
		local ownerId = model:GetAttribute("OwnerUserId")
		if ownerId == player.UserId then
			line ..= "  •  YOURS  •  " .. BrainrotData.formatMoney(model:GetAttribute("Income") or 0) .. "/s"
		else
			line ..= "  •  Hold E near it to STEAL (if the base is unlocked!)"
		end
	elseif state == "carried" then
		line ..= "  •  BEING CARRIED — slap the thief with F!"
	end
	_ = dist
	hud.contextLabel.Text = line
end)

print("Brainrot Bazaar client ready.")

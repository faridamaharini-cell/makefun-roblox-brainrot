-- Brainrot Bay client: HUD wiring, keybinds, remote listeners and the
-- nearest-brainrot hint line.
-- Movement stays on Roblox's own controls (WASD / arrow keys). Every
-- action key goes through ContextActionService, never
-- UserInputService.InputBegan with gameProcessedEvent, because the
-- camera scripts swallow arrow keys and processed input: E buys the
-- nearest brainrot, F slaps a thief, L locks your base, R rebirths,
-- Q claims the current quest, G gifts a brainrot to a friend.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local Config = require(Shared:WaitForChild("Config"))
local Economy = require(Shared:WaitForChild("Economy"))
local Quests = require(Shared:WaitForChild("Quests"))
local HUD = require(script:WaitForChild("HUD"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

-- The server creates every remote in ReplicatedStorage/Remotes. Wait
-- briefly for each one; a missing remote only warns and disables that
-- one action instead of freezing the whole client at startup.
local function waitRemote(name)
	local remote = remotesFolder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	remote = remotesFolder:WaitForChild(name, 15)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	warn("[Brainrot Bay] Remote missing after 15s: " .. name)
	return nil
end

local buyNearest = waitRemote("BuyNearest")
local lockBase = waitRemote("LockBase")
local rebirth = waitRemote("Rebirth")
local slap = waitRemote("Slap")
local notify = waitRemote("Notify")
local claimQuest = waitRemote("ClaimQuest")
local upgradeBase = waitRemote("UpgradeBase")
local giftBrainrot = waitRemote("GiftBrainrot")
local moneyUpdate = waitRemote("MoneyUpdate")
local questUpdate = waitRemote("QuestUpdate")
local upgradeUpdate = waitRemote("UpgradeUpdate")
local eventUpdate = waitRemote("EventUpdate")

local function fire(remote, ...)
	if remote then
		remote:FireServer(...)
	else
		HUD.toast("That action is not ready yet — try again in a moment.", "bad")
	end
end

HUD.build(player)
HUD.setMoney(Config.StartingMoney or 100, 0)
HUD.setRebirths(0)
HUD.setContext("Walk up to a brainrot on the conveyor — press E to buy it!")

-- Upgrade costs come from Shared.Economy, the same module the server
-- charges from, so the buttons can never disagree with the server:
-- level-0 costs are capacity $1,000, income $2,500, lock $800, and they
-- grow x3 per level. The server pushes the next costs after every
-- purchase (UpgradeUpdate), so the buttons stay right as levels rise.
local upgradeCosts = {}
for _, kind in ipairs({ "capacity", "income", "lock" }) do
	upgradeCosts[kind] = Economy.upgradeCost(kind, 0) or 0
end
HUD.setUpgradeCosts(upgradeCosts)

-- Rebirth count, if the server publishes leaderstats (v1 did).
local leaderstats = player:FindFirstChild("leaderstats")
if leaderstats then
	local rebirthsValue = leaderstats:FindFirstChild("Rebirths")
	if rebirthsValue then
		HUD.setRebirths(rebirthsValue.Value)
		rebirthsValue:GetPropertyChangedSignal("Value"):Connect(function()
			HUD.setRebirths(rebirthsValue.Value)
		end)
	end
end

-- Server pushes: money, quests, events and toasts.
if moneyUpdate then
	moneyUpdate.OnClientEvent:Connect(function(money, incomePerSecond)
		HUD.setMoney(money or 0, incomePerSecond or 0)
	end)
end

-- The server sends the whole quest board (QuestUpdate fires with one
-- table: questId -> { progress, claimed }), never a single quest's
-- fields, so the client reads titles/targets from Shared.Quests -- the
-- same definitions the server counts progress against. The tracker
-- shows the first unclaimed quest in board order, preferring one still
-- in progress; claiming sends that quest's id back (ClaimQuest needs
-- it -- firing with no id is rejected server-side as "Unknown quest").
local currentQuestId = nil

local function refreshQuestBoard(board)
	if typeof(board) ~= "table" then
		return
	end
	local current = nil
	for _, quest in ipairs(Quests.Quests) do
		local entry = board[quest.id]
		if entry and not entry.claimed then
			current = { quest = quest, entry = entry }
			if (entry.progress or 0) < quest.target then
				break
			end
		end
	end
	if not current then
		currentQuestId = nil
		HUD.setQuest("All quests complete!", 0, 1, true)
		return
	end
	currentQuestId = current.quest.id
	HUD.setQuest(current.quest.title, current.entry.progress, current.quest.target, current.entry.claimed)
end

local function claimCurrentQuest()
	if currentQuestId then
		fire(claimQuest, currentQuestId)
	else
		HUD.toast("No quest ready to claim yet — check the quest board.", "bad")
	end
end

if questUpdate then
	questUpdate.OnClientEvent:Connect(refreshQuestBoard)
end

if upgradeUpdate then
	upgradeUpdate.OnClientEvent:Connect(function(nextCosts)
		HUD.setUpgradeCosts(nextCosts)
	end)
end

if notify then
	notify.OnClientEvent:Connect(function(message, kind)
		HUD.toast(message, kind)
	end)
end

-- Live event state, with a ticking countdown rendered on the banner.
local currentEvent = { name = "none", endsAtUnix = 0 }

local function formatCountdown(secondsLeft)
	local minutes = math.floor(secondsLeft / 60)
	local seconds = math.floor(secondsLeft % 60)
	if minutes > 0 then
		return string.format("%d:%02d", minutes, seconds)
	end
	return tostring(seconds) .. "s"
end

local function refreshEventBanner()
	if currentEvent.name == "none" or currentEvent.endsAtUnix <= 0 then
		HUD.setEvent(nil)
		return
	end
	local remaining = currentEvent.endsAtUnix - os.time()
	if remaining <= 0 then
		HUD.setEvent(nil)
		return
	end
	if currentEvent.name == "wave" then
		HUD.setEvent("TSUNAMI IN " .. formatCountdown(remaining) .. " — GET TO HIGH GROUND!", "wave")
	elseif currentEvent.name == "golden" then
		HUD.setEvent("GOLDEN HOUR — x2 INCOME! " .. formatCountdown(remaining) .. " left", "event")
	elseif currentEvent.name == "meteor" then
		HUD.setEvent("METEOR SHOWER! " .. formatCountdown(remaining), "event")
	else
		HUD.setEvent(nil)
	end
end

if eventUpdate then
	eventUpdate.OnClientEvent:Connect(function(eventName, endsAtUnix)
		currentEvent.name = eventName or "none"
		currentEvent.endsAtUnix = tonumber(endsAtUnix) or 0
		refreshEventBanner()
	end)
end

-- Buttons do exactly what the keys do.
if HUD.claimButton then
	HUD.claimButton.MouseButton1Click:Connect(function()
		claimCurrentQuest()
	end)
end
if HUD.upgradeButtons.capacity then
	HUD.upgradeButtons.capacity.MouseButton1Click:Connect(function()
		fire(upgradeBase, "capacity")
	end)
end
if HUD.upgradeButtons.income then
	HUD.upgradeButtons.income.MouseButton1Click:Connect(function()
		fire(upgradeBase, "income")
	end)
end
if HUD.upgradeButtons.lock then
	HUD.upgradeButtons.lock.MouseButton1Click:Connect(function()
		fire(upgradeBase, "lock")
	end)
end

-- Keybinds through ContextActionService.
local function bindKey(actionName, keyCode, fn)
	ContextActionService:BindAction(actionName, function(_actionName, inputState, _inputObject)
		if inputState == Enum.UserInputState.Begin then
			fn()
		end
	end, false, keyCode)
end

bindKey("BrainrotBayBuy", Enum.KeyCode.E, function()
	fire(buyNearest)
end)
bindKey("BrainrotBaySlap", Enum.KeyCode.F, function()
	fire(slap)
end)
bindKey("BrainrotBayLock", Enum.KeyCode.L, function()
	fire(lockBase)
end)
bindKey("BrainrotBayRebirth", Enum.KeyCode.R, function()
	fire(rebirth)
end)
bindKey("BrainrotBayClaimQuest", Enum.KeyCode.Q, function()
	claimCurrentQuest()
end)
bindKey("BrainrotBayGift", Enum.KeyCode.G, function()
	fire(giftBrainrot)
end)

-- Nearest-brainrot scan: name, rarity, mutation, price, income and the
-- right hint (buy / yours / stealable / being carried), refreshed four
-- times a second. The event countdown refreshes on the same tick.
local function nearestBrainrotModel(maxDistance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local best = nil
	local bestDist = maxDistance
	for _, folderName in ipairs({ "Walkers", "OwnedBrainrots" }) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			for _, model in ipairs(folder:GetChildren()) do
				if model:IsA("Model") then
					local ok, dist = pcall(function()
						return (model:GetPivot().Position - root.Position).Magnitude
					end)
					if ok and dist < bestDist then
						bestDist = dist
						best = model
					end
				end
			end
		end
	end
	return best
end

local function refreshContextLine()
	local model = nearestBrainrotModel(16)
	if not model then
		HUD.setContext("Walk up to a brainrot on the conveyor — press E to buy it!")
		return
	end
	local defId = model:GetAttribute("DefId")
	local def = defId and BrainrotData.getCharacter(defId)
	if not def then
		return
	end
	local rarity = BrainrotData.getRarity(def.rarity)
	local mutation = model:GetAttribute("Mutation") or ""
	local line = def.name .. "  •  " .. rarity.name
	if mutation ~= "" and mutation ~= "Normal" then
		line ..= " " .. mutation
	end
	local state = model:GetAttribute("State")
	if state == "walking" then
		line ..= "  •  "
			.. BrainrotData.formatMoney(model:GetAttribute("Price") or 0)
			.. "  •  "
			.. BrainrotData.formatMoney(model:GetAttribute("Income") or 0)
			.. "/s  •  Press E to BUY"
	elseif state == "owned" then
		if model:GetAttribute("OwnerUserId") == player.UserId then
			line ..= "  •  YOURS  •  " .. BrainrotData.formatMoney(model:GetAttribute("Income") or 0) .. "/s  •  Press G near a friend to GIFT"
		else
			line ..= "  •  Grab it to STEAL (if the base is unlocked!)"
		end
	elseif state == "carried" then
		line ..= "  •  BEING CARRIED — slap the thief with F!"
	end
	HUD.setContext(line)
end

local tickAccumulator = 0
RunService.RenderStepped:Connect(function(dt)
	tickAccumulator += dt
	if tickAccumulator < 0.25 then
		return
	end
	tickAccumulator = 0
	refreshContextLine()
	refreshEventBanner()
end)

task.delay(0.5, function()
	HUD.toast("Welcome to Brainrot Bay! Walk up to a brainrot and press E to buy it.", "good")
end)

print("Brainrot Bay client ready.")

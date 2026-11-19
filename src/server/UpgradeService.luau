-- UpgradeService: base upgrades through the UpgradeBase remote.
--   "capacity" -- +2 brainrot slots per level, max 4 (12 -> 20 slots)
--   "income"   -- +25% income per level, max 4 (up to +100%)
--   "lock"     -- +15s base-lock duration per level, max 3 (30s -> 75s)
-- Costs and caps come from Shared.Economy.upgradeCost, which returns nil
-- at max level; money is only taken when the purchase actually goes through.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Economy = require(Shared:WaitForChild("Economy"))
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local UpgradeService = {}

local UPGRADE_NAMES = {
	capacity = "Capacity",
	income = "Income",
	lock = "Lock",
}

local function effectText(kind, newLevel)
	if kind == "capacity" then
		return "Your base now holds " .. Economy.slotsForLevel(newLevel, 12) .. " brainrots!"
	elseif kind == "income" then
		return "Your income is now x" .. string.format("%.2f", Economy.incomeMultiplier(newLevel)) .. "!"
	elseif kind == "lock" then
		return "Your base lock now lasts " .. Economy.lockDuration(newLevel, 30) .. "s!"
	end
	return ""
end

function UpgradeService.tryUpgrade(player, kind)
	local data = State.getPlayer(player)
	if not data then
		return false
	end
	if not UPGRADE_NAMES[kind] then
		Remotes.notify(player, "Unknown upgrade.", "bad")
		return false
	end
	local level = data.upgrades[kind]
	local cost = Economy.upgradeCost(kind, level)
	if cost == nil then
		Remotes.notify(player, UPGRADE_NAMES[kind] .. " is already at max level (" .. Economy.maxLevel(kind) .. ")!", "bad")
		return false
	end
	if data.money < cost then
		Remotes.notify(player, UPGRADE_NAMES[kind] .. " level " .. (level + 1) .. " costs " .. BrainrotData.formatMoney(cost) .. " — you have " .. BrainrotData.formatMoney(data.money) .. ".", "bad")
		return false
	end
	data.money -= cost
	data.upgrades[kind] = level + 1
	Remotes.MoneyUpdate:FireClient(player, math.floor(data.money), State.incomePerSecond(player))
	Remotes.notify(player, UPGRADE_NAMES[kind] .. " upgraded to level " .. (level + 1) .. "! " .. effectText(kind, level + 1), "good")
	-- Push the next costs so the client's upgrade buttons show the new
	-- price (x3 per level) instead of the level-0 price; 0 means maxed.
	local nextCosts = {}
	for _, nextKind in ipairs({ "capacity", "income", "lock" }) do
		nextCosts[nextKind] = Economy.upgradeCost(nextKind, data.upgrades[nextKind]) or 0
	end
	Remotes.UpgradeUpdate:FireClient(player, nextCosts)
	return true
end

function UpgradeService.start()
	Remotes.UpgradeBase.OnServerEvent:Connect(function(player, kind)
		UpgradeService.tryUpgrade(player, kind)
	end)
end

return UpgradeService

-- Economy: base-upgrade costs and payback math for Brainrot Bay.
-- All prices here are pure functions of (kind, level) so server and client
-- agree without any shared state. Levels are 0-based: level 0 is the first
-- purchase, level N is the (N+1)-th. A base starts at level 0 in every kind.
--
-- Upgrade kinds:
--   "capacity" -- +2 brainrot slots per level, max 4 levels (12 -> 20 slots)
--   "income"   -- +25% income per level, max 4 levels (up to +100%)
--   "lock"     -- +15s base-lock duration per level, max 3 levels (30s -> 75s)
--
-- Costs grow x3 per level so late upgrades are a real decision, not a
-- reflex buy: capacity 1000 * 3^level, income 2500 * 3^level,
-- lock 800 * 3^level.

local BrainrotData = require(script.Parent.BrainrotData)

local Economy = {}

Economy.UpgradeDefs = {
	capacity = { maxLevel = 4, baseCost = 1000, slotsPerLevel = 2 },
	income = { maxLevel = 4, baseCost = 2500, incomeBonusPerLevel = 0.25 },
	lock = { maxLevel = 3, baseCost = 800, lockSecondsPerLevel = 15 },
}

-- Seconds for a brainrot to earn back its own price (Normal mutation).
-- By the BrainrotData economy rule this is ~40s at every tier.
function Economy.paybackSeconds(def, mutation)
	local price = BrainrotData.priceFor(def, mutation)
	local income = BrainrotData.incomeFor(def, mutation)
	if income <= 0 then
		return math.huge
	end
	return price / income
end

-- Cost of buying the NEXT level of `kind` when the base is at `level`
-- (0-based, i.e. level 0 means "no upgrades bought yet"). Returns nil when
-- the kind is unknown or the base is already at max level.
function Economy.upgradeCost(kind, level)
	local def = Economy.UpgradeDefs[kind]
	if not def then
		return nil
	end
	if level < 0 or level >= def.maxLevel then
		return nil
	end
	return def.baseCost * (3 ^ level)
end

-- Max level for a kind (0 when the kind is unknown).
function Economy.maxLevel(kind)
	local def = Economy.UpgradeDefs[kind]
	if not def then
		return 0
	end
	return def.maxLevel
end

-- Total slots of a base whose capacity level is `capacityLevel`.
function Economy.slotsForLevel(capacityLevel, baseSlots)
	local def = Economy.UpgradeDefs.capacity
	local level = math.clamp(capacityLevel or 0, 0, def.maxLevel)
	return (baseSlots or 12) + level * def.slotsPerLevel
end

-- Income multiplier from the income upgrade level: 1 + 0.25 per level.
function Economy.incomeMultiplier(incomeLevel)
	local def = Economy.UpgradeDefs.income
	local level = math.clamp(incomeLevel or 0, 0, def.maxLevel)
	return 1 + level * def.incomeBonusPerLevel
end

-- Lock duration in seconds from the lock upgrade level: 30s + 15s per level.
function Economy.lockDuration(lockLevel, baseDuration)
	local def = Economy.UpgradeDefs.lock
	local level = math.clamp(lockLevel or 0, 0, def.maxLevel)
	return (baseDuration or 30) + level * def.lockSecondsPerLevel
end

return Economy

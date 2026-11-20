-- Brainrot Bay shared tuning.
-- Every number the island runs on lives in this one table, so the server and
-- the client always agree on world size, timers, costs and event cycles.
-- World layout: the conveyor runs along Z from ConveyorStartZ to
-- ConveyorEndZ; its length (300) is exactly EndZ - StartZ. Bases sit in two
-- rows of five flanking the conveyor, ten bases total.

local Config = {
	-- World and bases
	MaxBases = 10,
	SlotsPerBase = 12,
	ConveyorLength = 300,
	ConveyorWidth = 14,
	ConveyorStartZ = -145,
	ConveyorEndZ = 155,

	-- Conveyor walkers
	WalkerSpeed = 5,
	MaxWalkers = 10,
	SpawnInterval = 3.5,
	TickInterval = 1,

	-- Combat and interaction
	LockDuration = 30,
	LockCooldown = 120,
	SlapCooldown = 3,
	SlapRange = 10,
	BuyRange = 14,
	BaseSafeRadius = 15,
	CarryHeight = 6,

	-- Tsunami wave event
	WaveCycle = 90,
	WaveWarning = 15,
	WaveSpeed = 45,
	WaveWidth = 340,

	-- Starting cash
	StartingMoney = 2000,

	-- Golden Hour event (double income while active)
	GoldenHourCycle = 240,
	GoldenHourDuration = 60,

	-- Meteor shower event (bonus spawns while active)
	MeteorCycle = 180,
	MeteorDuration = 45,

	-- Gifting
	GiftRange = 20,
}

-- Rebirth n costs 50,000 * 2^n. First rebirth is 50,000, second 100,000, ...
function Config.rebirthCost(rebirths)
	return 50000 * (2 ^ rebirths)
end

-- Each rebirth doubles all income: multiplier is 2^n.
function Config.rebirthMultiplier(rebirths)
	return 2 ^ rebirths
end

return Config

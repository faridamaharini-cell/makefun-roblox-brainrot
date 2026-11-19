-- Brainrot Bazaar shared tuning: one place for every number the game runs on,
-- so server and client agree on costs, timers and world size.
local Config = {}

Config.MaxBases = 8
Config.SlotsPerBase = 10
Config.ConveyorLength = 260
Config.ConveyorWidth = 14
Config.ConveyorStartZ = -125
Config.ConveyorEndZ = 128

Config.WalkerSpeed = 5
Config.MaxWalkers = 8
Config.SpawnInterval = 4
Config.TickInterval = 1

Config.LockDuration = 30
Config.LockCooldown = 120
Config.SlapCooldown = 3
Config.SlapRange = 10
Config.BuyRange = 14
Config.BaseSafeRadius = 15
Config.CarryHeight = 6

Config.WaveCycle = 90 -- seconds of calm between waves
Config.WaveWarning = 15 -- seconds of warning before the wave hits
Config.WaveSpeed = 45 -- studs per second the wall sweeps
Config.WaveWidth = 340

Config.StartingMoney = 100

function Config.rebirthCost(rebirths)
	return 50000 * (2 ^ rebirths)
end

function Config.rebirthMultiplier(rebirths)
	return 2 ^ rebirths
end

return Config

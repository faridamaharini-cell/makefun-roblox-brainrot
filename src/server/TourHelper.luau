-- TourHelper: reviewer hooks for make.fun's finalist review (TOUR.json).
-- grant(amount) gives every player in the server that much money, so a
-- reviewer can reach the shop and rebirth screens at once; wave("go")
-- fires the tsunami immediately. Never used by the game itself.
local State = require(script.Parent.State)
local Remotes = require(script.Parent.Remotes)

local TourHelper = {}

function TourHelper.grant(amount)
	amount = tonumber(amount) or 0
	for _, data in pairs(State.players) do
		data.money += amount
	end
	Remotes.notify(nil, "Tour grant: +" .. tostring(amount) .. " for everyone.", "info")
end

function TourHelper.wave(_arg)
	local HazardService = require(script.Parent.HazardService)
	HazardService.triggerWave()
end

function TourHelper.spawnLegendary(_arg)
	local SpawnService = require(script.Parent.SpawnService)
	SpawnService.spawnOne("Legendary")
end

return TourHelper

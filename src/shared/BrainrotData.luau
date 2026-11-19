-- BrainrotData: the cast of Brainrot Bay.
-- 32 original bay creatures on a 9-rung rarity ladder, plus 6 mutations.
--
-- ECONOMY RULE (do not break this): every character's base income is
-- floor(price / 40), so a Normal brainrot pays for itself in exactly ~40
-- seconds at every tier. A mutation multiplier applies EXACTLY ONCE, to
-- both price and income, inside priceFor / incomeFor. The incomeMult on a
-- rarity is only a nominal ladder descriptor (used for display / balancing
-- talk) -- it is NEVER multiplied in again, or income would double-count.
-- That double-multiplier bug is what sank the v1 economy; keep it out.

local BrainrotData = {}

BrainrotData.Rarities = {
	{ name = "Common", weight = 40, color = Color3.fromRGB(205, 205, 205), incomeMult = 1 },
	{ name = "Rare", weight = 25, color = Color3.fromRGB(90, 170, 255), incomeMult = 2.5 },
	{ name = "Epic", weight = 15, color = Color3.fromRGB(190, 100, 255), incomeMult = 6 },
	{ name = "Legendary", weight = 10, color = Color3.fromRGB(255, 205, 45), incomeMult = 15 },
	{ name = "Mythic", weight = 6, color = Color3.fromRGB(255, 85, 125), incomeMult = 35 },
	{ name = "Divine", weight = 3, color = Color3.fromRGB(70, 235, 225), incomeMult = 80 },
	{ name = "Cosmic", weight = 2, color = Color3.fromRGB(150, 110, 255), incomeMult = 150 },
	{ name = "Secret", weight = 1, color = Color3.fromRGB(145, 255, 95), incomeMult = 250 },
	{ name = "Eternal", weight = 0.5, color = Color3.fromRGB(255, 240, 150), incomeMult = 400 },
}

BrainrotData.Mutations = {
	{ name = "Normal", weight = 70, mult = 1, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Golden", weight = 15, mult = 2, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", weight = 10, mult = 5, color = Color3.fromRGB(125, 220, 255) },
	{ name = "Rainbow", weight = 4, mult = 10, color = Color3.fromRGB(255, 125, 220) },
	{ name = "Shadow", weight = 0.7, mult = 20, color = Color3.fromRGB(90, 70, 160) },
	{ name = "Lava", weight = 0.3, mult = 50, color = Color3.fromRGB(255, 90, 30) },
}

-- Each row: id, display name, rarity, price, income (= floor(price/40)),
-- body colour, head colour, accessory.
-- Price ladder per rung (payback 40s everywhere): Common 40-200, Rare
-- 400-1200, Epic 2000-6000, Legendary 10000-24000, Mythic 40000-96000,
-- Divine 160000-300000, Cosmic 480000-800000, Secret 1.2M-1.6M, Eternal 3.2M.
BrainrotData.Characters = {
	-- Common
	{ id = "splish", name = "Splish the Sardine", rarity = "Common", price = 40, income = 1, body = Color3.fromRGB(150, 200, 235), head = Color3.fromRGB(185, 220, 245), accessory = "hat" },
	{ id = "barnacle", name = "Barnacle Bob", rarity = "Common", price = 80, income = 2, body = Color3.fromRGB(140, 140, 150), head = Color3.fromRGB(170, 170, 180), accessory = "mustache" },
	{ id = "kelpy", name = "Kelpy the Kelp Kid", rarity = "Common", price = 120, income = 3, body = Color3.fromRGB(70, 180, 90), head = Color3.fromRGB(110, 205, 120), accessory = "antenna" },
	{ id = "pebble", name = "Pebble the Crab", rarity = "Common", price = 160, income = 4, body = Color3.fromRGB(235, 90, 70), head = Color3.fromRGB(245, 130, 110), accessory = "bowtie" },
	{ id = "drippy", name = "Drippy the Droplet", rarity = "Common", price = 200, income = 5, body = Color3.fromRGB(90, 170, 255), head = Color3.fromRGB(140, 200, 255), accessory = "glasses" },
	-- Rare
	{ id = "tidepool", name = "Tidepool Terry", rarity = "Rare", price = 400, income = 10, body = Color3.fromRGB(110, 210, 190), head = Color3.fromRGB(150, 230, 215), accessory = "hat" },
	{ id = "salty", name = "Salty the Seagull", rarity = "Rare", price = 600, income = 15, body = Color3.fromRGB(235, 235, 240), head = Color3.fromRGB(255, 255, 255), accessory = "wings" },
	{ id = "coral", name = "Coral the Clownfish", rarity = "Rare", price = 800, income = 20, body = Color3.fromRGB(255, 140, 60), head = Color3.fromRGB(255, 175, 110), accessory = "bowtie" },
	{ id = "anchor", name = "Anchor Andy", rarity = "Rare", price = 1000, income = 25, body = Color3.fromRGB(80, 95, 115), head = Color3.fromRGB(120, 135, 155), accessory = "mustache" },
	{ id = "bubblegum", name = "Bubblegum Brenda", rarity = "Rare", price = 1200, income = 30, body = Color3.fromRGB(255, 150, 210), head = Color3.fromRGB(255, 185, 225), accessory = "glasses" },
	-- Epic
	{ id = "mermike", name = "Mer-Mike the Merman", rarity = "Epic", price = 2000, income = 50, body = Color3.fromRGB(60, 200, 180), head = Color3.fromRGB(100, 220, 200), accessory = "crown" },
	{ id = "lighthouse", name = "Lighthouse Larry", rarity = "Epic", price = 2800, income = 70, body = Color3.fromRGB(235, 225, 210), head = Color3.fromRGB(250, 245, 230), accessory = "antenna" },
	{ id = "octavia", name = "Octavia the Octopus", rarity = "Epic", price = 3600, income = 90, body = Color3.fromRGB(180, 110, 220), head = Color3.fromRGB(205, 150, 235), accessory = "cape" },
	{ id = "surfer", name = "Surfer Sammy", rarity = "Epic", price = 4800, income = 120, body = Color3.fromRGB(255, 200, 80), head = Color3.fromRGB(255, 220, 130), accessory = "glasses" },
	{ id = "pearl", name = "Pearl the Pufferfish", rarity = "Epic", price = 6000, income = 150, body = Color3.fromRGB(250, 240, 220), head = Color3.fromRGB(255, 250, 240), accessory = "crown" },
	-- Legendary
	{ id = "krak", name = "Krak the Kraken", rarity = "Legendary", price = 10000, income = 250, body = Color3.fromRGB(120, 70, 180), head = Color3.fromRGB(155, 105, 210), accessory = "cape" },
	{ id = "neptune", name = "Neptune Jr.", rarity = "Legendary", price = 14000, income = 350, body = Color3.fromRGB(50, 120, 220), head = Color3.fromRGB(90, 155, 240), accessory = "crown" },
	{ id = "tidaltina", name = "Tidal Tina", rarity = "Legendary", price = 18000, income = 450, body = Color3.fromRGB(70, 200, 230), head = Color3.fromRGB(110, 220, 245), accessory = "halo" },
	{ id = "shipwreck", name = "Shipwreck Steve", rarity = "Legendary", price = 24000, income = 600, body = Color3.fromRGB(150, 115, 75), head = Color3.fromRGB(185, 150, 105), accessory = "hat" },
	-- Mythic
	{ id = "levi", name = "Levi the Leviathan", rarity = "Mythic", price = 40000, income = 1000, body = Color3.fromRGB(45, 70, 120), head = Color3.fromRGB(80, 105, 160), accessory = "wings" },
	{ id = "atlantis", name = "Queen Atlantis", rarity = "Mythic", price = 56000, income = 1400, body = Color3.fromRGB(90, 220, 215), head = Color3.fromRGB(130, 235, 230), accessory = "crown" },
	{ id = "stormsurge", name = "Stormsurge Sally", rarity = "Mythic", price = 72000, income = 1800, body = Color3.fromRGB(100, 110, 200), head = Color3.fromRGB(140, 150, 225), accessory = "cape" },
	{ id = "abyss", name = "Abyssal Al", rarity = "Mythic", price = 96000, income = 2400, body = Color3.fromRGB(30, 30, 55), head = Color3.fromRGB(60, 60, 95), accessory = "halo" },
	-- Divine
	{ id = "poseidon", name = "Poseidon Prime", rarity = "Divine", price = 160000, income = 4000, body = Color3.fromRGB(60, 160, 255), head = Color3.fromRGB(105, 190, 255), accessory = "crown" },
	{ id = "sirena", name = "Sirena the Songstress", rarity = "Divine", price = 220000, income = 5500, body = Color3.fromRGB(255, 170, 220), head = Color3.fromRGB(255, 200, 235), accessory = "halo" },
	{ id = "tidalwave", name = "Tidalwave Titan", rarity = "Divine", price = 300000, income = 7500, body = Color3.fromRGB(40, 180, 200), head = Color3.fromRGB(80, 205, 225), accessory = "cape" },
	-- Cosmic
	{ id = "moonjelly", name = "Moonjelly the Jellyfish", rarity = "Cosmic", price = 480000, income = 12000, body = Color3.fromRGB(200, 170, 255), head = Color3.fromRGB(220, 200, 255), accessory = "halo" },
	{ id = "stardust", name = "Stardust Stella", rarity = "Cosmic", price = 640000, income = 16000, body = Color3.fromRGB(255, 230, 140), head = Color3.fromRGB(255, 242, 180), accessory = "crown" },
	{ id = "galaxycrab", name = "Galaxy Crab", rarity = "Cosmic", price = 800000, income = 20000, body = Color3.fromRGB(130, 80, 220), head = Color3.fromRGB(165, 120, 240), accessory = "wings" },
	-- Secret
	{ id = "voidwhale", name = "The Void Whale", rarity = "Secret", price = 1200000, income = 30000, body = Color3.fromRGB(25, 25, 45), head = Color3.fromRGB(55, 55, 85), accessory = "wings" },
	{ id = "timekeeper", name = "The Tide Timekeeper", rarity = "Secret", price = 1600000, income = 40000, body = Color3.fromRGB(220, 200, 130), head = Color3.fromRGB(240, 225, 170), accessory = "halo" },
	-- Eternal
	{ id = "baygod", name = "The Bay Eternal", rarity = "Eternal", price = 3200000, income = 80000, body = Color3.fromRGB(255, 215, 90), head = Color3.fromRGB(255, 235, 150), accessory = "crown" },
}

-- Fast lookups built once, so getRarity / getMutation / getCharacter are O(1).
local rarityByName = {}
for _, rarity in ipairs(BrainrotData.Rarities) do
	rarityByName[rarity.name] = rarity
end

local mutationByName = {}
for _, mutation in ipairs(BrainrotData.Mutations) do
	mutationByName[mutation.name] = mutation
end

local characterById = {}
for _, character in ipairs(BrainrotData.Characters) do
	characterById[character.id] = character
end

function BrainrotData.getRarity(name)
	return rarityByName[name] or BrainrotData.Rarities[1]
end

function BrainrotData.getMutation(name)
	return mutationByName[name] or BrainrotData.Mutations[1]
end

function BrainrotData.getCharacter(id)
	return characterById[id]
end

-- Weighted draw over a list whose entries carry a `weight` field.
local function weightedPick(list)
	local totalWeight = 0
	for _, entry in ipairs(list) do
		totalWeight += entry.weight
	end
	local roll = math.random() * totalWeight
	for _, entry in ipairs(list) do
		roll -= entry.weight
		if roll <= 0 then
			return entry
		end
	end
	return list[#list]
end

function BrainrotData.rollRarity()
	return weightedPick(BrainrotData.Rarities).name
end

function BrainrotData.rollMutation()
	return weightedPick(BrainrotData.Mutations)
end

function BrainrotData.rollCharacter(rarityName)
	local pool = {}
	for _, character in ipairs(BrainrotData.Characters) do
		if character.rarity == rarityName then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return BrainrotData.Characters[1]
	end
	return pool[math.random(1, #pool)]
end

-- Mutation multiplier applies exactly once here. Base price / income are
-- already rarity-scaled in the table, so no rarity factor is added.
function BrainrotData.priceFor(def, mutation)
	local mult = mutation and mutation.mult or 1
	return math.floor(def.price * mult)
end

-- Same single application of the mutation multiplier as priceFor.
function BrainrotData.incomeFor(def, mutation)
	local mult = mutation and mutation.mult or 1
	return math.floor(def.income * mult)
end

function BrainrotData.formatMoney(amount)
	amount = math.floor(amount)
	if amount < 0 then
		return "-" .. BrainrotData.formatMoney(-amount)
	elseif amount >= 1000000000 then
		return string.format("$%.2fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("$%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(amount)
	end
end

return BrainrotData

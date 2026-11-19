-- BrainrotData: the whole cast of Brainrot Bazaar.
-- 21 absurd characters of our own, on a 7-rung rarity ladder, with mutations
-- that multiply what they earn. Prices and income are the game's economy:
-- a Common pays for itself in ~25 seconds, a Secret costs a rebirth or two.
local BrainrotData = {}

BrainrotData.Rarities = {
	{ name = "Common", weight = 40, color = Color3.fromRGB(200, 200, 200), incomeMult = 1 },
	{ name = "Rare", weight = 25, color = Color3.fromRGB(80, 160, 255), incomeMult = 2.5 },
	{ name = "Epic", weight = 15, color = Color3.fromRGB(180, 90, 255), incomeMult = 6 },
	{ name = "Legendary", weight = 10, color = Color3.fromRGB(255, 200, 40), incomeMult = 15 },
	{ name = "Mythic", weight = 6, color = Color3.fromRGB(255, 80, 120), incomeMult = 35 },
	{ name = "Brainrot God", weight = 3, color = Color3.fromRGB(60, 230, 220), incomeMult = 80 },
	{ name = "Secret", weight = 1, color = Color3.fromRGB(140, 255, 90), incomeMult = 200 },
}

BrainrotData.Mutations = {
	{ name = "Normal", weight = 70, mult = 1, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Golden", weight = 15, mult = 2, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", weight = 10, mult = 5, color = Color3.fromRGB(120, 220, 255) },
	{ name = "Rainbow", weight = 5, mult = 10, color = Color3.fromRGB(255, 120, 220) },
}

-- id, name, rarity, base price, base $/sec, body colour, head colour, accessory
BrainrotData.Characters = {
	{ id = "noobini", name = "Noobini the Noodle", rarity = "Common", price = 25, income = 1, body = Color3.fromRGB(255, 220, 130), head = Color3.fromRGB(255, 235, 170), accessory = "hat" },
	{ id = "croaksalot", name = "Sir Croaksalot", rarity = "Common", price = 50, income = 2, body = Color3.fromRGB(90, 200, 110), head = Color3.fromRGB(120, 220, 140), accessory = "bowtie" },
	{ id = "pizzaroni", name = "Pizzaroni Supreme", rarity = "Common", price = 100, income = 4, body = Color3.fromRGB(255, 150, 60), head = Color3.fromRGB(255, 190, 90), accessory = "mustache" },
	{ id = "noodlebeard", name = "Captain Noodlebeard", rarity = "Rare", price = 300, income = 10, body = Color3.fromRGB(120, 170, 255), head = Color3.fromRGB(240, 210, 170), accessory = "hat" },
	{ id = "pickle", name = "Professor Pickle", rarity = "Rare", price = 500, income = 16, body = Color3.fromRGB(110, 200, 80), head = Color3.fromRGB(150, 220, 110), accessory = "glasses" },
	{ id = "wombat", name = "DJ Wombat", rarity = "Rare", price = 750, income = 22, body = Color3.fromRGB(150, 110, 80), head = Color3.fromRGB(180, 140, 100), accessory = "antenna" },
	{ id = "bananaphone", name = "Lord Bananaphone", rarity = "Epic", price = 1500, income = 45, body = Color3.fromRGB(255, 225, 60), head = Color3.fromRGB(255, 240, 120), accessory = "crown" },
	{ id = "toaster", name = "Grandma Toaster", rarity = "Epic", price = 2500, income = 70, body = Color3.fromRGB(200, 200, 210), head = Color3.fromRGB(220, 220, 230), accessory = "hat" },
	{ id = "avocado", name = "Agent Avocado", rarity = "Epic", price = 4000, income = 110, body = Color3.fromRGB(90, 180, 90), head = Color3.fromRGB(140, 210, 110), accessory = "glasses" },
	{ id = "fluffernutter", name = "King Fluffernutter", rarity = "Legendary", price = 8000, income = 220, body = Color3.fromRGB(255, 180, 220), head = Color3.fromRGB(255, 210, 235), accessory = "crown" },
	{ id = "chocula", name = "Count Chocula Jr.", rarity = "Legendary", price = 12000, income = 320, body = Color3.fromRGB(120, 80, 160), head = Color3.fromRGB(200, 180, 220), accessory = "cape" },
	{ id = "baguette", name = "Monsieur Baguette", rarity = "Legendary", price = 18000, income = 450, body = Color3.fromRGB(230, 190, 120), head = Color3.fromRGB(245, 215, 150), accessory = "mustache" },
	{ id = "penguin", name = "Emperor Penguin Supreme", rarity = "Mythic", price = 35000, income = 850, body = Color3.fromRGB(40, 50, 70), head = Color3.fromRGB(240, 240, 240), accessory = "crown" },
	{ id = "samosa", name = "Sultan Samosa", rarity = "Mythic", price = 50000, income = 1200, body = Color3.fromRGB(255, 170, 40), head = Color3.fromRGB(255, 200, 90), accessory = "cape" },
	{ id = "bubble", name = "Baron von Bubble", rarity = "Mythic", price = 75000, income = 1750, body = Color3.fromRGB(150, 220, 255), head = Color3.fromRGB(190, 235, 255), accessory = "wings" },
	{ id = "moonpie", name = "Madame Moonpie", rarity = "Brainrot God", price = 150000, income = 3500, body = Color3.fromRGB(220, 190, 255), head = Color3.fromRGB(240, 220, 255), accessory = "halo" },
	{ id = "donut", name = "Doctor Donut", rarity = "Brainrot God", price = 220000, income = 5000, body = Color3.fromRGB(255, 150, 180), head = Color3.fromRGB(255, 190, 205), accessory = "halo" },
	{ id = "frog", name = "Sir Reginald Frog", rarity = "Brainrot God", price = 300000, income = 6800, body = Color3.fromRGB(70, 200, 120), head = Color3.fromRGB(110, 220, 150), accessory = "crown" },
	{ id = "sock", name = "The Forbidden Sock", rarity = "Secret", price = 600000, income = 14000, body = Color3.fromRGB(90, 90, 110), head = Color3.fromRGB(130, 130, 150), accessory = "wings" },
	{ id = "sandwich", name = "The Invisible Sandwich", rarity = "Secret", price = 900000, income = 20000, body = Color3.fromRGB(240, 220, 160), head = Color3.fromRGB(250, 240, 200), accessory = "halo" },
	{ id = "watermelon", name = "Grand Wizard Watermelon", rarity = "Secret", price = 1500000, income = 32000, body = Color3.fromRGB(60, 180, 90), head = Color3.fromRGB(100, 210, 120), accessory = "hat" },
}

function BrainrotData.getRarity(rarityName)
	for _, r in ipairs(BrainrotData.Rarities) do
		if r.name == rarityName then
			return r
		end
	end
	return BrainrotData.Rarities[1]
end

function BrainrotData.getMutation(mutationName)
	for _, m in ipairs(BrainrotData.Mutations) do
		if m.name == mutationName then
			return m
		end
	end
	return BrainrotData.Mutations[1]
end

function BrainrotData.getCharacter(id)
	for _, c in ipairs(BrainrotData.Characters) do
		if c.id == id then
			return c
		end
	end
	return nil
end

local function weightedPick(list)
	local total = 0
	for _, entry in ipairs(list) do
		total += entry.weight
	end
	local roll = math.random() * total
	for _, entry in ipairs(list) do
		roll -= entry.weight
		if roll <= 0 then
			return entry
		end
	end
	return list[1]
end

function BrainrotData.rollRarity()
	return weightedPick(BrainrotData.Rarities).name
end

function BrainrotData.rollMutation()
	return weightedPick(BrainrotData.Mutations)
end

function BrainrotData.rollCharacter(rarityName)
	local pool = {}
	for _, c in ipairs(BrainrotData.Characters) do
		if c.rarity == rarityName then
			table.insert(pool, c)
		end
	end
	if #pool == 0 then
		return BrainrotData.Characters[1]
	end
	return pool[math.random(1, #pool)]
end

-- Price and income both scale with the mutation multiplier.
function BrainrotData.priceFor(def, mutation)
	return math.floor(def.price * mutation.mult)
end

-- Price and income both scale with the mutation multiplier. Base income is
-- already scaled per rarity in the character table, so no rarity factor here.
function BrainrotData.incomeFor(def, mutation)
	return math.floor(def.income * mutation.mult)
end

function BrainrotData.formatMoney(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return string.format("$%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(amount)
	end
end

return BrainrotData

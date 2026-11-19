-- BrainrotFactory: builds every Brainrot Bay character out of plain Parts.
-- No MeshParts, no Decals, no asset ids: everything the judge sees is built
-- by this code, so the game loads identically on any account in Studio.
-- Models are built at the origin facing +Z; callers place them with PivotTo.

local BrainrotData = require(script.Parent.BrainrotData)

local BrainrotFactory = {}

-- Per-mutation tint overrides. Normal keeps the character's own colours.
-- Shadow and Lava also switch the body to Neon so they glow on the conveyor.
local MUTATION_TINTS = {
	Golden = { body = Color3.fromRGB(255, 215, 0), head = Color3.fromRGB(255, 232, 100), neon = false },
	Diamond = { body = Color3.fromRGB(140, 220, 255), head = Color3.fromRGB(185, 238, 255), neon = true },
	Rainbow = { body = Color3.fromRGB(255, 120, 220), head = Color3.fromRGB(140, 230, 220), neon = true },
	Shadow = { body = Color3.fromRGB(55, 40, 105), head = Color3.fromRGB(85, 65, 150), neon = true },
	Lava = { body = Color3.fromRGB(255, 95, 35), head = Color3.fromRGB(255, 150, 60), neon = true },
}

local function makeBox(name, size, color, parent, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function makeBall(name, diameter, color, parent, material)
	local ball = Instance.new("Part")
	ball.Name = name
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(diameter, diameter, diameter)
	ball.Color = color
	ball.Material = material or Enum.Material.SmoothPlastic
	ball.Anchored = true
	ball.CanCollide = false
	ball.Parent = parent
	return ball
end

-- One builder per accessory kind. Each receives the model, the head part and
-- the character definition; positions are relative to the head centre.
local AccessoryBuilders = {}

AccessoryBuilders.hat = function(model, head, def)
	local brim = makeBox("HatBrim", Vector3.new(3.4, 0.35, 3.4), def.body, model)
	brim.Position = head.Position + Vector3.new(0, 1.05, 0)
	local top = makeBox("HatTop", Vector3.new(1.9, 1.3, 1.9), def.body, model)
	top.Position = head.Position + Vector3.new(0, 1.85, 0)
end

AccessoryBuilders.crown = function(model, head, _def)
	local gold = Color3.fromRGB(255, 215, 0)
	local band = makeBox("Crown", Vector3.new(2.5, 0.5, 2.5), gold, model, Enum.Material.Neon)
	band.Position = head.Position + Vector3.new(0, 1.1, 0)
	for _, offsetX in ipairs({ -0.85, 0, 0.85 }) do
		local spike = makeBox("CrownSpike", Vector3.new(0.45, 0.85, 0.45), gold, model, Enum.Material.Neon)
		spike.Position = head.Position + Vector3.new(offsetX, 1.7, 0)
	end
end

AccessoryBuilders.cape = function(model, head, _def)
	local cape = makeBox("Cape", Vector3.new(2.9, 3.4, 0.25), Color3.fromRGB(165, 30, 45), model, Enum.Material.Fabric)
	cape.Position = head.Position + Vector3.new(0, -1.7, -1.2)
end

AccessoryBuilders.glasses = function(model, head, _def)
	local dark = Color3.fromRGB(25, 25, 35)
	for _, offsetX in ipairs({ -0.55, 0.55 }) do
		local lens = makeBox("GlassesLens", Vector3.new(0.95, 0.7, 0.15), dark, model, Enum.Material.Glass)
		lens.Position = head.Position + Vector3.new(offsetX, 0.1, 1.02)
	end
	local bridge = makeBox("GlassesBridge", Vector3.new(0.45, 0.15, 0.15), dark, model)
	bridge.Position = head.Position + Vector3.new(0, 0.1, 1.02)
end

AccessoryBuilders.antenna = function(model, head, _def)
	local rod = makeBox("Antenna", Vector3.new(0.2, 1.5, 0.2), Color3.fromRGB(65, 65, 65), model)
	rod.Position = head.Position + Vector3.new(0, 1.75, 0)
	local tip = makeBall("AntennaTip", 0.85, Color3.fromRGB(255, 60, 90), model, Enum.Material.Neon)
	tip.Position = head.Position + Vector3.new(0, 2.6, 0)
end

AccessoryBuilders.wings = function(model, head, _def)
	for _, side in ipairs({ -1, 1 }) do
		local wing = makeBox("Wing", Vector3.new(1.7, 2.3, 0.2), Color3.fromRGB(242, 242, 255), model, Enum.Material.Fabric)
		wing.Position = head.Position + Vector3.new(side * 2.15, -1.0, -0.65)
		wing.CFrame = CFrame.new(wing.Position) * CFrame.Angles(0, 0, side * -0.55)
	end
end

AccessoryBuilders.halo = function(model, head, _def)
	local halo = Instance.new("Part")
	halo.Name = "Halo"
	halo.Shape = Enum.PartType.Cylinder
	halo.Size = Vector3.new(0.3, 2.5, 2.5)
	halo.Color = Color3.fromRGB(255, 232, 125)
	halo.Material = Enum.Material.Neon
	halo.Anchored = true
	halo.CanCollide = false
	halo.CFrame = CFrame.new(head.Position + Vector3.new(0, 1.65, 0)) * CFrame.Angles(0, 0, math.rad(90))
	halo.Parent = model
end

AccessoryBuilders.mustache = function(model, head, _def)
	local mo = makeBox("Mustache", Vector3.new(1.7, 0.35, 0.3), Color3.fromRGB(55, 38, 22), model)
	mo.Position = head.Position + Vector3.new(0, -0.6, 1.02)
end

AccessoryBuilders.bowtie = function(model, head, _def)
	for _, side in ipairs({ -1, 1 }) do
		local knot = makeBox("Bowtie", Vector3.new(0.95, 0.6, 0.2), Color3.fromRGB(205, 30, 55), model)
		knot.Position = head.Position + Vector3.new(side * 0.55, -2.35, 1.0)
		knot.CFrame = CFrame.new(knot.Position) * CFrame.Angles(0, 0, side * 0.65)
	end
	local centre = makeBox("BowtieKnot", Vector3.new(0.4, 0.4, 0.25), Color3.fromRGB(205, 30, 55), model)
	centre.Position = head.Position + Vector3.new(0, -2.35, 1.0)
end

local function makeLabel(name, text, textColor, positionY, parent)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0.33, 0)
	label.Position = UDim2.new(0, 0, positionY, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

-- Builds the model at the origin, facing +Z. Caller moves it with PivotTo.
-- `mutation` is a mutation table from BrainrotData.Mutations; a mutation
-- NAME string ("Golden") or nil is also accepted and resolved here, so a
-- caller passing a name instead of a table cannot crash the tint lookup
-- (MUTATION_TINTS[nil] would error) -- Normal is the default either way.
function BrainrotFactory.buildBrainrotModel(def, mutation)
	if type(mutation) == "string" then
		mutation = BrainrotData.getMutation(mutation)
	elseif mutation == nil then
		mutation = BrainrotData.getMutation("Normal")
	end
	local rarity = BrainrotData.getRarity(def.rarity)

	local bodyColor = def.body
	local headColor = def.head
	local bodyNeon = false
	local tint = MUTATION_TINTS[mutation.name]
	if tint then
		bodyColor = tint.body
		headColor = tint.head
		bodyNeon = tint.neon
	end

	local model = Instance.new("Model")
	model.Name = def.name

	-- Torso (2.8 x 2.6 x 2, centre y 2.5) is the PrimaryPart.
	local body = makeBox("Body", Vector3.new(2.8, 2.6, 2), bodyColor, model)
	body.Position = Vector3.new(0, 2.5, 0)
	if bodyNeon then
		body.Material = Enum.Material.Neon
	end
	model.PrimaryPart = body

	-- Head (2.2 cube, centre y 4.6) sits on the torso.
	local head = makeBox("Head", Vector3.new(2.2, 2, 2.2), headColor, model)
	head.Position = Vector3.new(0, 4.6, 0)

	-- Eyes on the +Z face of the head, with dark pupils.
	for _, offsetX in ipairs({ -0.55, 0.55 }) do
		local eye = makeBox("Eye", Vector3.new(0.55, 0.65, 0.12), Color3.fromRGB(255, 255, 255), model)
		eye.Position = Vector3.new(offsetX, 4.75, 1.12)
		local pupil = makeBox("Pupil", Vector3.new(0.28, 0.34, 0.12), Color3.fromRGB(20, 20, 20), model)
		pupil.Position = Vector3.new(offsetX, 4.7, 1.16)
	end

	-- Arms at the torso sides and legs under the torso.
	for _, side in ipairs({ -1, 1 }) do
		local arm = makeBox("Arm", Vector3.new(0.7, 2.0, 0.7), bodyColor, model)
		arm.Position = Vector3.new(side * 1.75, 2.5, 0)
		local leg = makeBox("Leg", Vector3.new(0.9, 1.2, 0.9), Color3.fromRGB(60, 60, 70), model)
		leg.Position = Vector3.new(side * 0.65, 0.6, 0)
	end

	local buildAccessory = AccessoryBuilders[def.accessory]
	if buildAccessory then
		buildAccessory(model, head, def)
	end

	-- Floating label above the head: name, rarity (+ mutation), $/sec.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 130, 0, 66)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	makeLabel("NameLabel", def.name, Color3.fromRGB(255, 255, 255), 0, billboard)
	local rarityText = rarity.name
	if mutation.name ~= "Normal" then
		rarityText = rarity.name .. " " .. mutation.name
	end
	makeLabel("RarityLabel", rarityText, rarity.color, 0.33, billboard)
	makeLabel(
		"IncomeLabel",
		BrainrotData.formatMoney(BrainrotData.incomeFor(def, mutation)) .. "/s",
		Color3.fromRGB(120, 255, 140),
		0.66,
		billboard
	)

	-- Interaction prompt; services retarget ActionText for Buy vs Steal.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "InteractPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	model:SetAttribute("DefId", def.id)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("Price", BrainrotData.priceFor(def, mutation))
	model:SetAttribute("Income", BrainrotData.incomeFor(def, mutation))
	model:SetAttribute("State", "walking")

	return model
end

-- Short alias kept for callers that used the v1 builder name.
BrainrotFactory.build = BrainrotFactory.buildBrainrotModel

return BrainrotFactory

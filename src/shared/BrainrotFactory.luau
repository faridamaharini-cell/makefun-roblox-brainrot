-- BrainrotFactory: builds every Brainrot Bay character out of plain Parts.
-- No MeshParts, no Decals, no asset ids: everything the judge sees is built
-- by this code, so the game loads identically on any account in Studio.
-- Models are built at the origin facing +Z; callers place them with PivotTo.

local BrainrotData = require(script.Parent.BrainrotData)

local BrainrotFactory = {}

-- Characters are built big: MODEL_SCALE 2.0 makes the ~5.7-stud character
-- ~11.4 studs tall, so they read as big creatures next to the player (like
-- the Rot Ranch animals).
-- PIVOT (v4): the model pivot is the Body centre, nominally 2.5 studs above
-- the feet before scaling (PIVOT_ABOVE_FEET = 5.0 after scaling) — but that
-- constant was WRONG in practice (v3.6 screenshot: only floating labels
-- visible, bodies sunk/invisible). The constant trusts ScaleTo's pivot
-- semantics and the hand-measured leg bottom; both can drift. So no caller
-- may trust the constant any more: groundOffset(model) MEASURES the real
-- distance from the pivot to the lowest BasePart bottom with
-- GetBoundingBox() on the live, scaled model, and placeOnSurface() places
-- the model, re-measures, and corrects the Y until the lowest point sits
-- exactly on the surface (within 0.05 studs). placeOnSurface is the only
-- correct way to stand a brainrot on a surface; PIVOT_ABOVE_FEET is kept
-- only as a first-guess seed and a fallback.
BrainrotFactory.MODEL_SCALE = 2.0
BrainrotFactory.PIVOT_ABOVE_FEET = 2.5 * BrainrotFactory.MODEL_SCALE

-- Measured distance from the model's pivot down to its lowest part bottom,
-- on the live (already scaled) model. GetBoundingBox covers every BasePart
-- in the model (BillboardGuis are not parts, so the label never pollutes
-- the measurement); the lowest point is the feet (legs bottom) unless an
-- accessory hangs lower, in which case that accessory IS the lowest point
-- and this still returns the truth.
function BrainrotFactory.groundOffset(model)
	local cf, size = model:GetBoundingBox()
	local bottom = cf.Position.Y - size.Y / 2
	return model:GetPivot().Position.Y - bottom
end

-- Stand `model` on `surfaceY` at (x, z), facing `yaw` (default 0). Places
-- at the constant seed, measures the real bottom, then shifts by the exact
-- error so the lowest point lands on the surface. Returns the measured
-- ground offset, which callers should store and reuse for every later
-- PivotTo of the same model (walk bob, idle bob) instead of re-deriving it.
function BrainrotFactory.placeOnSurface(model, surfaceY, x, z, yaw)
	yaw = yaw or 0
	model:PivotTo(CFrame.new(x, surfaceY + BrainrotFactory.PIVOT_ABOVE_FEET, z) * CFrame.Angles(0, yaw, 0))
	local offset = BrainrotFactory.groundOffset(model)
	local cf, size = model:GetBoundingBox()
	local bottom = cf.Position.Y - size.Y / 2
	local err = surfaceY - bottom
	if math.abs(err) > 0.001 then
		model:PivotTo(model:GetPivot() + Vector3.new(0, err, 0))
	end
	-- Verify the correction landed: re-measure and warn loudly if not.
	local cf2, size2 = model:GetBoundingBox()
	local bottom2 = cf2.Position.Y - size2.Y / 2
	if math.abs(bottom2 - surfaceY) > 0.05 then
		warn("BrainrotFactory.placeOnSurface: " .. model.Name .. " bottom " .. tostring(bottom2) .. " vs surface " .. tostring(surfaceY))
	end
	return offset
end

-- Stagger the floating label height so neighbouring brainrots' labels
-- never stack on one screen line: slot/walker index mod 3 lifts the label
-- by 0 / 1.2 / 2.4 studs. Call after buildBrainrotModel, from the spawner
-- (walker id) or the slotter (slot index).
function BrainrotFactory.staggerLabel(model, index)
	local billboard = model:FindFirstChild("Label", true)
	if billboard and billboard:IsA("BillboardGui") then
		local step = (index or 0) % 3
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.2 + step * 1.2, 0)
	end
end

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
	brim.Position = head.Position + Vector3.new(0, 1.25, 0)
	local top = makeBox("HatTop", Vector3.new(1.9, 1.3, 1.9), def.body, model)
	top.Position = head.Position + Vector3.new(0, 2.05, 0)
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
	cape.Position = head.Position + Vector3.new(0, -1.7, -1.15)
end

AccessoryBuilders.glasses = function(model, head, _def)
	local dark = Color3.fromRGB(25, 25, 35)
	for _, offsetX in ipairs({ -0.55, 0.55 }) do
		local lens = makeBox("GlassesLens", Vector3.new(0.95, 0.7, 0.15), dark, model, Enum.Material.Glass)
		lens.Position = head.Position + Vector3.new(offsetX, 0.1, 1.15)
	end
	local bridge = makeBox("GlassesBridge", Vector3.new(0.45, 0.15, 0.15), dark, model)
	bridge.Position = head.Position + Vector3.new(0, 0.1, 1.15)
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
	mo.Position = head.Position + Vector3.new(0, -0.6, 1.12)
end

AccessoryBuilders.bowtie = function(model, head, _def)
	for _, side in ipairs({ -1, 1 }) do
		local knot = makeBox("Bowtie", Vector3.new(0.95, 0.6, 0.2), Color3.fromRGB(205, 30, 55), model)
		knot.Position = head.Position + Vector3.new(side * 0.55, -2.35, 1.1)
		knot.CFrame = CFrame.new(knot.Position) * CFrame.Angles(0, 0, side * 0.65)
	end
	local centre = makeBox("BowtieKnot", Vector3.new(0.4, 0.4, 0.25), Color3.fromRGB(205, 30, 55), model)
	centre.Position = head.Position + Vector3.new(0, -2.35, 1.1)
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

	-- Torso (2.8 x 2.6 x 2 box, centre y 2.5) is the PrimaryPart, like a
	-- Roblox avatar's torso. Feet stay at model y 0, pivot at y 2.5.
	local body = makeBox("Body", Vector3.new(2.8, 2.6, 2), bodyColor, model)
	body.Position = Vector3.new(0, 2.5, 0)
	if bodyNeon then
		body.Material = Enum.Material.Neon
	end
	model.PrimaryPart = body

	-- Head (2.2 cube, centre y 4.6) sits on the torso, like a Roblox
	-- avatar's head. Its +Z face is at Z 1.1.
	local head = makeBox("Head", Vector3.new(2.2, 2, 2.2), headColor, model)
	head.Position = Vector3.new(0, 4.6, 0)

	-- Eyes on the +Z face of the head, with dark pupils. The face plane
	-- is at Z 1.1, so the eyes (0.12 thick, centred at 1.12) and pupils
	-- (centred at 1.16) poke out just past it.
	for _, offsetX in ipairs({ -0.55, 0.55 }) do
		local eye = makeBox("Eye", Vector3.new(0.55, 0.65, 0.12), Color3.fromRGB(255, 255, 255), model)
		eye.Position = Vector3.new(offsetX, 4.75, 1.12)
		local pupil = makeBox("Pupil", Vector3.new(0.28, 0.34, 0.12), Color3.fromRGB(20, 20, 20), model)
		pupil.Position = Vector3.new(offsetX, 4.7, 1.16)
	end

	-- Smile: a small dark mouth below the eyes, on the face plane.
	local mouth = makeBox("Mouth", Vector3.new(0.9, 0.25, 0.12), Color3.fromRGB(20, 20, 20), model)
	mouth.Position = Vector3.new(0, 4.05, 1.08)

	-- Hair, Roblox style: a flat box cap on top of the head plus a thin
	-- back panel down the back of the head, leaving the face open. Only
	-- when the accessory does not already cover the top of the head (hat,
	-- crown, antenna and halo sit up there instead). The head top is at
	-- Y 5.7, so the cap (0.6 thick) sits centred at 6.0.
	local TOP_ACCESSORIES = { hat = true, crown = true, antenna = true, halo = true }
	if not TOP_ACCESSORIES[def.accessory] then
		local hairColor = Color3.fromRGB(45, 30, 20)
		local cap = makeBox("Hair", Vector3.new(2.4, 0.6, 2.4), hairColor, model)
		cap.Position = head.Position + Vector3.new(0, 1.4, 0)
		local back = makeBox("HairBack", Vector3.new(2.4, 1.6, 0.3), hairColor, model)
		back.Position = head.Position + Vector3.new(0, 0.4, -1.2)
	end

	-- Arms at the torso sides and legs under the torso, as boxes like a
	-- Roblox avatar. The legs are longer (2.0, centred at Y 1.0) for
	-- human proportions, emerging from under the torso; feet stay at
	-- model y 0, Body centre at 2.5.
	for _, side in ipairs({ -1, 1 }) do
		local arm = makeBox("Arm", Vector3.new(0.7, 2.0, 0.7), bodyColor, model)
		arm.Position = Vector3.new(side * 1.75, 2.5, 0)
		local leg = makeBox("Leg", Vector3.new(0.9, 2.0, 0.9), Color3.fromRGB(60, 60, 70), model)
		leg.Position = Vector3.new(side * 0.65, 1.0, 0)
	end

	local buildAccessory = AccessoryBuilders[def.accessory]
	if buildAccessory then
		buildAccessory(model, head, def)
	end

	-- Floating label above the head: name, rarity (+ mutation), $/sec.
	-- v4: SMALL — v3.6 used a 260x132px AlwaysOnTop billboard, so a whole
	-- conveyor of labels merged into one unreadable jumble that dwarfed
	-- the bodies underneath. This one is 96x40px, sits just 3.2 studs
	-- above the head, and staggerLabel() (called by the spawner/slotter)
	-- lifts neighbours by 0/1.2/2.4 studs so labels never stack.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 96, 0, 40)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
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

	-- Scale the whole character up around its pivot (the Body centre, so
	-- the pivot stays put and the feet drop to -PIVOT_ABOVE_FEET below it
	-- in theory — callers must NOT trust that; see groundOffset above).
	-- The label's Size and StudsOffsetWorldSpace are GUI properties that
	-- ScaleTo does not touch, so keep them at the small v4 values set
	-- above: do NOT scale the billboard up with the body.
	model:ScaleTo(BrainrotFactory.MODEL_SCALE)

	return model
end

-- Short alias kept for callers that used the v1 builder name.
BrainrotFactory.build = BrainrotFactory.buildBrainrotModel

return BrainrotFactory

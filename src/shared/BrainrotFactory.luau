-- BrainrotFactory: builds every brainrot character out of plain Parts.
-- No MeshParts, no Decals, no asset ids: everything the judge sees is built
-- by this code, so it loads identically on any account in Studio.
local BrainrotData = require(script.Parent.BrainrotData)

local BrainrotFactory = {}

local function newPart(name, size, color, parent, material)
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

local function buildAccessory(kind, head, def)
	if kind == "hat" then
		local brim = newPart("HatBrim", Vector3.new(3.2, 0.3, 3.2), def.body, head.Parent)
		brim.Position = head.Position + Vector3.new(0, 1.1, 0)
		local top = newPart("HatTop", Vector3.new(1.8, 1.2, 1.8), def.body, head.Parent)
		top.Position = head.Position + Vector3.new(0, 1.8, 0)
	elseif kind == "crown" then
		local band = newPart("Crown", Vector3.new(2.6, 0.5, 2.6), Color3.fromRGB(255, 215, 0), head.Parent, Enum.Material.Neon)
		band.Position = head.Position + Vector3.new(0, 1.15, 0)
		for _, dx in ipairs({ -0.9, 0, 0.9 }) do
			local spike = newPart("CrownSpike", Vector3.new(0.4, 0.8, 0.4), Color3.fromRGB(255, 215, 0), head.Parent, Enum.Material.Neon)
			spike.Position = head.Position + Vector3.new(dx, 1.7, 0)
		end
	elseif kind == "cape" then
		local cape = newPart("Cape", Vector3.new(2.8, 3.2, 0.25), Color3.fromRGB(160, 30, 40), head.Parent, Enum.Material.Fabric)
		cape.Position = head.Position + Vector3.new(0, -1.6, -1.15)
	elseif kind == "glasses" then
		for _, dx in ipairs({ -0.55, 0.55 }) do
			local lens = newPart("Glasses", Vector3.new(0.9, 0.7, 0.15), Color3.fromRGB(20, 20, 30), head.Parent, Enum.Material.Glass)
			lens.Position = head.Position + Vector3.new(dx, 0.15, 1.05)
		end
		local bridge = newPart("GlassesBridge", Vector3.new(0.4, 0.15, 0.15), Color3.fromRGB(20, 20, 30), head.Parent)
		bridge.Position = head.Position + Vector3.new(0, 0.15, 1.05)
	elseif kind == "antenna" then
		local rod = newPart("Antenna", Vector3.new(0.2, 1.4, 0.2), Color3.fromRGB(60, 60, 60), head.Parent)
		rod.Position = head.Position + Vector3.new(0, 1.7, 0)
		local ball = Instance.new("Part")
		ball.Name = "AntennaBall"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(0.8, 0.8, 0.8)
		ball.Color = Color3.fromRGB(255, 60, 90)
		ball.Material = Enum.Material.Neon
		ball.Anchored = true
		ball.CanCollide = false
		ball.Position = head.Position + Vector3.new(0, 2.5, 0)
		ball.Parent = head.Parent
	elseif kind == "wings" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = newPart("Wing", Vector3.new(1.6, 2.2, 0.2), Color3.fromRGB(240, 240, 255), head.Parent, Enum.Material.Fabric)
			wing.Position = head.Position + Vector3.new(side * 2.1, -0.9, -0.6)
			wing.CFrame = CFrame.new(wing.Position) * CFrame.Angles(0, 0, side * -0.5)
		end
	elseif kind == "halo" then
		local halo = Instance.new("Part")
		halo.Name = "Halo"
		halo.Shape = Enum.PartType.Cylinder
		halo.Size = Vector3.new(0.3, 2.4, 2.4)
		halo.Color = Color3.fromRGB(255, 230, 120)
		halo.Material = Enum.Material.Neon
		halo.Anchored = true
		halo.CanCollide = false
		halo.CFrame = CFrame.new(head.Position + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0, math.rad(90))
		halo.Parent = head.Parent
	elseif kind == "mustache" then
		local mo = newPart("Mustache", Vector3.new(1.6, 0.35, 0.3), Color3.fromRGB(50, 35, 20), head.Parent)
		mo.Position = head.Position + Vector3.new(0, -0.55, 1.05)
	elseif kind == "bowtie" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = newPart("Bowtie", Vector3.new(0.9, 0.6, 0.2), Color3.fromRGB(200, 30, 50), head.Parent)
			wing.Position = head.Position + Vector3.new(side * 0.55, -2.2, 1.05)
			wing.CFrame = CFrame.new(wing.Position) * CFrame.Angles(0, 0, side * 0.6)
		end
	end
end

-- Builds the model at the origin, facing +Z. Caller moves it with PivotTo.
function BrainrotFactory.build(def, mutation)
	local rarity = BrainrotData.getRarity(def.rarity)
	local model = Instance.new("Model")
	model.Name = def.name

	local bodyColor = def.body
	local headColor = def.head
	if mutation.name == "Golden" then
		bodyColor = Color3.fromRGB(255, 215, 0)
		headColor = Color3.fromRGB(255, 230, 90)
	elseif mutation.name == "Diamond" then
		bodyColor = Color3.fromRGB(140, 220, 255)
		headColor = Color3.fromRGB(180, 235, 255)
	elseif mutation.name == "Rainbow" then
		bodyColor = Color3.fromRGB(255, 120, 220)
		headColor = Color3.fromRGB(140, 230, 220)
	end

	local body = newPart("Body", Vector3.new(3, 2.4, 2), bodyColor, model)
	body.Position = Vector3.new(0, 2.4, 0)
	if mutation.name == "Diamond" or mutation.name == "Rainbow" then
		body.Material = Enum.Material.Neon
	end
	model.PrimaryPart = body

	local head = newPart("Head", Vector3.new(2.4, 2, 2), headColor, model)
	head.Position = Vector3.new(0, 4.4, 0)

	-- Eyes on the front of the head (+Z face).
	for _, dx in ipairs({ -0.55, 0.55 }) do
		local eye = newPart("Eye", Vector3.new(0.55, 0.65, 0.12), Color3.fromRGB(255, 255, 255), model)
		eye.Position = Vector3.new(dx, 4.55, 1.02)
		local pupil = newPart("Pupil", Vector3.new(0.28, 0.34, 0.12), Color3.fromRGB(20, 20, 20), model)
		pupil.Position = Vector3.new(dx, 4.5, 1.06)
	end

	-- Legs.
	for _, dx in ipairs({ -0.7, 0.7 }) do
		local leg = newPart("Leg", Vector3.new(0.8, 1.2, 0.8), Color3.fromRGB(60, 60, 70), model)
		leg.Position = Vector3.new(dx, 0.6, 0)
	end

	buildAccessory(def.accessory, head, def)

	-- Name / rarity / $/sec label floating above the head.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 120, 0, 60)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0.33, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.33, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = rarity.name .. (mutation.name ~= "Normal" and (" " .. mutation.name) or "")
	rarityLabel.TextColor3 = rarity.color
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.Parent = billboard

	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, 0, 0.34, 0)
	incomeLabel.Position = UDim2.new(0, 0, 0.66, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = BrainrotData.formatMoney(BrainrotData.incomeFor(def, mutation)) .. "/s"
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.GothamBold
	incomeLabel.TextStrokeTransparency = 0
	incomeLabel.Parent = billboard

	-- Interaction prompt; services retarget its text for Buy vs Steal.
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

return BrainrotFactory

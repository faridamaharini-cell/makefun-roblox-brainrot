-- WorldBuilder: builds the whole 3D world from code when the server starts.
-- A central conveyor down the middle, 8 player bases around it (4 per side),
-- trees, lamps and a welcome arch. The baseplate itself is static in
-- default.project.json; everything else is built here.
local Workspace = game:GetService("Workspace")

local WorldBuilder = {}

local BASE_COLORS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(90, 160, 255),
	Color3.fromRGB(120, 220, 120),
	Color3.fromRGB(255, 200, 60),
	Color3.fromRGB(200, 120, 255),
	Color3.fromRGB(90, 220, 210),
	Color3.fromRGB(255, 140, 200),
	Color3.fromRGB(255, 160, 80),
}

local BASE_Z = { -96, -32, 32, 96 }

local function newPart(name, size, color, position, parent, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Position = position
	part.Parent = parent
	return part
end

local function addSign(parent, position, text, textColor, size)
	local board = newPart("Sign", Vector3.new(14, 4, 0.6), Color3.fromRGB(35, 35, 45), position, parent)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SignLabel"
	billboard.Size = UDim2.new(0, 260, 0, 70)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 220, 80)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0
	label.Parent = billboard
	return board
end

function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = Workspace

	-- Conveyor: the brainrot runway down the middle of the map.
	local conveyor = Instance.new("Folder")
	conveyor.Name = "Conveyor"
	conveyor.Parent = world
	newPart("Strip", Vector3.new(14, 1, 260), Color3.fromRGB(60, 60, 75), Vector3.new(0, 0, 0), conveyor)
	for _, side in ipairs({ -1, 1 }) do
		newPart("Rail", Vector3.new(0.6, 1.6, 260), Color3.fromRGB(255, 200, 60), Vector3.new(side * 7.2, 1.2, 0), conveyor, Enum.Material.Neon)
	end
	-- Chevrons pointing the way the brainrots walk (+Z).
	for z = -110, 110, 20 do
		local chevron = newPart("Chevron", Vector3.new(6, 0.2, 3), Color3.fromRGB(255, 220, 90), Vector3.new(0, 0.55, z), conveyor, Enum.Material.Neon)
		chevron.CFrame = CFrame.new(chevron.Position) * CFrame.Angles(0, math.rad(45), 0)
	end

	-- Welcome arch over the conveyor entrance.
	local arch = Instance.new("Folder")
	arch.Name = "Arch"
	arch.Parent = world
	for _, side in ipairs({ -1, 1 }) do
		newPart("ArchPost", Vector3.new(1.5, 12, 1.5), Color3.fromRGB(255, 90, 140), Vector3.new(side * 8, 6, -128), arch)
	end
	addSign(arch, Vector3.new(0, 12.5, -128), "BRAINROT BAZAAR", Color3.fromRGB(255, 220, 80), nil)

	-- Player bases: 4 on each side of the conveyor.
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world
	local bases = {}
	local index = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs(BASE_Z) do
			index += 1
			local center = Vector3.new(side * 45, 0, z)
			local color = BASE_COLORS[index]
			local baseFolder = Instance.new("Folder")
			baseFolder.Name = "Base" .. index
			baseFolder.Parent = basesFolder

			newPart("Platform", Vector3.new(26, 1, 26), color, center, baseFolder)
			-- Back wall on the outer edge so the base reads as a home, not a slab.
			newPart("BackWall", Vector3.new(1, 6, 26), Color3.fromRGB(40, 40, 55), center + Vector3.new(side * 12.5, 3, 0), baseFolder)
			-- 10 slots: 2 rows x 5 columns.
			local slots = {}
			for row = 0, 1 do
				for col = 0, 4 do
					local slotPos = center + Vector3.new(-8 + col * 4, 0.6, -4 + row * 8)
					newPart("SlotPad", Vector3.new(3.4, 0.2, 3.4), Color3.fromRGB(255, 255, 255), slotPos, baseFolder, Enum.Material.Neon)
					table.insert(slots, slotPos + Vector3.new(0, 0.1, 0))
				end
			end
			-- Spawn pad on the conveyor-facing edge.
			local spawnPos = center + Vector3.new(side * -16, 1, 0)
			newPart("SpawnPad", Vector3.new(4, 0.2, 4), Color3.fromRGB(120, 255, 140), spawnPos, baseFolder, Enum.Material.Neon)
			addSign(baseFolder, center + Vector3.new(0, 8, 0), "BASE " .. index, color, nil)

			table.insert(bases, {
				index = index,
				center = center,
				spawnPos = spawnPos,
				slots = slots,
				ownerUserId = nil,
				color = color,
			})
		end
	end

	-- Decor: trees around the edges and lamps along the conveyor.
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = world
	local treeSpots = {
		Vector3.new(-70, 0, -120), Vector3.new(70, 0, -120),
		Vector3.new(-70, 0, -60), Vector3.new(70, 0, -60),
		Vector3.new(-70, 0, 0), Vector3.new(70, 0, 0),
		Vector3.new(-70, 0, 60), Vector3.new(70, 0, 60),
		Vector3.new(-70, 0, 120), Vector3.new(70, 0, 120),
		Vector3.new(-30, 0, -135), Vector3.new(30, 0, -135),
		Vector3.new(-30, 0, 135), Vector3.new(30, 0, 135),
	}
	for i, spot in ipairs(treeSpots) do
		local trunk = Instance.new("Part")
		trunk.Name = "TreeTrunk" .. i
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Size = Vector3.new(6, 1.6, 1.6)
		trunk.Color = Color3.fromRGB(120, 80, 40)
		trunk.Anchored = true
		trunk.CanCollide = true
		trunk.CFrame = CFrame.new(spot + Vector3.new(0, 3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		trunk.Parent = decor
		local leaves = Instance.new("Part")
		leaves.Name = "TreeLeaves" .. i
		leaves.Shape = Enum.PartType.Ball
		leaves.Size = Vector3.new(7, 7, 7)
		leaves.Color = Color3.fromRGB(60, 180, 80)
		leaves.Anchored = true
		leaves.CanCollide = false
		leaves.Position = spot + Vector3.new(0, 8, 0)
		leaves.Parent = decor
	end
	for _, z in ipairs({ -90, -30, 30, 90 }) do
		for _, side in ipairs({ -1, 1 }) do
			newPart("LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(50, 50, 60), Vector3.new(side * 10, 3.5, z), decor)
			newPart("LampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), Vector3.new(side * 10, 7.4, z), decor, Enum.Material.Neon)
		end
	end

	return bases
end

return WorldBuilder

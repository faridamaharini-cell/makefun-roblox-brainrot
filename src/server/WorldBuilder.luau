-- WorldBuilder: builds the whole Brainrot Bay island out of plain Parts.
-- No asset ids anywhere: the beach, the 300-stud conveyor, ten bases in two
-- rows of five, the spawn plaza, palms, market stalls, lamps, bunting, the
-- animated water at the map edge and the big BRAINROT BAY sign are all made
-- here, in code. Lighting is set to Future with a warm afternoon sun.
-- v3.1: the sand beach sits clearly above the project baseplate (no more
-- grey z-fight), and a little town grew around the plaza: a detailed barn,
-- shops and houses with pitched roofs, a gatehouse, wooden fences along
-- the conveyor, round trees, bushes, crates, barrels and hay bales.
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

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
	Color3.fromRGB(140, 220, 255),
	Color3.fromRGB(190, 255, 140),
}

local BASE_Z = { -120, -60, 0, 60, 120 }
local SLOT_COLS = { -11, -6.6, -2.2, 2.2, 6.6, 11 }
local SLOT_ROWS = { -8, 0, 8 }

-- Top of the sand beach. The project baseplate's top is at Y=0, so the
-- beach (and everything standing on it) uses this as its ground level.
local BEACH_TOP_Y = 0.2

-- Building scale: v3.3 makes the town's buildings ~1.8x bigger (Rot Ranch
-- reference), so they clearly tower over the ~5-stud player. Scaled
-- around each building's own ground centre. Every building helper
-- multiplies its widths, heights and offsets by BS.
local BS = 1.8

local function part(name, size, color, position, parent, material, collide)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = collide ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Position = position
	p.Parent = parent
	return p
end

-- A dark board with a floating text label that always faces the camera.
local function signBoard(parent, position, text, textColor, boardSize)
	local board = part("Sign", boardSize or Vector3.new(16, 4.5, 0.6), Color3.fromRGB(30, 30, 42), position, parent)
	local gui = Instance.new("BillboardGui")
	gui.Name = "SignLabel"
	gui.Size = UDim2.new(0, 300, 0, 80)
	gui.AlwaysOnTop = true
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "SignText"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = textColor or Color3.fromRGB(255, 220, 80)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBlack
	label.TextStrokeTransparency = 0
	label.Parent = gui
	return board, label
end

local function palmTree(parent, spot, index)
	local trunk = Instance.new("Part")
	trunk.Name = "PalmTrunk" .. index
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(9, 1.8, 1.8)
	trunk.Color = Color3.fromRGB(140, 95, 50)
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.CFrame = CFrame.new(spot + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Parent = parent
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local leaf = Instance.new("Part")
		leaf.Name = "PalmLeaf" .. index .. "_" .. i
		leaf.Shape = Enum.PartType.Ball
		leaf.Size = Vector3.new(4.5, 2.2, 4.5)
		leaf.Color = Color3.fromRGB(50, 185, 80)
		leaf.Anchored = true
		leaf.CanCollide = false
		leaf.Position = spot + Vector3.new(math.cos(angle) * 2.6, 9.2, math.sin(angle) * 2.6)
		leaf.Parent = parent
	end
	local crown = Instance.new("Part")
	crown.Name = "PalmCrown" .. index
	crown.Shape = Enum.PartType.Ball
	crown.Size = Vector3.new(5, 4, 5)
	crown.Color = Color3.fromRGB(60, 200, 90)
	crown.Anchored = true
	crown.CanCollide = false
	crown.Position = spot + Vector3.new(0, 9.6, 0)
	crown.Parent = parent
end

local function marketStall(parent, position, stripeA, stripeB, index)
	local stall = Instance.new("Folder")
	stall.Name = "Stall" .. index
	stall.Parent = parent
	part("Counter", Vector3.new(8, 2.4, 3), Color3.fromRGB(150, 100, 55), position + Vector3.new(0, 1.2, 0), stall, Enum.Material.Wood)
	for _, side in ipairs({ -1, 1 }) do
		part("StallPost", Vector3.new(0.5, 5, 0.5), Color3.fromRGB(90, 60, 35), position + Vector3.new(side * 3.8, 2.5, 0), stall, Enum.Material.Wood)
	end
	-- Striped awning: six alternating panels sloping gently forward.
	for i = 0, 5 do
		local color = (i % 2 == 0) and stripeA or stripeB
		local panel = part("Awning", Vector3.new(1.5, 0.25, 4.4), color, position + Vector3.new(-3.75 + i * 1.5, 5.2, 0.4), stall, Enum.Material.Fabric, false)
		panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(math.rad(-12), 0, 0)
	end
end

-- Pitched roof: two slanted panels meeting at a ridge, plus a ridge beam.
-- `center` is the ridge centre; halfSpan is the horizontal distance from
-- ridge to eave (including overhang), rise is eave-to-ridge height, len is
-- the roof length along the ridge. ridgeAxis "X" or "Z".
local function pitchedRoof(parent, center, halfSpan, rise, len, color, ridgeAxis)
	local slopeLen = math.sqrt(halfSpan * halfSpan + rise * rise) + 0.4
	local angle = math.atan(rise / halfSpan)
	for _, side in ipairs({ -1, 1 }) do
		local panel
		if ridgeAxis == "X" then
			panel = part("RoofPanel", Vector3.new(len, 0.4 * BS, slopeLen), color, center + Vector3.new(0, -rise / 2, side * halfSpan / 2), parent, Enum.Material.SmoothPlastic, false)
			panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(side * angle, 0, 0)
		else
			panel = part("RoofPanel", Vector3.new(slopeLen, 0.4 * BS, len), color, center + Vector3.new(side * halfSpan / 2, -rise / 2, 0), parent, Enum.Material.SmoothPlastic, false)
			panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(0, 0, -side * angle)
		end
	end
	if ridgeAxis == "X" then
		part("RidgeBeam", Vector3.new(len, 0.6 * BS, 0.6 * BS), Color3.fromRGB(90, 60, 35), center, parent, Enum.Material.Wood)
	else
		part("RidgeBeam", Vector3.new(0.6 * BS, 0.6 * BS, len), Color3.fromRGB(90, 60, 35), center, parent, Enum.Material.Wood)
	end
end

-- A window on a wall facing +/-X: white frame + light-blue glass.
local function xWindow(parent, x, y, z, facing)
	part("WindowFrame", Vector3.new(0.2 * BS, 2.2 * BS, 2.6 * BS), Color3.fromRGB(255, 255, 255), Vector3.new(x + facing * 0.1 * BS, y, z), parent, Enum.Material.SmoothPlastic, false)
	part("WindowGlass", Vector3.new(0.26 * BS, 1.8 * BS, 2.2 * BS), Color3.fromRGB(150, 210, 255), Vector3.new(x + facing * 0.14 * BS, y, z), parent, Enum.Material.Glass, false)
end

-- A detailed beach house: wood walls, white base trim, door + windows on
-- the conveyor-facing side, pitched roof with ridge beam, chimney, and a
-- little porch (floor, posts, striped awning). facing +1 = front toward
-- +X, -1 = front toward -X.
local function house(parent, pos, wallColor, roofColor, facing, index)
	local home = Instance.new("Folder")
	home.Name = "House" .. index
	home.Parent = parent
	local W, D, H = 10 * BS, 8 * BS, 7 * BS
	local baseY = BEACH_TOP_Y
	part("Walls", Vector3.new(W, H, D), wallColor, pos + Vector3.new(0, baseY + H / 2, 0), home, Enum.Material.Wood)
	part("BaseTrim", Vector3.new(W + 0.4 * BS, 0.5 * BS, D + 0.4 * BS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 0.25 * BS, 0), home, Enum.Material.SmoothPlastic, false)
	local faceX = pos.X + facing * (W / 2)
	part("Door", Vector3.new(0.3 * BS, 3.6 * BS, 2 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(faceX + facing * 0.16 * BS, baseY + 1.8 * BS, pos.Z), home, Enum.Material.Wood)
	xWindow(home, faceX, baseY + 3.6 * BS, pos.Z - 2.6 * BS, facing)
	xWindow(home, faceX, baseY + 3.6 * BS, pos.Z + 2.6 * BS, facing)
	local ridgeY = baseY + H + 3 * BS
	pitchedRoof(home, Vector3.new(pos.X, ridgeY, pos.Z), W / 2 + 1 * BS, 3 * BS, D + 1 * BS, roofColor, "Z")
	local cx = pos.X + 3 * BS
	part("Chimney", Vector3.new(1.2 * BS, 3 * BS, 1.2 * BS), Color3.fromRGB(150, 60, 60), Vector3.new(cx, ridgeY - 1 * BS, pos.Z - 2 * BS), home, Enum.Material.SmoothPlastic)
	part("ChimneyCap", Vector3.new(1.8 * BS, 0.5 * BS, 1.8 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(cx, ridgeY + 0.7 * BS, pos.Z - 2 * BS), home, Enum.Material.SmoothPlastic, false)
	local porchX = faceX + facing * 1.6 * BS
	part("PorchFloor", Vector3.new(3 * BS, 0.3 * BS, 4.5 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(porchX, baseY + 0.15 * BS, pos.Z), home, Enum.Material.Wood)
	for _, pz in ipairs({ -1.8 * BS, 1.8 * BS }) do
		part("PorchPost", Vector3.new(0.5 * BS, 4.4 * BS, 0.5 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(porchX + facing * 1.2 * BS, baseY + 2.2 * BS, pos.Z + pz), home, Enum.Material.Wood)
	end
	local awn = part("PorchAwning", Vector3.new(3.2 * BS, 0.25 * BS, 4.6 * BS), roofColor, Vector3.new(porchX + facing * 0.4 * BS, baseY + 4.4 * BS, pos.Z), home, Enum.Material.Fabric, false)
	awn.CFrame = CFrame.new(awn.Position) * CFrame.Angles(0, 0, facing * math.rad(-12))
end

-- A big red barn: double doors with a beam, hayloft door + beam, windows
-- on both long sides, pitched roof (ridge along X), chimney and porch.
-- The front faces +Z (toward the plaza).
local function barn(parent, pos, wallColor, roofColor, index)
	local b = Instance.new("Folder")
	b.Name = "Barn" .. index
	b.Parent = parent
	local W, D, H = 14 * BS, 10 * BS, 9 * BS
	local baseY = BEACH_TOP_Y
	part("Walls", Vector3.new(W, H, D), wallColor, pos + Vector3.new(0, baseY + H / 2, 0), b, Enum.Material.Wood)
	part("BaseTrim", Vector3.new(W + 0.4 * BS, 0.5 * BS, D + 0.4 * BS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 0.25 * BS, 0), b, Enum.Material.SmoothPlastic, false)
	local faceZ = pos.Z + D / 2
	for _, dx in ipairs({ -1.3 * BS, 1.3 * BS }) do
		part("BarnDoor", Vector3.new(2.4 * BS, 4.6 * BS, 0.3 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X + dx, baseY + 2.3 * BS, faceZ + 0.16 * BS), b, Enum.Material.Wood)
	end
	part("DoorBeam", Vector3.new(5.6 * BS, 0.5 * BS, 0.35 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X, baseY + 4.9 * BS, faceZ + 0.16 * BS), b, Enum.Material.Wood)
	part("LoftDoor", Vector3.new(2 * BS, 2 * BS, 0.3 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X, baseY + 7 * BS, faceZ + 0.16 * BS), b, Enum.Material.Wood)
	part("LoftBeam", Vector3.new(3 * BS, 0.4 * BS, 0.4 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X, baseY + 8.3 * BS, faceZ + 0.2 * BS), b, Enum.Material.Wood)
	for _, sx in ipairs({ -1, 1 }) do
		local wx = pos.X + sx * (W / 2)
		xWindow(b, wx, baseY + 4.5 * BS, pos.Z - 2.5 * BS, sx)
		xWindow(b, wx, baseY + 4.5 * BS, pos.Z + 2.5 * BS, sx)
	end
	local ridgeY = baseY + H + 3.5 * BS
	pitchedRoof(b, Vector3.new(pos.X, ridgeY, pos.Z), D / 2 + 1 * BS, 3.5 * BS, W + 1 * BS, roofColor, "X")
	part("Chimney", Vector3.new(1.2 * BS, 3 * BS, 1.2 * BS), Color3.fromRGB(150, 60, 60), Vector3.new(pos.X - 3 * BS, ridgeY - 1 * BS, pos.Z + 3 * BS), b, Enum.Material.SmoothPlastic)
	part("ChimneyCap", Vector3.new(1.8 * BS, 0.5 * BS, 1.8 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X - 3 * BS, ridgeY + 0.7 * BS, pos.Z + 3 * BS), b, Enum.Material.SmoothPlastic, false)
	local porchZ = faceZ + 1.6 * BS
	part("PorchFloor", Vector3.new(6 * BS, 0.3 * BS, 3 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X, baseY + 0.15 * BS, porchZ), b, Enum.Material.Wood)
	for _, px in ipairs({ -2.6 * BS, 2.6 * BS }) do
		part("PorchPost", Vector3.new(0.5 * BS, 5.4 * BS, 0.5 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X + px, baseY + 2.9 * BS, porchZ + 1.2 * BS), b, Enum.Material.Wood)
	end
	local awn = part("PorchAwning", Vector3.new(6.2 * BS, 0.25 * BS, 3.2 * BS), roofColor, Vector3.new(pos.X, baseY + 5.4 * BS, porchZ + 0.4 * BS), b, Enum.Material.Fabric, false)
	awn.CFrame = CFrame.new(awn.Position) * CFrame.Angles(math.rad(12), 0, 0)
end

-- A market shop: big display window, door, striped awning, sign board,
-- pitched roof (ridge along X) and chimney. The front faces +Z.
local function shop(parent, pos, wallColor, roofColor, index)
	local s = Instance.new("Folder")
	s.Name = "Shop" .. index
	s.Parent = parent
	local W, D, H = 11 * BS, 9 * BS, 7 * BS
	local baseY = BEACH_TOP_Y
	part("Walls", Vector3.new(W, H, D), wallColor, pos + Vector3.new(0, baseY + H / 2, 0), s, Enum.Material.Wood)
	part("BaseTrim", Vector3.new(W + 0.4 * BS, 0.5 * BS, D + 0.4 * BS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 0.25 * BS, 0), s, Enum.Material.SmoothPlastic, false)
	local faceZ = pos.Z + D / 2
	part("Door", Vector3.new(2 * BS, 3.6 * BS, 0.3 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X - 2.5 * BS, baseY + 1.8 * BS, faceZ + 0.16 * BS), s, Enum.Material.Wood)
	part("ShopWindowFrame", Vector3.new(4.5 * BS, 2.6 * BS, 0.2 * BS), Color3.fromRGB(255, 255, 255), Vector3.new(pos.X + 2 * BS, baseY + 3.4 * BS, faceZ + 0.1 * BS), s, Enum.Material.SmoothPlastic, false)
	part("ShopWindowGlass", Vector3.new(4.1 * BS, 2.2 * BS, 0.26 * BS), Color3.fromRGB(150, 210, 255), Vector3.new(pos.X + 2 * BS, baseY + 3.4 * BS, faceZ + 0.14 * BS), s, Enum.Material.Glass, false)
	xWindow(s, pos.X + W / 2, baseY + 3.6 * BS, pos.Z, 1)
	xWindow(s, pos.X - W / 2, baseY + 3.6 * BS, pos.Z, -1)
	signBoard(s, Vector3.new(pos.X, baseY + 5.8 * BS, faceZ + 0.4 * BS), "TIDE SHOP", Color3.fromRGB(255, 220, 80), Vector3.new(8 * BS, 2.5 * BS, 0.4 * BS))
	local ridgeY = baseY + H + 3 * BS
	pitchedRoof(s, Vector3.new(pos.X, ridgeY, pos.Z), D / 2 + 1 * BS, 3 * BS, W + 1 * BS, roofColor, "X")
	part("Chimney", Vector3.new(1.2 * BS, 3 * BS, 1.2 * BS), Color3.fromRGB(150, 60, 60), Vector3.new(pos.X + 3 * BS, ridgeY - 1 * BS, pos.Z + 2 * BS), s, Enum.Material.SmoothPlastic)
	part("ChimneyCap", Vector3.new(1.8 * BS, 0.5 * BS, 1.8 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(pos.X + 3 * BS, ridgeY + 0.7 * BS, pos.Z + 2 * BS), s, Enum.Material.SmoothPlastic, false)
	for i = 0, 2 do
		local color = (i % 2 == 0) and roofColor or Color3.fromRGB(255, 255, 255)
		local panel = part("ShopAwning", Vector3.new(1.6 * BS, 0.25 * BS, 2.2 * BS), color, Vector3.new(pos.X + 0.4 * BS + i * 1.6 * BS, baseY + 5.0 * BS, faceZ + 0.9 * BS), s, Enum.Material.Fabric, false)
		panel.CFrame = CFrame.new(panel.Position) * CFrame.Angles(math.rad(12), 0, 0)
	end
	part("PorchFloor", Vector3.new(4 * BS, 0.3 * BS, 2.5 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X - 2.5 * BS, baseY + 0.15 * BS, faceZ + 1.4 * BS), s, Enum.Material.Wood)
end

-- A small hut with a single-slope (shed) roof, door + windows on the
-- conveyor-facing side and a striped awning. facing +1 = front toward +X.
local function hut(parent, pos, wallColor, roofColor, facing, index)
	local h = Instance.new("Folder")
	h.Name = "Hut" .. index
	h.Parent = parent
	local W, D, H = 8 * BS, 7 * BS, 6 * BS
	local baseY = BEACH_TOP_Y
	part("Walls", Vector3.new(W, H, D), wallColor, pos + Vector3.new(0, baseY + H / 2, 0), h, Enum.Material.Wood)
	part("BaseTrim", Vector3.new(W + 0.4 * BS, 0.4 * BS, D + 0.4 * BS), Color3.fromRGB(255, 255, 255), pos + Vector3.new(0, baseY + 0.2 * BS, 0), h, Enum.Material.SmoothPlastic, false)
	local faceX = pos.X + facing * (W / 2)
	part("Door", Vector3.new(0.3 * BS, 3.2 * BS, 1.8 * BS), Color3.fromRGB(90, 60, 35), Vector3.new(faceX + facing * 0.16 * BS, baseY + 1.6 * BS, pos.Z), h, Enum.Material.Wood)
	xWindow(h, faceX, baseY + 3.4 * BS, pos.Z - 2.2 * BS, facing)
	xWindow(h, faceX, baseY + 3.4 * BS, pos.Z + 2.2 * BS, facing)
	local roof = part("ShedRoof", Vector3.new(W + 1.5 * BS, 0.35 * BS, D + 1 * BS), roofColor, Vector3.new(pos.X, baseY + H + 1.6 * BS, pos.Z), h, Enum.Material.SmoothPlastic, false)
	roof.CFrame = CFrame.new(roof.Position) * CFrame.Angles(0, 0, facing * math.rad(-20))
	local awn = part("HutAwning", Vector3.new(2.8 * BS, 0.25 * BS, 3.4 * BS), roofColor, Vector3.new(faceX + facing * 0.9 * BS, baseY + 5.2 * BS, pos.Z), h, Enum.Material.Fabric, false)
	awn.CFrame = CFrame.new(awn.Position) * CFrame.Angles(0, 0, facing * math.rad(-12))
end

-- Gatehouse over the plaza walkway: two towers, a beam and a small pitched
-- cap. Players walk between the towers toward the conveyor.
local function gatehouse(parent, pos)
	local g = Instance.new("Folder")
	g.Name = "Gatehouse"
	g.Parent = parent
	local baseY = BEACH_TOP_Y
	for _, sx in ipairs({ -1, 1 }) do
		part("GateTower", Vector3.new(3 * BS, 9 * BS, 3 * BS), Color3.fromRGB(255, 200, 60), Vector3.new(pos.X + sx * 10 * BS, baseY + 4.5 * BS, pos.Z), g, Enum.Material.SmoothPlastic)
		part("TowerCap", Vector3.new(3.8 * BS, 0.6 * BS, 3.8 * BS), Color3.fromRGB(200, 120, 255), Vector3.new(pos.X + sx * 10 * BS, baseY + 9.3 * BS, pos.Z), g, Enum.Material.SmoothPlastic, false)
	end
	part("GateBeam", Vector3.new(23 * BS, 2 * BS, 3 * BS), Color3.fromRGB(150, 100, 55), Vector3.new(pos.X, baseY + 9.5 * BS, pos.Z), g, Enum.Material.Wood)
	pitchedRoof(g, Vector3.new(pos.X, baseY + 11.5 * BS, pos.Z), 2.5 * BS, 1.5 * BS, 24 * BS, Color3.fromRGB(255, 90, 90), "Z")
end

-- A wooden fence run along Z: posts every ~10 studs + two rails.
local function fenceRun(parent, x, zA, zB, index)
	local f = Instance.new("Folder")
	f.Name = "Fence" .. index
	f.Parent = parent
	local baseY = BEACH_TOP_Y
	local n = math.floor((zB - zA) / 10 + 0.5)
	for i = 0, n do
		local z = zA + (zB - zA) * (i / n)
		part("FencePost", Vector3.new(0.5, 3, 0.5), Color3.fromRGB(150, 100, 55), Vector3.new(x, baseY + 1.5, z), f, Enum.Material.Wood)
	end
	for _, ry in ipairs({ 1.2, 2.4 }) do
		part("FenceRail", Vector3.new(0.3, 0.3, zB - zA), Color3.fromRGB(150, 100, 55), Vector3.new(x, baseY + ry, (zA + zB) / 2), f, Enum.Material.Wood, false)
	end
end

-- A round leafy tree: trunk + three leaf balls.
local function roundTree(parent, spot, index)
	local t = Instance.new("Folder")
	t.Name = "Tree" .. index
	t.Parent = parent
	local baseY = BEACH_TOP_Y
	local trunk = Instance.new("Part")
	trunk.Name = "TreeTrunk"
	trunk.Shape = Enum.PartType.Cylinder
	trunk.Size = Vector3.new(7, 1.6, 1.6)
	trunk.Color = Color3.fromRGB(140, 95, 50)
	trunk.Anchored = true
	trunk.CanCollide = true
	trunk.CFrame = CFrame.new(spot + Vector3.new(0, baseY + 3.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	trunk.Parent = t
	for _, leaf in ipairs({
		{ Vector3.new(0, 8.5, 0), 6.5 },
		{ Vector3.new(-2.2, 7, 0), 4.5 },
		{ Vector3.new(2.2, 7, 0), 4.5 },
	}) do
		local ball = Instance.new("Part")
		ball.Name = "TreeLeaves"
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(leaf[2], leaf[2], leaf[2])
		ball.Color = Color3.fromRGB(50, 185, 80)
		ball.Anchored = true
		ball.CanCollide = false
		ball.Position = spot + leaf[1] + Vector3.new(0, baseY, 0)
		ball.Parent = t
	end
end

function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "World"
	world.Parent = Workspace

	-- Warm afternoon sun, Future lighting, a soft hazy sky.
	-- (Lighting.Technology is NOT written here: it needs the RobloxScript
	-- capability, which a game Script lacks, so writing it killed build()
	-- on its first Lighting line. Future is already baked into the place
	-- by default.project.json's Lighting properties.)
	Lighting.ClockTime = 15
	Lighting.Brightness = 2
	Lighting.Ambient = Color3.fromRGB(90, 80, 70)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 130, 150)
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(200, 220, 255)
	atmosphere.Decay = Color3.fromRGB(120, 140, 180)
	atmosphere.Glare = 0.4
	atmosphere.Haze = 1.5
	atmosphere.Parent = Lighting

	-- The beach itself: a wide sand plate whose top sits clearly above the
	-- project baseplate (top Y=0), so the sand wins the depth fight and the
	-- ground reads as a beach, not a grey baseplate.
	part("Beach", Vector3.new(460, 1, 400), Color3.fromRGB(238, 214, 150), Vector3.new(0, BEACH_TOP_Y - 0.5, 5), world, Enum.Material.Sand)

	-- Animated water hugging the far edges of the island.
	local water = Instance.new("Folder")
	water.Name = "Water"
	water.Parent = world
	local waterParts = {}
	for _, z in ipairs({ 208, -198 }) do
		local sea = part("Sea", Vector3.new(460, 1, 70), Color3.fromRGB(40, 140, 230), Vector3.new(0, 0, z), water, Enum.Material.Neon, false)
		sea.Transparency = 0.3
		table.insert(waterParts, sea)
	end
	task.spawn(function()
		local t = 0
		while world.Parent do
			t += 0.15
			for _, sea in ipairs(waterParts) do
				sea.Position = Vector3.new(0, math.sin(t) * 0.25, sea.Position.Z)
			end
			task.wait(0.15)
		end
	end)

	-- The conveyor: a 300-stud runway down the middle, Z -145 to 155.
	local conveyor = Instance.new("Folder")
	conveyor.Name = "Conveyor"
	conveyor.Parent = world
	part("Strip", Vector3.new(14, 1, 300), Color3.fromRGB(55, 55, 70), Vector3.new(0, 0.5, 5), conveyor)
	for _, side in ipairs({ -1, 1 }) do
		part("Rail", Vector3.new(0.6, 1.6, 300), Color3.fromRGB(255, 200, 60), Vector3.new(side * 7.2, 1.3, 5), conveyor, Enum.Material.Neon)
	end
	local chevrons = {}
	for z = -135, 145, 20 do
		local chevron = part("Chevron", Vector3.new(6, 0.2, 3), Color3.fromRGB(255, 220, 90), Vector3.new(0, 1.05, z), conveyor, Enum.Material.Neon, false)
		chevron.CFrame = CFrame.new(chevron.Position) * CFrame.Angles(0, math.rad(45), 0)
		table.insert(chevrons, chevron)
	end
	-- The belt scrolls: chevrons drift toward +Z and wrap back to the start.
	task.spawn(function()
		while world.Parent do
			task.wait(0.12)
			for _, chevron in ipairs(chevrons) do
				local z = chevron.Position.Z + 1.2
				if z > 150 then
					z = -140
				end
				chevron.CFrame = CFrame.new(0, 1.05, z) * CFrame.Angles(0, math.rad(45), 0)
			end
		end
	end)

	-- Welcome arch over the conveyor entrance, with the island's name.
	local arch = Instance.new("Folder")
	arch.Name = "Arch"
	arch.Parent = world
	for _, side in ipairs({ -1, 1 }) do
		part("ArchPost", Vector3.new(1.5, 13, 1.5), Color3.fromRGB(255, 90, 140), Vector3.new(side * 8, 6.5, -148), arch)
	end
	signBoard(arch, Vector3.new(0, 14, -148), "BRAINROT BAY", Color3.fromRGB(255, 220, 80), Vector3.new(30, 5, 0.6))

	-- Spawn plaza: checker tiles where newcomers first land.
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = world
	for row = 0, 3 do
		for col = 0, 7 do
			local color = ((row + col) % 2 == 0) and Color3.fromRGB(255, 240, 200) or Color3.fromRGB(90, 200, 230)
			part("PlazaTile", Vector3.new(4.8, 0.2, 4.8), color, Vector3.new(-17.5 + col * 5, BEACH_TOP_Y + 0.1, -172 + row * 5), plaza, Enum.Material.SmoothPlastic, false)
		end
	end
	signBoard(plaza, Vector3.new(0, 9, -178), "WELCOME TO THE BAY", Color3.fromRGB(120, 255, 140), Vector3.new(24, 4, 0.6))

	-- Ten bases: two rows of five flanking the conveyor.
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world
	local bases = {}
	local index = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs(BASE_Z) do
			index += 1
			local center = Vector3.new(side * 48, 1, z)
			local color = BASE_COLORS[index]
			local baseFolder = Instance.new("Folder")
			baseFolder.Name = "Base" .. index
			baseFolder.Parent = basesFolder

			part("Platform", Vector3.new(30, 1, 30), color, center + Vector3.new(0, -0.5, 0), baseFolder)
			part("BackWall", Vector3.new(1, 6, 30), Color3.fromRGB(40, 40, 55), center + Vector3.new(side * 14.5, 3, 0), baseFolder)
			-- 18 slot pads (3 rows x 6): 12 unlocked at start, +2 per
			-- capacity level up to 20. Pads past the current cap are just
			-- decoration until an upgrade unlocks them.
			local slots = {}
			for _, rz in ipairs(SLOT_ROWS) do
				for _, cx in ipairs(SLOT_COLS) do
					local slotPos = center + Vector3.new(cx, 0.6, rz)
					part("SlotPad", Vector3.new(3.4, 0.2, 3.4), Color3.fromRGB(255, 255, 255), slotPos, baseFolder, Enum.Material.Neon, false)
					table.insert(slots, slotPos + Vector3.new(0, 0.1, 0))
				end
			end
			-- Green spawn pad on the conveyor-facing edge.
			local spawnPos = center + Vector3.new(side * -18, 1, 0)
			part("SpawnPad", Vector3.new(4, 0.2, 4), Color3.fromRGB(120, 255, 140), spawnPos, baseFolder, Enum.Material.Neon, false)
			local _, signLabel = signBoard(baseFolder, center + Vector3.new(0, 9, 0), "BASE " .. index, color)
			-- Lock force-field: invisible until the base is locked.
			local lockField = part("LockField", Vector3.new(30, 8, 30), Color3.fromRGB(90, 160, 255), center + Vector3.new(0, 4, 0), baseFolder, Enum.Material.Neon, false)
			lockField.Transparency = 1

			table.insert(bases, {
				index = index,
				center = center,
				spawnPos = spawnPos,
				slots = slots,
				ownerUserId = nil,
				color = color,
				folder = baseFolder,
				signLabel = signLabel,
				lockField = lockField,
			})
		end
	end

	-- Decor: palms around the edges, stalls near the plaza, lamps and
	-- bunting along the conveyor so the bay reads as a night market.
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = world
	local treeSpots = {
		Vector3.new(-75, 0, -120), Vector3.new(75, 0, -120),
		Vector3.new(-75, 0, -60), Vector3.new(75, 0, -60),
		Vector3.new(-75, 0, 0), Vector3.new(75, 0, 0),
		Vector3.new(-75, 0, 60), Vector3.new(75, 0, 60),
		Vector3.new(-75, 0, 120), Vector3.new(75, 0, 120),
		Vector3.new(-30, 0, -165), Vector3.new(30, 0, -165),
		Vector3.new(-30, 0, 175), Vector3.new(30, 0, 175),
	}
	for i, spot in ipairs(treeSpots) do
		palmTree(decor, spot, i)
	end

	marketStall(decor, Vector3.new(-26, 0, -160), Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 255, 255), 1)
	marketStall(decor, Vector3.new(26, 0, -160), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 255, 255), 2)
	marketStall(decor, Vector3.new(-26, 0, 172), Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 255, 255), 3)
	marketStall(decor, Vector3.new(26, 0, 172), Color3.fromRGB(120, 220, 120), Color3.fromRGB(255, 255, 255), 4)

	for _, z in ipairs({ -100, -40, 20, 80, 140 }) do
		for _, side in ipairs({ -1, 1 }) do
			part("LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(50, 50, 60), Vector3.new(side * 10, 3.5, z), decor)
			part("LampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), Vector3.new(side * 10, 7.4, z), decor, Enum.Material.Neon, false)
		end
	end
	-- Bunting: little coloured flags strung between the lamp tops.
	local flagColors = {
		Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(120, 220, 120), Color3.fromRGB(90, 160, 255),
		Color3.fromRGB(200, 120, 255),
	}
	for _, side in ipairs({ -1, 1 }) do
		for i = 1, 4 do
			local zA = ({ -100, -40, 20, 80 })[i]
			local zB = ({ -40, 20, 80, 140 })[i]
			for f = 1, 5 do
				local z = zA + (zB - zA) * (f / 6)
				local flag = part("Flag", Vector3.new(1.4, 1.6, 0.15), flagColors[(f % #flagColors) + 1], Vector3.new(side * 10, 6.6, z), decor, Enum.Material.Fabric, false)
				flag.CFrame = CFrame.new(flag.Position) * CFrame.Angles(math.rad(20), 0, 0)
			end
		end
	end

	-- v3.1 town: barns, shops and houses with pitched roofs, a gatehouse,
	-- fences, trees and props — the bay reads as a busy little town now.
	local buildings = Instance.new("Folder")
	buildings.Name = "Buildings"
	buildings.Parent = world
	-- Town centre by the spawn plaza: a barn and a shop facing the plaza.
	barn(buildings, Vector3.new(-45, 0, -178), Color3.fromRGB(200, 60, 60), Color3.fromRGB(90, 60, 35), 1)
	shop(buildings, Vector3.new(45, 0, -178), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 160, 255), 1)
	-- Houses flanking the conveyor, fronts facing the conveyor. At BS 1.8
	-- they sit at X ±25 so the bigger porches clear the fences at X ±9.
	house(buildings, Vector3.new(-25, 0, -30), Color3.fromRGB(120, 220, 120), Color3.fromRGB(200, 60, 60), 1, 1)
	house(buildings, Vector3.new(25, 0, -30), Color3.fromRGB(90, 160, 255), Color3.fromRGB(255, 200, 60), -1, 2)
	house(buildings, Vector3.new(-25, 0, 30), Color3.fromRGB(200, 120, 255), Color3.fromRGB(90, 220, 210), 1, 3)
	house(buildings, Vector3.new(25, 0, 30), Color3.fromRGB(255, 140, 200), Color3.fromRGB(120, 220, 120), -1, 4)
	-- Smaller huts further down the conveyor.
	hut(buildings, Vector3.new(-20, 0, -90), Color3.fromRGB(255, 160, 80), Color3.fromRGB(90, 160, 255), 1, 1)
	hut(buildings, Vector3.new(20, 0, 90), Color3.fromRGB(140, 220, 255), Color3.fromRGB(200, 60, 60), -1, 2)
	-- Gatehouse over the plaza walkway.
	gatehouse(buildings, Vector3.new(0, 0, -160))

	-- Wooden fences along both sides of the conveyor, with gaps at each
	-- base front so players can walk from the conveyor to their base.
	local fences = Instance.new("Folder")
	fences.Name = "Fences"
	fences.Parent = world
	local fenceIndex = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, seg in ipairs({ { -105, -75 }, { -45, -15 }, { 15, 45 }, { 75, 105 } }) do
			fenceIndex += 1
			fenceRun(fences, side * 9, seg[1], seg[2], fenceIndex)
		end
	end

	-- Greenery: round trees and bushes scattered in the free ground.
	local greenery = Instance.new("Folder")
	greenery.Name = "Greenery"
	greenery.Parent = world
	for i, spot in ipairs({
		Vector3.new(-70, 0, -90), Vector3.new(70, 0, -90),
		Vector3.new(-70, 0, -30), Vector3.new(70, 0, -30),
		Vector3.new(-70, 0, 30), Vector3.new(70, 0, 30),
	}) do
		roundTree(greenery, spot, i)
	end
	for _, spot in ipairs({
		Vector3.new(14, 0, -110), Vector3.new(-14, 0, 50),
		Vector3.new(14, 0, 10), Vector3.new(-14, 0, -10),
		Vector3.new(26, 0, -75), Vector3.new(-26, 0, 75),
		Vector3.new(26, 0, 140), Vector3.new(-26, 0, -140),
	}) do
		local bush = Instance.new("Part")
		bush.Name = "Bush"
		bush.Shape = Enum.PartType.Ball
		bush.Size = Vector3.new(3, 3, 3)
		bush.Color = Color3.fromRGB(60, 200, 90)
		bush.Anchored = true
		bush.CanCollide = false
		bush.Position = spot + Vector3.new(0, BEACH_TOP_Y + 1.5, 0)
		bush.Parent = greenery
	end

	-- Props: crates, barrels, hay bales, goods on the stall counters,
	-- lamps by the plaza and big readable signs on posts.
	local props = Instance.new("Folder")
	props.Name = "Props"
	props.Parent = world
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(-24, BEACH_TOP_Y + 1.25, -156), props, Enum.Material.Wood)
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(-24, BEACH_TOP_Y + 3.75, -156), props, Enum.Material.Wood)
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(24, BEACH_TOP_Y + 1.25, 170), props, Enum.Material.Wood)
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(24, BEACH_TOP_Y + 3.75, 170), props, Enum.Material.Wood)
	-- Props moved out of the barn/shop footprints when the buildings grew
	-- to BS 1.8 (barn spans X -57.6..-32.4, shop X 35.1..54.9, Z -187..-169).
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(-62, BEACH_TOP_Y + 1.25, -156), props, Enum.Material.Wood)
	part("Crate", Vector3.new(2.5, 2.5, 2.5), Color3.fromRGB(150, 100, 55), Vector3.new(62, BEACH_TOP_Y + 1.25, -156), props, Enum.Material.Wood)
	for _, spot in ipairs({ Vector3.new(24, 0, -156), Vector3.new(-24, 0, 168), Vector3.new(-60, 0, -160), Vector3.new(60, 0, -160) }) do
		local barrel = Instance.new("Part")
		barrel.Name = "Barrel"
		barrel.Shape = Enum.PartType.Cylinder
		barrel.Size = Vector3.new(2.5, 2, 2)
		barrel.Color = Color3.fromRGB(120, 80, 40)
		barrel.Anchored = true
		barrel.CanCollide = true
		barrel.CFrame = CFrame.new(spot + Vector3.new(0, BEACH_TOP_Y + 1.25, 0)) * CFrame.Angles(0, 0, math.rad(90))
		barrel.Parent = props
	end
	for _, spot in ipairs({ Vector3.new(-63, 0, -186), Vector3.new(-60, 0, -186), Vector3.new(60, 0, -186), Vector3.new(63, 0, -186) }) do
		local bale = Instance.new("Part")
		bale.Name = "HayBale"
		bale.Shape = Enum.PartType.Cylinder
		bale.Size = Vector3.new(3, 2.2, 2.2)
		bale.Color = Color3.fromRGB(230, 200, 80)
		bale.Anchored = true
		bale.CanCollide = true
		bale.Position = spot + Vector3.new(0, BEACH_TOP_Y + 1.1, 0)
		bale.Parent = props
	end
	for _, g in ipairs({
		{ Vector3.new(-26, 0, -160), Color3.fromRGB(255, 90, 90) },
		{ Vector3.new(26, 0, -160), Color3.fromRGB(90, 160, 255) },
		{ Vector3.new(-26, 0, 172), Color3.fromRGB(255, 200, 60) },
		{ Vector3.new(26, 0, 172), Color3.fromRGB(120, 220, 120) },
	}) do
		part("Goods", Vector3.new(1.5, 1.5, 1.5), g[2], g[1] + Vector3.new(0, 3.1, 0), props, Enum.Material.SmoothPlastic, false)
	end
	for _, spot in ipairs({ Vector3.new(-14, 0, -168), Vector3.new(14, 0, -168) }) do
		part("LampPole", Vector3.new(0.6, 7, 0.6), Color3.fromRGB(50, 50, 60), spot + Vector3.new(0, BEACH_TOP_Y + 3.5, 0), props)
		part("LampHead", Vector3.new(1.6, 1, 1.6), Color3.fromRGB(255, 240, 160), spot + Vector3.new(0, BEACH_TOP_Y + 7.4, 0), props, Enum.Material.Neon, false)
	end
	for _, s in ipairs({
		{ Vector3.new(-14, 0, -152), "MARKET" },
		{ Vector3.new(14, 0, 152), "FRESH BRAINROTS" },
	}) do
		local sp = s[1]
		for _, sx in ipairs({ -1, 1 }) do
			part("SignPost", Vector3.new(0.5, 6, 0.5), Color3.fromRGB(90, 60, 35), sp + Vector3.new(sx * 7, BEACH_TOP_Y + 3, 0), props, Enum.Material.Wood)
		end
		signBoard(props, sp + Vector3.new(0, BEACH_TOP_Y + 7, 0), s[2], Color3.fromRGB(255, 220, 80), Vector3.new(16, 4, 0.6))
	end

	return bases
end

return WorldBuilder

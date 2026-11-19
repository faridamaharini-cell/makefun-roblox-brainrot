-- HUD: builds the whole interface in code (ScreenGui over the 3D world).
-- Money top-centre (clear of Roblox's top-left menu buttons), action buttons
-- bottom-right, a context line bottom-centre, toasts under the money bar.
local HUD = {}

local function makeLabel(name, parent, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

local function makeButton(name, parent, text, size, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.TextStrokeTransparency = 0
	button.AutoButtonColor = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

function HUD.build(player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBazaarGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Money bar, top-centre.
	local moneyFrame = Instance.new("Frame")
	moneyFrame.Name = "MoneyFrame"
	moneyFrame.AnchorPoint = Vector2.new(0.5, 0)
	moneyFrame.Position = UDim2.new(0.5, 0, 0, 12)
	moneyFrame.Size = UDim2.new(0, 340, 0, 64)
	moneyFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	moneyFrame.BackgroundTransparency = 0.25
	moneyFrame.BorderSizePixel = 0
	moneyFrame.Parent = gui
	local moneyCorner = Instance.new("UICorner")
	moneyCorner.CornerRadius = UDim.new(0, 12)
	moneyCorner.Parent = moneyFrame

	local moneyLabel = makeLabel("MoneyLabel", moneyFrame, "$100", UDim2.new(1, 0, 0.55, 0), UDim2.new(0, 0, 0, 0), 30, Color3.fromRGB(120, 255, 140))
	local incomeLabel = makeLabel("IncomeLabel", moneyFrame, "+$0/s  •  Rebirth x1", UDim2.new(1, 0, 0.4, 0), UDim2.new(0, 0, 0.55, 0), 18, Color3.fromRGB(255, 220, 90))

	-- Toast line under the money bar.
	local toastLabel = makeLabel("ToastLabel", gui, "", UDim2.new(0, 640, 0, 30), UDim2.new(0.5, -320, 0, 86), 20, Color3.fromRGB(255, 255, 255))
	toastLabel.AnchorPoint = Vector2.new(0.5, 0)

	-- Context line: what the nearest brainrot is, bottom-centre.
	local contextLabel = makeLabel("ContextLabel", gui, "Walk up to a brainrot on the conveyor — press E to buy it!", UDim2.new(0, 640, 0, 34), UDim2.new(0.5, -320, 1, -120), 20, Color3.fromRGB(255, 255, 255))
	contextLabel.AnchorPoint = Vector2.new(0.5, 0)

	-- Action buttons, bottom-right.
	local lockButton = makeButton("LockButton", gui, "🔒 Lock Base (L)", UDim2.new(0, 220, 0, 48), UDim2.new(1, -240, 1, -120), Color3.fromRGB(60, 120, 255))
	local rebirthButton = makeButton("RebirthButton", gui, "✨ Rebirth (R)", UDim2.new(0, 220, 0, 48), UDim2.new(1, -240, 1, -64), Color3.fromRGB(160, 60, 220))

	-- Controls help, bottom-left.
	makeLabel("HelpLabel", gui, "Move: WASD / Arrows  •  E: Buy  •  F: Slap  •  L: Lock  •  R: Rebirth", UDim2.new(0, 460, 0, 26), UDim2.new(0, 16, 1, -36), 16, Color3.fromRGB(230, 230, 230))

	-- Title, top-right (away from the Roblox menu buttons).
	makeLabel("TitleLabel", gui, "🧠 BRAINROT BAZAAR", UDim2.new(0, 300, 0, 30), UDim2.new(1, -316, 0, 12), 22, Color3.fromRGB(255, 220, 80))

	return {
		gui = gui,
		moneyLabel = moneyLabel,
		incomeLabel = incomeLabel,
		toastLabel = toastLabel,
		contextLabel = contextLabel,
		lockButton = lockButton,
		rebirthButton = rebirthButton,
	}
end

return HUD

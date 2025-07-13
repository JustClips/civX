
-- Eps1llon Hub Inventory & Hotbar, 2025 – Fixed Inventory Opening & Complete Drag System
local player = game:GetService("Players").LocalPlayer
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

if not player.Character then player.CharacterAdded:Wait() end

local HOTBAR_SLOTS = 5
local INVENTORY_SLOTS = 16 -- 4x4 grid
local SLOT_SIZE_HOTBAR = 58
local SLOT_SIZE_INVENTORY = 58
local SLOT_SPACING = 8

-- Drag state variables
local isDragging = false
local dragObject = nil
local dragFrame = nil
local dragStartPos = nil
local originalParent = nil
local dragSourceSlot = nil
local dragSourceType = nil
local dragStartTime = 0

-- Armor icons with your specified assets
local ArmorImageMap = {
	["Helmet"] = "rbxassetid://90312969969176",      -- First slot (top)
	["Chestplate"] = "rbxassetid://130576150893908", -- Updated chestplate asset
	["Tunic"] = ""                                   -- Third slot (bottom) - empty for now
}

local TOOL_SLOT_MAP = {
	["Wood Knife"] = 1, ["Small Rock"] = 2, ["Sword"] = 3, ["Axe"] = 4, ["Bow"] = 5,
}
local SLOT_TOOL_MAP = {}
for toolName, slotIndex in pairs(TOOL_SLOT_MAP) do SLOT_TOOL_MAP[slotIndex] = toolName end

local lastClickTime = {} for i = 1, HOTBAR_SLOTS do lastClickTime[i] = 0 end

local function hideAllRobloxInventoryUI()
	spawn(function()
		while true do
			wait(0.1)
			pcall(function()
				local playerGui = player:WaitForChild("PlayerGui")
				local backpackGui = playerGui:FindFirstChild("Backpack")
				if backpackGui then backpackGui.Enabled = false end
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
		end
	end)
end

hideAllRobloxInventoryUI()
local playerGui = player:WaitForChild("PlayerGui")
local existingHotbar = playerGui:FindFirstChild("CustomHotbar")
if existingHotbar then existingHotbar:Destroy() end
local existingInventory = playerGui:FindFirstChild("InventoryGUI")
if existingInventory then existingInventory:Destroy() end

------------------ HOTBAR (BOTTOM CENTER) WITH BACKPACK BUTTON ------------------
local hotbarGui = Instance.new("ScreenGui")
hotbarGui.Name = "CustomHotbar"
hotbarGui.ResetOnSpawn = false
hotbarGui.DisplayOrder = 100
hotbarGui.Parent = playerGui

local hotbarFrame = Instance.new("Frame")
hotbarFrame.AnchorPoint = Vector2.new(0.5, 1)
hotbarFrame.Position = UDim2.new(0.5, 0, 1, -24)
hotbarFrame.Size = UDim2.new(0, HOTBAR_SLOTS * SLOT_SIZE_HOTBAR + (HOTBAR_SLOTS-1) * SLOT_SPACING + 70, 0, SLOT_SIZE_HOTBAR)
hotbarFrame.BackgroundTransparency = 1
hotbarFrame.Parent = hotbarGui

-- Backpack Button (left side of hotbar) - Dark Theme
local backpackBtn = Instance.new("TextButton")
backpackBtn.Size = UDim2.new(0, SLOT_SIZE_HOTBAR, 0, SLOT_SIZE_HOTBAR)
backpackBtn.Position = UDim2.new(0, 0, 0, 0)
backpackBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
backpackBtn.BackgroundTransparency = 0.2
backpackBtn.BorderSizePixel = 0
backpackBtn.AutoButtonColor = false
backpackBtn.Text = ""
backpackBtn.Parent = hotbarFrame

local backpackStroke = Instance.new("UIStroke", backpackBtn)
backpackStroke.Color = Color3.fromRGB(120, 120, 120)
backpackStroke.Thickness = 2
backpackStroke.Transparency = 0.4

local backpackCorner = Instance.new("UICorner", backpackBtn)
backpackCorner.CornerRadius = UDim.new(0, 12)

local backpackIcon = Instance.new("ImageLabel")
backpackIcon.Name = "BackpackIcon"
backpackIcon.Size = UDim2.new(0.8, 0, 0.8, 0)
backpackIcon.Position = UDim2.new(0.1, 0, 0.1, 0)
backpackIcon.BackgroundTransparency = 1
backpackIcon.Image = "rbxassetid://122441752637461"
backpackIcon.ScaleType = Enum.ScaleType.Fit
backpackIcon.Parent = backpackBtn

-- Hotbar slots (shifted right to make room for backpack button) - Dark Theme
local hotbarSlots = {}
for i = 1, HOTBAR_SLOTS do
	local slotBtn = Instance.new("TextButton")
	slotBtn.Size = UDim2.new(0, SLOT_SIZE_HOTBAR, 0, SLOT_SIZE_HOTBAR)
	slotBtn.Position = UDim2.new(0, 70 + (i-1)*(SLOT_SIZE_HOTBAR+SLOT_SPACING), 0, 0)
	slotBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	slotBtn.BackgroundTransparency = 0.1
	slotBtn.BorderSizePixel = 0
	slotBtn.AutoButtonColor = false
	slotBtn.Text = ""
	slotBtn.Parent = hotbarFrame

	local uiStroke = Instance.new("UIStroke", slotBtn)
	uiStroke.Color = Color3.fromRGB(100, 100, 100)
	uiStroke.Thickness = 2
	uiStroke.Transparency = 0.3

	local uicorner = Instance.new("UICorner", slotBtn)
	uicorner.CornerRadius = UDim.new(0, 12)

	local numLabel = Instance.new("TextLabel")
	numLabel.Size = UDim2.new(0, 16, 0, 14)
	numLabel.Position = UDim2.new(0, 6, 0, 6)
	numLabel.BackgroundTransparency = 1
	numLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	numLabel.Font = Enum.Font.GothamSemibold
	numLabel.TextSize = 12
	numLabel.Text = tostring(i)
	numLabel.TextXAlignment = Enum.TextXAlignment.Left
	numLabel.TextYAlignment = Enum.TextYAlignment.Top
	numLabel.Parent = slotBtn

	local iconImg = Instance.new("ImageLabel")
	iconImg.Name = "Icon"
	iconImg.Size = UDim2.new(1, -12, 0.6, 0)
	iconImg.Position = UDim2.new(0, 6, 0, 8)
	iconImg.BackgroundTransparency = 1
	iconImg.Visible = false
	iconImg.Parent = slotBtn

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 16)
	nameLabel.Position = UDim2.new(0, 5, 0.7, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 10
	nameLabel.TextStrokeTransparency = 0.95
	nameLabel.Text = ""
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.ClipsDescendants = true
	nameLabel.RichText = false
	nameLabel.Parent = slotBtn

	hotbarSlots[i] = {btn = slotBtn, num = numLabel, outline = uiStroke, icon = iconImg, name = nameLabel, slotIndex = i}
end

------------------ INVENTORY GUI - DARK THEME ------------------
local inventoryGui = Instance.new("ScreenGui")
inventoryGui.Name = "InventoryGUI"
inventoryGui.ResetOnSpawn = false
inventoryGui.DisplayOrder = 200
inventoryGui.IgnoreGuiInset = true
inventoryGui.Parent = playerGui

local invFrame = Instance.new("Frame")
invFrame.Name = "InventoryFrame"
invFrame.AnchorPoint = Vector2.new(0.5,0.5)
invFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
invFrame.Size = UDim2.new(0, 650, 0, 410)
invFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
invFrame.BackgroundTransparency = 0.1
invFrame.BorderSizePixel = 0
invFrame.Visible = false
invFrame.ClipsDescendants = false -- Changed to false so drag works outside bounds
invFrame.Parent = inventoryGui
invFrame.ZIndex = 10

local invCorner = Instance.new("UICorner")
invCorner.CornerRadius = UDim.new(0, 22)
invCorner.Parent = invFrame

local invStroke = Instance.new("UIStroke")
invStroke.Thickness = 2
invStroke.Color = Color3.fromRGB(80, 80, 80)
invStroke.Transparency = 0.2
invStroke.Parent = invFrame

-- Centered Title
local titleText = Instance.new("TextLabel")
titleText.Name = "TitleText"
titleText.Size = UDim2.new(1, 0, 0, 50)
titleText.Position = UDim2.new(0, 0, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Inventory"
titleText.TextColor3 = Color3.fromRGB(220,220,220)
titleText.TextSize = 33
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Center
titleText.TextYAlignment = Enum.TextYAlignment.Center
titleText.ZIndex = 11
titleText.Parent = invFrame

-- Close Button ("-") top right - Dark Theme
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -44, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
closeBtn.TextSize = 24
closeBtn.Font = Enum.Font.GothamBlack
closeBtn.ZIndex = 20
closeBtn.Parent = invFrame
local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(1, 0)
closeBtnCorner.Parent = closeBtn

closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(255,100,100) end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = Color3.fromRGB(180,180,180) end)

-- ARMOR SLOTS (3 slots on the left side, aligned with avatar) - Dark Theme
local armorSlotW, armorSlotH = 50, 50
local armorSlots = {}

-- Calculate alignment with avatar
local avatarStartY = 105
local avatarHeight = 170
local totalArmorHeight = (armorSlotH * 3) + (10 * 2)
local armorStartY = avatarStartY + (avatarHeight - totalArmorHeight) / 2

-- First slot (top) - Helmet
local slot1 = Instance.new("Frame")
slot1.Name = "ArmorSlot1"
slot1.Size = UDim2.new(0, armorSlotW, 0, armorSlotH)
slot1.Position = UDim2.new(0, 15, 0, armorStartY)
slot1.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
slot1.BackgroundTransparency = 0.15
slot1.BorderSizePixel = 0
slot1.ZIndex = 21
slot1.Parent = invFrame
local slot1Corner = Instance.new("UICorner")
slot1Corner.CornerRadius = UDim.new(0, 10)
slot1Corner.Parent = slot1
local slot1Stroke = Instance.new("UIStroke")
slot1Stroke.Thickness = 2
slot1Stroke.Color = Color3.fromRGB(90, 90, 90)
slot1Stroke.Transparency = 0.3
slot1Stroke.Parent = slot1

local slot1Img = Instance.new("ImageLabel")
slot1Img.Name = "Slot1Img"
slot1Img.Size = UDim2.new(0.65,0,0.65,0)
slot1Img.Position = UDim2.new(0.175,0,0.05,0)
slot1Img.BackgroundTransparency = 1
slot1Img.Image = ArmorImageMap["Helmet"]
slot1Img.Visible = true
slot1Img.ZIndex = 22
slot1Img.Parent = slot1

local slot1Label = Instance.new("TextLabel")
slot1Label.Name = "Slot1Label"
slot1Label.Size = UDim2.new(1, -4, 0, 14)
slot1Label.Position = UDim2.new(0, 2, 1, -16)
slot1Label.BackgroundTransparency = 1
slot1Label.Text = "Helmet"
slot1Label.TextColor3 = Color3.fromRGB(200, 200, 200)
slot1Label.TextSize = 9
slot1Label.Font = Enum.Font.GothamBold
slot1Label.TextXAlignment = Enum.TextXAlignment.Center
slot1Label.TextTruncate = Enum.TextTruncate.AtEnd
slot1Label.ZIndex = 23
slot1Label.Parent = slot1

-- Second slot (middle) - Chestplate
local slot2 = Instance.new("Frame")
slot2.Name = "ArmorSlot2"
slot2.Size = UDim2.new(0, armorSlotW, 0, armorSlotH)
slot2.Position = UDim2.new(0, 15, 0, armorStartY + armorSlotH + 10)
slot2.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
slot2.BackgroundTransparency = 0.15
slot2.BorderSizePixel = 0
slot2.ZIndex = 21
slot2.Parent = invFrame
local slot2Corner = Instance.new("UICorner")
slot2Corner.CornerRadius = UDim.new(0, 10)
slot2Corner.Parent = slot2
local slot2Stroke = Instance.new("UIStroke")
slot2Stroke.Thickness = 2
slot2Stroke.Color = Color3.fromRGB(90, 90, 90)
slot2Stroke.Transparency = 0.3
slot2Stroke.Parent = slot2

local slot2Img = Instance.new("ImageLabel")
slot2Img.Name = "Slot2Img"
slot2Img.Size = UDim2.new(0.65,0,0.65,0)
slot2Img.Position = UDim2.new(0.175,0,0.05,0)
slot2Img.BackgroundTransparency = 1
slot2Img.Image = ArmorImageMap["Chestplate"]
slot2Img.Visible = true
slot2Img.ZIndex = 22
slot2Img.Parent = slot2

local slot2Label = Instance.new("TextLabel")
slot2Label.Name = "Slot2Label"
slot2Label.Size = UDim2.new(1, -4, 0, 14)
slot2Label.Position = UDim2.new(0, 2, 1, -16)
slot2Label.BackgroundTransparency = 1
slot2Label.Text = "Chestplate"
slot2Label.TextColor3 = Color3.fromRGB(200, 200, 200)
slot2Label.TextSize = 8
slot2Label.Font = Enum.Font.GothamBold
slot2Label.TextXAlignment = Enum.TextXAlignment.Center
slot2Label.TextTruncate = Enum.TextTruncate.AtEnd
slot2Label.ZIndex = 23
slot2Label.Parent = slot2

-- Third slot (bottom) - Empty
local slot3 = Instance.new("Frame")
slot3.Name = "ArmorSlot3"
slot3.Size = UDim2.new(0, armorSlotW, 0, armorSlotH)
slot3.Position = UDim2.new(0, 15, 0, armorStartY + (armorSlotH + 10) * 2)
slot3.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
slot3.BackgroundTransparency = 0.15
slot3.BorderSizePixel = 0
slot3.ZIndex = 21
slot3.Parent = invFrame
local slot3Corner = Instance.new("UICorner")
slot3Corner.CornerRadius = UDim.new(0, 10)
slot3Corner.Parent = slot3
local slot3Stroke = Instance.new("UIStroke")
slot3Stroke.Thickness = 2
slot3Stroke.Color = Color3.fromRGB(90, 90, 90)
slot3Stroke.Transparency = 0.3
slot3Stroke.Parent = slot3

local slot3Img = Instance.new("ImageLabel")
slot3Img.Name = "Slot3Img"
slot3Img.Size = UDim2.new(0.65,0,0.65,0)
slot3Img.Position = UDim2.new(0.175,0,0.05,0)
slot3Img.BackgroundTransparency = 1
slot3Img.Image = ""
slot3Img.Visible = false
slot3Img.ZIndex = 22
slot3Img.Parent = slot3

local slot3Label = Instance.new("TextLabel")
slot3Label.Name = "Slot3Label"
slot3Label.Size = UDim2.new(1, -4, 0, 14)
slot3Label.Position = UDim2.new(0, 2, 1, -16)
slot3Label.BackgroundTransparency = 1
slot3Label.Text = "Empty"
slot3Label.TextColor3 = Color3.fromRGB(120, 120, 120)
slot3Label.TextSize = 9
slot3Label.Font = Enum.Font.GothamBold
slot3Label.TextXAlignment = Enum.TextXAlignment.Center
slot3Label.TextTruncate = Enum.TextTruncate.AtEnd
slot3Label.ZIndex = 23
slot3Label.Parent = slot3

armorSlots = {slot1, slot2, slot3}

-- Avatar (Dark Theme)
local avatarFrame = Instance.new("Frame")
avatarFrame.Size = UDim2.new(0, 120, 0, 170)
avatarFrame.Position = UDim2.new(0, 75, 0, avatarStartY)
avatarFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
avatarFrame.BackgroundTransparency = 0.2
avatarFrame.BorderSizePixel = 0
avatarFrame.ZIndex = 11
avatarFrame.Parent = invFrame
local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(0, 15)
avatarCorner.Parent = avatarFrame

local avatarStroke = Instance.new("UIStroke")
avatarStroke.Thickness = 2
avatarStroke.Color = Color3.fromRGB(80, 80, 80)
avatarStroke.Transparency = 0.3
avatarStroke.Parent = avatarFrame

local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size180x180
local avatarImg = Instance.new("ImageLabel")
avatarImg.Size = UDim2.new(1, -16, 1, -16)
avatarImg.Position = UDim2.new(0, 8, 0, 8)
avatarImg.BackgroundTransparency = 1
avatarImg.ScaleType = Enum.ScaleType.Fit
avatarImg.ZIndex = 12
avatarImg.Parent = avatarFrame
local function updateAvatar()
	local userId = player.UserId
	local thumbContent, _ = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
	avatarImg.Image = thumbContent
end
updateAvatar()

-- Age (Dark Theme)
local userAge = 16
local ageLabel = Instance.new("TextLabel")
ageLabel.Size = UDim2.new(1, -12, 0, 32)
ageLabel.Position = UDim2.new(0, 6, 1, -40)
ageLabel.BackgroundTransparency = 1
ageLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
ageLabel.Font = Enum.Font.GothamBlack
ageLabel.TextSize = 22
ageLabel.TextXAlignment = Enum.TextXAlignment.Center
ageLabel.TextYAlignment = Enum.TextYAlignment.Center
ageLabel.Text = "Age: "..tostring(userAge)
ageLabel.ZIndex = 14
ageLabel.Parent = avatarFrame

-- Height (Dark Theme)
local userHeight = 1.75
local heightLabel = Instance.new("TextLabel")
heightLabel.Size = UDim2.new(1, -14, 0, 22)
heightLabel.Position = UDim2.new(0, 7, 1, -18)
heightLabel.BackgroundTransparency = 1
heightLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
heightLabel.Font = Enum.Font.GothamBold
heightLabel.TextSize = 14
heightLabel.TextXAlignment = Enum.TextXAlignment.Center
heightLabel.TextYAlignment = Enum.TextYAlignment.Center
heightLabel.Text = "Current Height: "..tostring(userHeight).."m"
heightLabel.ZIndex = 14
heightLabel.Parent = avatarFrame

-- Health and Thirst bars (Dark Theme)
local healthBarFrame = Instance.new("Frame")
healthBarFrame.Size = UDim2.new(0, 18, 0, 170)
healthBarFrame.Position = UDim2.new(0, 205, 0, avatarStartY)
healthBarFrame.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
healthBarFrame.BorderSizePixel = 0
healthBarFrame.ZIndex = 13
healthBarFrame.Parent = invFrame
local healthBarCorner = Instance.new("UICorner")
healthBarCorner.CornerRadius = UDim.new(0, 10)
healthBarCorner.Parent = healthBarFrame

local healthFill = Instance.new("Frame")
healthFill.Size = UDim2.new(1, 0, 1, 0)
healthFill.Position = UDim2.new(0, 0, 0, 0)
healthFill.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
healthFill.BorderSizePixel = 0
healthFill.ZIndex = 14
healthFill.Parent = healthBarFrame
local healthFillCorner = Instance.new("UICorner")
healthFillCorner.CornerRadius = UDim.new(0, 10)
healthFillCorner.Parent = healthFill

local thirstBarFrame = Instance.new("Frame")
thirstBarFrame.Size = UDim2.new(0, 18, 0, 170)
thirstBarFrame.Position = UDim2.new(0, 230, 0, avatarStartY)
thirstBarFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
thirstBarFrame.BorderSizePixel = 0
thirstBarFrame.ZIndex = 13
thirstBarFrame.Parent = invFrame
local thirstBarCorner = Instance.new("UICorner")
thirstBarCorner.CornerRadius = UDim.new(0, 10)
thirstBarCorner.Parent = thirstBarFrame

local thirstFill = Instance.new("Frame")
thirstFill.Size = UDim2.new(1, 0, 1, 0)
thirstFill.Position = UDim2.new(0, 0, 0, 0)
thirstFill.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
thirstFill.BorderSizePixel = 0
thirstFill.ZIndex = 14
thirstFill.Parent = thirstBarFrame
local thirstFillCorner = Instance.new("UICorner")
thirstFillCorner.CornerRadius = UDim.new(0, 10)
thirstFillCorner.Parent = thirstFill

-- Update bars
local thirstValue = 100
local function updateHealthBar()
	local char = player.Character
	if char and char:FindFirstChildOfClass("Humanoid") then
		local hum = char:FindFirstChildOfClass("Humanoid")
		local percent = math.clamp(hum.Health/hum.MaxHealth,0,1)
		healthFill.Size = UDim2.new(1,0,percent,0)
		healthFill.Position = UDim2.new(0,0,1-percent,0)
	end
end
if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
	player.Character:FindFirstChildOfClass("Humanoid").HealthChanged:Connect(updateHealthBar)
end
player.CharacterAdded:Connect(function(char)
	repeat wait() until char:FindFirstChildOfClass("Humanoid")
	char:FindFirstChildOfClass("Humanoid").HealthChanged:Connect(updateHealthBar)
	updateHealthBar()
end)
updateHealthBar()

local function updateThirstBar()
	local percent = math.clamp(thirstValue / 100,0,1)
	thirstFill.Size = UDim2.new(1,0,percent,0)
	thirstFill.Position = UDim2.new(0,0,1-percent,0)
end
updateThirstBar()
spawn(function()
	while true do
		wait(1)
		thirstValue = math.max(thirstValue - 0.2, 0)
		updateThirstBar()
	end
end)

-- Inventory Grid (Dark Theme)
local invGridContainer = Instance.new("Frame")
invGridContainer.Name = "InvGridContainer"
invGridContainer.Size = UDim2.new(0, 308, 0, 308)
invGridContainer.Position = UDim2.new(0, 260, 0, 80)
invGridContainer.BackgroundTransparency = 1
invGridContainer.ZIndex = 12
invGridContainer.Parent = invFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, SLOT_SIZE_INVENTORY, 0, SLOT_SIZE_INVENTORY)
gridLayout.CellPadding = UDim2.new(0, SLOT_SPACING, 0, SLOT_SPACING)
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = invGridContainer

local inventorySlots = {}
for i = 1, INVENTORY_SLOTS do
	local slotFrame = Instance.new("Frame")
	slotFrame.Name = "Slot"..i
	slotFrame.Size = UDim2.new(0, SLOT_SIZE_INVENTORY, 0, SLOT_SIZE_INVENTORY)
	slotFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	slotFrame.BackgroundTransparency = 0.2
	slotFrame.BorderSizePixel = 0
	slotFrame.LayoutOrder = i
	slotFrame.ZIndex = 13
	slotFrame.Parent = invGridContainer

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 8)
	slotCorner.Parent = slotFrame

	local slotStroke = Instance.new("UIStroke")
	slotStroke.Thickness = 2
	slotStroke.Color = Color3.fromRGB(80, 80, 80)
	slotStroke.Transparency = 0.4
	slotStroke.Parent = slotFrame

	local toolImage = Instance.new("ImageLabel")
	toolImage.Name = "ToolImage"
	toolImage.Size = UDim2.new(1, -14, 0.6, 0)
	toolImage.Position = UDim2.new(0, 7, 0, 6)
	toolImage.BackgroundTransparency = 1
	toolImage.Visible = false
	toolImage.ZIndex = 15
	toolImage.Parent = slotFrame

	local toolLabel = Instance.new("TextLabel")
	toolLabel.Name = "ToolLabel"
	toolLabel.Size = UDim2.new(1, -8, 0, 20)
	toolLabel.Position = UDim2.new(0, 4, 0.65, 0)
	toolLabel.BackgroundTransparency = 1
	toolLabel.Text = ""
	toolLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	toolLabel.TextSize = 10
	toolLabel.Font = Enum.Font.GothamBold
	toolLabel.TextXAlignment = Enum.TextXAlignment.Center
	toolLabel.TextTruncate = Enum.TextTruncate.AtEnd
	toolLabel.ZIndex = 16
	toolLabel.Parent = slotFrame

	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.Position = UDim2.new(0, 0, 0, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 17
	clickBtn.Parent = slotFrame

	inventorySlots[i] = {
		frame = slotFrame,
		label = toolLabel,
		image = toolImage,
		button = clickBtn,
		slotIndex = i,
		stroke = slotStroke
	}
end

-- Drag Frame for animations (Dark Theme) - Higher ZIndex
local dragFrame = Instance.new("Frame")
dragFrame.Size = UDim2.new(0, 60, 0, 60)
dragFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dragFrame.BackgroundTransparency = 0.1
dragFrame.BorderSizePixel = 0
dragFrame.Visible = false
dragFrame.ZIndex = 2000 -- Very high ZIndex to appear above everything
dragFrame.Parent = playerGui -- Parented to playerGui to work outside inventory bounds

local dragCorner = Instance.new("UICorner")
dragCorner.CornerRadius = UDim.new(0, 8)
dragCorner.Parent = dragFrame

local dragStroke = Instance.new("UIStroke")
dragStroke.Thickness = 2
dragStroke.Color = Color3.fromRGB(150, 150, 150)
dragStroke.Transparency = 0.2
dragStroke.Parent = dragFrame

local dragImage = Instance.new("ImageLabel")
dragImage.Size = UDim2.new(0.7, 0, 0.7, 0)
dragImage.Position = UDim2.new(0.15, 0, 0.05, 0)
dragImage.BackgroundTransparency = 1
dragImage.ZIndex = 2001
dragImage.Parent = dragFrame

local dragLabel = Instance.new("TextLabel")
dragLabel.Size = UDim2.new(1, -4, 0, 16)
dragLabel.Position = UDim2.new(0, 2, 0.75, 0)
dragLabel.BackgroundTransparency = 1
dragLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
dragLabel.TextSize = 8
dragLabel.Font = Enum.Font.GothamBold
dragLabel.TextXAlignment = Enum.TextXAlignment.Center
dragLabel.TextTruncate = Enum.TextTruncate.AtEnd
dragLabel.ZIndex = 2001
dragLabel.Parent = dragFrame

local ToolImageMap = {
	["Wood Knife"] = "rbxassetid://14653143267",
	["Small Rock"] = "rbxassetid://15025907307",
	["Sword"] = "rbxassetid://7800035224",
	["Axe"] = "rbxassetid://14916078007",
	["Bow"] = "rbxassetid://14528967708",
	["Pickaxe"] = "rbxassetid://6744956242",
	["Hammer"] = "rbxassetid://14332896409",
	["Shield"] = "rbxassetid://13188705059",
	["Potion"] = "rbxassetid://10724660322",
	["Rope"] = "rbxassetid://13632624321"
}

local function getToolImage(tool)
	if ToolImageMap[tool.Name] then
		return ToolImageMap[tool.Name]
	elseif tool.TextureId and tool.TextureId ~= "" then
		return tool.TextureId
	end
	return ""
end

-- Fixed Drag and Drop Functions
local function startDrag(tool, sourceSlot, sourceType)
	if isDragging then return end
	isDragging = true
	dragObject = tool
	dragSourceSlot = sourceSlot
	dragSourceType = sourceType
	dragStartTime = tick()
	
	print("Starting drag with tool:", tool.Name, "from slot:", sourceSlot, "type:", sourceType)
	
	-- Setup drag frame
	dragFrame.Visible = true
	dragLabel.Text = tool.Name
	
	local imageId = getToolImage(tool)
	if imageId ~= "" then
		dragImage.Image = imageId
		dragImage.Visible = true
	else
		dragImage.Visible = false
	end
	
	-- Position drag frame at mouse
	local mouse = UserInputService:GetMouseLocation()
	dragFrame.Position = UDim2.new(0, mouse.X - 30, 0, mouse.Y - 30)
	
	-- Animation with enhanced effects
	dragFrame.Size = UDim2.new(0, 40, 0, 40)
	dragStroke.Color = Color3.fromRGB(150, 255, 150)
	TweenService:Create(dragFrame, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 60, 0, 60)
	}):Play()
	TweenService:Create(dragStroke, TweenInfo.new(0.1), {Transparency = 0.1}):Play()
end

local function updateDrag()
	if not isDragging then return end
	local mouse = UserInputService:GetMouseLocation()
	dragFrame.Position = UDim2.new(0, mouse.X - 30, 0, mouse.Y - 30)
end

-- Auto-overflow helper functions
local function isHotbarFull()
	for i = 1, HOTBAR_SLOTS do
		if not SLOT_TOOL_MAP[i] then
			return false
		end
	end
	return true
end

local function findFirstEmptyInventorySlot()
	local backpackTools = getBackpackDisplayTools()
	for i = 1, INVENTORY_SLOTS do
		if not backpackTools[i] then
			return i
		end
	end
	return nil
end

local function endDrag(targetSlot, targetType)
	if not isDragging then return end
	
	print("Ending drag. Target slot:", targetSlot, "Target type:", targetType)
	
	-- Animation
	TweenService:Create(dragFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
		Size = UDim2.new(0, 40, 0, 40),
		BackgroundTransparency = 0.8
	}):Play()
	TweenService:Create(dragStroke, TweenInfo.new(0.15), {Transparency = 0.8}):Play()
	
	spawn(function()
		wait(0.15)
		dragFrame.Visible = false
		dragFrame.BackgroundTransparency = 0.1
		dragStroke.Transparency = 0.2
		dragFrame.Size = UDim2.new(0, 60, 0, 60)
	end)
	
	-- Enhanced drop handling with proper synchronization
	if targetSlot and targetType and dragObject then
		local toolName = dragObject.Name
		print("Processing drop:", toolName, "from", dragSourceType, dragSourceSlot, "to", targetType, targetSlot)
		
		if dragSourceType == "hotbar" and targetType == "hotbar" then
			-- Hotbar to hotbar (reordering) - Fixed synchronization
			if dragSourceSlot ~= targetSlot then
				local sourceToolName = SLOT_TOOL_MAP[dragSourceSlot]
				local targetToolName = SLOT_TOOL_MAP[targetSlot]
				
				-- Clear old mappings properly
				if sourceToolName then 
					TOOL_SLOT_MAP[sourceToolName] = nil 
					SLOT_TOOL_MAP[dragSourceSlot] = nil
				end
				if targetToolName then 
					TOOL_SLOT_MAP[targetToolName] = nil 
					SLOT_TOOL_MAP[targetSlot] = nil
				end
				
				-- Set new mappings
				if sourceToolName then
					TOOL_SLOT_MAP[sourceToolName] = targetSlot
					SLOT_TOOL_MAP[targetSlot] = sourceToolName
				end
				if targetToolName then
					TOOL_SLOT_MAP[targetToolName] = dragSourceSlot
					SLOT_TOOL_MAP[dragSourceSlot] = targetToolName
				end
				
				-- Handle equipped tools
				local char = player.Character
				if char then
					local equippedTool = nil
					for _, tool in ipairs(char:GetChildren()) do
						if tool:IsA("Tool") then
							equippedTool = tool
							break
						end
					end
					
					-- Re-equip the tool if it was the one being dragged
					if equippedTool and equippedTool.Name == sourceToolName then
						equippedTool.Parent = player.Backpack
						spawn(function()
							wait(0.1)
							if char:FindFirstChild("Humanoid") then
								equippedTool.Parent = char
							end
						end)
					end
				end
			end
			
		elseif dragSourceType == "hotbar" and targetType == "inventory" then
			-- Hotbar to inventory - Fixed
			local toolName = SLOT_TOOL_MAP[dragSourceSlot]
			if toolName then
				SLOT_TOOL_MAP[dragSourceSlot] = nil
				TOOL_SLOT_MAP[toolName] = nil
				
				-- Move tool to backpack
				local char = player.Character
				if char and char:FindFirstChild(toolName) then
					char:FindFirstChild(toolName).Parent = player.Backpack
				end
			end
			
		elseif dragSourceType == "inventory" and targetType == "hotbar" then
			-- Inventory to hotbar - Fixed synchronization
			local oldToolName = SLOT_TOOL_MAP[targetSlot]
			
			-- Remove old tool from hotbar if exists
			if oldToolName then
				TOOL_SLOT_MAP[oldToolName] = nil
				SLOT_TOOL_MAP[targetSlot] = nil
				
				-- Move old tool to backpack
				local char = player.Character
				if char and char:FindFirstChild(oldToolName) then
					char:FindFirstChild(oldToolName).Parent = player.Backpack
				end
			end
			
			-- Add new tool to hotbar
			TOOL_SLOT_MAP[toolName] = targetSlot
			SLOT_TOOL_MAP[targetSlot] = toolName
			
			-- Equip the tool if this is the currently selected slot
			local char = player.Character
			if dragObject.Parent == player.Backpack and char then
				-- Unequip any currently equipped tool first
				for _, tool in ipairs(char:GetChildren()) do
					if tool:IsA("Tool") then
						tool.Parent = player.Backpack
					end
				end
				-- Equip the new tool
				dragObject.Parent = char
			end
			
		elseif dragSourceType == "inventory" and targetType == "inventory" then
			-- Inventory to inventory (reordering) - NEW FUNCTIONALITY
			if dragSourceSlot ~= targetSlot then
				local backpackTools = getBackpackDisplayTools()
				local sourceIndex = dragSourceSlot
				local targetIndex = targetSlot
				
				-- This is handled automatically by the backpack system
				-- No special mapping needed for inventory-to-inventory
				print("Inventory reordering not needed - handled by Roblox backpack system")
			end
		end
	end
	
	isDragging = false
	dragObject = nil
	dragSourceSlot = nil
	dragSourceType = nil
	
	-- Update all displays
	updateHotbar()
	updateInventorySlots()
	updateArmorSlots()
end

-- Mouse movement for drag
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		updateDrag()
	end
end)

-- Mouse release to end drag
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
		endDrag()
	end
end)

local function getBackpackDisplayTools()
	local backpack = player:FindFirstChild("Backpack")
	local tools = {}
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				if not TOOL_SLOT_MAP[tool.Name] then
					table.insert(tools, tool)
				end
			end
		end
	end
	return tools
end

local function getHotbarTools()
	local character = player.Character
	local backpack = player.Backpack
	local tools = {}
	if character and backpack then
		for i = 1, HOTBAR_SLOTS do
			local name = SLOT_TOOL_MAP[i]
			if name then
				local tool = character:FindFirstChild(name) or backpack:FindFirstChild(name)
				tools[i] = tool
			end
		end
	end
	return tools
end

local function equipToolToHotbarSlot(index)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	local toolName = SLOT_TOOL_MAP[index]
	if toolName and backpack and character then
		local tool = backpack:FindFirstChild(toolName)
		if tool then
			for _, v in ipairs(character:GetChildren()) do
				if v:IsA("Tool") then v.Parent = backpack end
			end
			tool.Parent = character
		elseif character:FindFirstChild(toolName) then
			character:FindFirstChild(toolName).Parent = backpack
		end
	end
end

local function updateHotbar()
	local tools = getHotbarTools()
	for i = 1, HOTBAR_SLOTS do
		local slot = hotbarSlots[i]
		local tool = tools[i]
		if tool then
			local imageId = getToolImage(tool)
			if imageId ~= "" then
				slot.icon.Image = imageId
				slot.icon.Visible = true
			else
				slot.icon.Visible = false
			end
			slot.name.Text = tool.Name
			slot.btn.BackgroundTransparency = 0.1
			slot.outline.Transparency = 0.1
		else
			slot.icon.Image = ""
			slot.icon.Visible = false
			slot.name.Text = ""
			slot.btn.BackgroundTransparency = 0.4
			slot.outline.Transparency = 0.5
		end
	end
end

local function updateInventorySlots()
	local backpackTools = getBackpackDisplayTools()
	for i = 1, INVENTORY_SLOTS do
		local slot = inventorySlots[i]
		local tool = backpackTools[i]
		if tool then
			slot.label.Text = tool.Name
			local img = getToolImage(tool)
			if img ~= "" then
				slot.image.Image = img
				slot.image.Visible = true
			else
				slot.image.Image = ""
				slot.image.Visible = false
			end
		else
			slot.label.Text = ""
			slot.image.Image = ""
			slot.image.Visible = false
		end
	end
end

local function updateArmorSlots()
	-- Armor slots show static images, no dynamic updates needed
end

-- Fixed Inventory State Management
local isInventoryOpen = false

local function openInventory()
	if isInventoryOpen then return end
	print("Opening inventory...")
	isInventoryOpen = true
	invFrame.Visible = true
	invFrame.BackgroundTransparency = 1
	updateAvatar()
	updateInventorySlots()
	updateHealthBar()
	updateArmorSlots()
	updateThirstBar()
	TweenService:Create(invFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency=0.1}):Play()
end

local function closeInventory()
	if not isInventoryOpen then return end
	print("Closing inventory...")
	isInventoryOpen = false
	local tween = TweenService:Create(invFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency=1})
	tween:Play()
	tween.Completed:Connect(function()
		if not isInventoryOpen then
			invFrame.Visible = false
		end
	end)
end

-- Fixed Backpack button click event
backpackBtn.MouseButton1Click:Connect(function()
	print("Backpack button clicked! Current state:", isInventoryOpen)
	if isInventoryOpen then
		closeInventory()
	else
		openInventory()
	end
end)

-- Backpack button hover effects
backpackBtn.MouseEnter:Connect(function()
	TweenService:Create(backpackStroke, TweenInfo.new(0.2), {Transparency = 0.1}):Play()
	TweenService:Create(backpackBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.05}):Play()
end)

backpackBtn.MouseLeave:Connect(function()
	TweenService:Create(backpackStroke, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
	TweenService:Create(backpackBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.2}):Play()
end)

-- Enhanced Hotbar slot events
for i = 1, HOTBAR_SLOTS do
	local slot = hotbarSlots[i]
	
	slot.btn.MouseButton1Click:Connect(function()
		if not isDragging then
			equipToolToHotbarSlot(i)
			updateHotbar()
			updateInventorySlots()
			updateArmorSlots()
		end
	end)
	
	-- Improved drag detection with better timing
	local mouseDownTime = 0
	slot.btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseDownTime = tick()
			local tools = getHotbarTools()
			local tool = tools[i]
			if tool and not isDragging then
				spawn(function()
					wait(0.15) -- Reduced delay for more responsive drag
					if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and (tick() - mouseDownTime) >= 0.15 then
						startDrag(tool, i, "hotbar")
					end
				end)
			end
		end
	end)
	
	slot.btn.MouseEnter:Connect(function()
		if isDragging then
			-- Enhanced visual feedback for valid drop target
			slot.outline.Color = Color3.fromRGB(100, 255, 100)
			slot.outline.Transparency = 0
			TweenService:Create(slot.btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.05}):Play()
		else
			-- Normal hover effect
			TweenService:Create(slot.outline, TweenInfo.new(0.1), {Transparency = 0.1}):Play()
		end
	end)
	
	slot.btn.MouseLeave:Connect(function()
		-- Reset to normal appearance
		slot.outline.Color = Color3.fromRGB(100, 100, 100)
		TweenService:Create(slot.outline, TweenInfo.new(0.1), {Transparency = 0.3}):Play()
		TweenService:Create(slot.btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.1}):Play()
	end)
	
	slot.btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
			endDrag(i, "hotbar")
		end
	end)
end

-- Enhanced Inventory slot events
for i = 1, INVENTORY_SLOTS do
	local slot = inventorySlots[i]
	
	-- Improved drag detection for inventory slots
	local mouseDownTime = 0
	slot.button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseDownTime = tick()
			local backpackTools = getBackpackDisplayTools()
			local tool = backpackTools[i]
			if tool and not isDragging then
				spawn(function()
					wait(0.15) -- Reduced delay for more responsive drag
					if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and (tick() - mouseDownTime) >= 0.15 then
						startDrag(tool, i, "inventory")
					end
				end)
			end
		end
	end)
	
	slot.frame.MouseEnter:Connect(function()
		if isDragging then
			-- Enhanced visual feedback for valid drop target
			slot.stroke.Color = Color3.fromRGB(100, 255, 100)
			slot.stroke.Transparency = 0
			TweenService:Create(slot.frame, TweenInfo.new(0.1), {BackgroundTransparency = 0.05}):Play()
		else
			-- Normal hover effect
			TweenService:Create(slot.stroke, TweenInfo.new(0.1), {Transparency = 0.2}):Play()
		end
	end)
	
	slot.frame.MouseLeave:Connect(function()
		-- Reset to normal appearance
		slot.stroke.Color = Color3.fromRGB(80, 80, 80)
		TweenService:Create(slot.stroke, TweenInfo.new(0.1), {Transparency = 0.4}):Play()
		TweenService:Create(slot.frame, TweenInfo.new(0.1), {BackgroundTransparency = 0.2}):Play()
	end)
	
	slot.button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
			endDrag(i, "inventory")
		end
	end)
end

closeBtn.MouseButton1Click:Connect(closeInventory)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local keyMap = {
		[Enum.KeyCode.One] = 1,
		[Enum.KeyCode.Two] = 2,
		[Enum.KeyCode.Three] = 3,
		[Enum.KeyCode.Four] = 4,
		[Enum.KeyCode.Five] = 5
	}
	if keyMap[input.KeyCode] then
		equipToolToHotbarSlot(keyMap[input.KeyCode])
		updateHotbar()
		updateInventorySlots()
		updateArmorSlots()
		updateThirstBar()
		return
	end
	if input.KeyCode == Enum.KeyCode.Backquote then
		if isInventoryOpen then
			closeInventory()
		else
			openInventory()
		end
	elseif input.KeyCode == Enum.KeyCode.Escape and isInventoryOpen then
		closeInventory()
	end
end)

-- Auto-assign new tools with overflow support
local function autoAssignTool(tool)
	if not tool or not tool:IsA("Tool") then return end
	
	-- Skip if tool is already assigned to a hotbar slot
	if TOOL_SLOT_MAP[tool.Name] then return end
	
	-- Try to assign to first empty hotbar slot
	for i = 1, HOTBAR_SLOTS do
		if not SLOT_TOOL_MAP[i] then
			TOOL_SLOT_MAP[tool.Name] = i
			SLOT_TOOL_MAP[i] = tool.Name
			print("Auto-assigned", tool.Name, "to hotbar slot", i)
			return
		end
	end
	
	-- Hotbar is full - tool will stay in inventory (auto-overflow)
	print("Hotbar full -", tool.Name, "placed in inventory (auto-overflow)")
end

local function connectEvents()
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	if backpack then
		backpack.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				-- Auto-assign new tools with overflow support
				autoAssignTool(child)
				wait(0.1)
				updateInventorySlots()
				updateHotbar()
				updateArmorSlots()
				updateThirstBar()
			end
		end)
		backpack.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				updateInventorySlots()
				updateHotbar()
				updateArmorSlots()
				updateThirstBar()
			end
		end)
	end
	if character then
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				updateHotbar()
				updateInventorySlots()
				updateArmorSlots()
				updateThirstBar()
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				updateHotbar()
				updateInventorySlots()
				updateArmorSlots()
				updateThirstBar()
			end
		end)
	end
end

player.CharacterAdded:Connect(function(newCharacter)
	wait(1)
	connectEvents()
	updateHotbar()
	updateInventorySlots()
	updateArmorSlots()
	updateThirstBar()
	hideAllRobloxInventoryUI()
end)

connectEvents()

-- Auto-assign existing tools in backpack
spawn(function()
	wait(1)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				autoAssignTool(tool)
			end
		end
	end
	updateHotbar()
	updateInventorySlots()
	updateArmorSlots()
	updateThirstBar()
end)

wait(1)
updateHotbar()
updateInventorySlots()
updateArmorSlots()
updateThirstBar()
print("Eps1llon: Fixed inventory system with working drag & drop, auto-overflow, and proper synchronization!")

-- [[ EXC HUB MM2 - Fixed & Universal Executor Support ]] --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

-- ลบ GUI เก่าถ้ามีอยู่
pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("EXCHubGUI") then
        game:GetService("CoreGui").EXCHubGUI:Destroy()
    end
    if LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("EXCHubGUI") then
        LocalPlayer.PlayerGui.EXCHubGUI:Destroy()
    end
end)

-- เช็คความสามารถ Executor (Drawing API)
local hasDrawing = (typeof(Drawing) == "table" or typeof(Drawing) == "userdata") and typeof(Drawing.new) == "function"

-- ==================== [ ระบบเสียง ] ==================== --
local ClickSound = Instance.new("Sound")
ClickSound.Name = "EXCClickSound"
ClickSound.SoundId = "rbxassetid://6895079853"
ClickSound.Volume = 0.5
ClickSound.Parent = SoundService

local function playSound()
    pcall(function() ClickSound:Play() end)
end

-- ==================== [ เช็คบทบาท MM2 ] ==================== --
local function getRole(plr)
    if not plr or not plr.Character then return "Innocent" end
    
    local backpack = plr:FindFirstChild("Backpack")
    local char = plr.Character

    local function checkContainer(container)
        if not container then return nil end
        for _, tool in pairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name == "knife" or name:find("knife") or tool:FindFirstChild("Blade") then
                    return "Murderer"
                elseif name == "gun" or name == "revolver" or name:find("gun") then
                    return "Sheriff"
                end
            end
        end
        return nil
    end

    return checkContainer(char) or checkContainer(backpack) or "Innocent"
end

local function getMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if getRole(p) == "Murderer" then
            return p
        end
    end
    return nil
end

-- ==================== [ GUI MAIN ] ==================== --
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EXCHubGUI"
ScreenGui.ResetOnSpawn = false

-- ระบบใส่ Parent แบบปลอดภัยทุก Executor
if gethui then
    ScreenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    pcall(function() syn.protect_gui(ScreenGui) end)
    ScreenGui.Parent = game:GetService("CoreGui")
else
    local success = pcall(function()
        ScreenGui.Parent = game:GetService("CoreGui")
    end)
    if not success then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- ==================== [ ปุ่มสวิตช์ล็อกลอยหน้าจอ ] ==================== --
local LockScreenBtn = Instance.new("TextButton")
LockScreenBtn.Name = "LockScreenBtn"
LockScreenBtn.Size = UDim2.new(0, 130, 0, 38)
LockScreenBtn.Position = UDim2.new(0.82, 0, 0.45, 0)
LockScreenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
LockScreenBtn.Text = "🎯 LOCK: OFF"
LockScreenBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
LockScreenBtn.TextSize = 10
LockScreenBtn.Font = Enum.Font.GothamBold
LockScreenBtn.Visible = false
LockScreenBtn.Parent = ScreenGui

local LockScreenCorner = Instance.new("UICorner")
LockScreenCorner.CornerRadius = UDim.new(0, 8)
LockScreenCorner.Parent = LockScreenBtn

local LockScreenStroke = Instance.new("UIStroke")
LockScreenStroke.Color = Color3.fromRGB(60, 60, 65)
LockScreenStroke.Thickness = 1.2
LockScreenStroke.Parent = LockScreenBtn

local isAimlockSystemEnabled = false
local isAimlockActive = false

LockScreenBtn.MouseButton1Click:Connect(function()
    playSound()
    if isAimlockSystemEnabled then
        isAimlockActive = not isAimlockActive
        if isAimlockActive then
            LockScreenBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
            LockScreenBtn.Text = "🎯 LOCK: ON"
            LockScreenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            LockScreenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            LockScreenBtn.Text = "🎯 LOCK: OFF"
            LockScreenBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
end)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 330)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(45, 45, 50)
MainStroke.Thickness = 1.2
MainStroke.Parent = MainFrame

-- ปุ่มเปิด/ปิด GUI
local ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 48, 0, 48)
ToggleBtn.Position = UDim2.new(0.03, 0, 0.15, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ToggleBtn.Image = "rbxthumb://type=Asset&id=105055399914466&w=420&h=420"
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleBtn

local toggleDragging, toggleDragStart, toggleStartPos, hasDragged = false, nil, nil, false
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging, hasDragged = true, false
        toggleDragStart, toggleStartPos = input.Position, ToggleBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if toggleDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - toggleDragStart
        if delta.Magnitude > 5 then hasDragged = true end
        ToggleBtn.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
    end
end)

ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging = false
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    playSound()
    if not hasDragged then MainFrame.Visible = not MainFrame.Visible end
end)

-- ==================== [ ด้านซ้าย: เมนู + โปรไฟล์ ] ==================== --
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0, 150, 1, 0)
LeftPanel.Position = UDim2.new(0, 0, 0, 0)
LeftPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = MainFrame

local LeftCorner = Instance.new("UICorner")
LeftCorner.CornerRadius = UDim.new(0, 10)
LeftCorner.Parent = LeftPanel

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(0, 42, 0, 42)
AvatarImage.Position = UDim2.new(0, 10, 0, 10)
AvatarImage.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
AvatarImage.Parent = LeftPanel

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarImage

local DisplayName = Instance.new("TextLabel")
DisplayName.Size = UDim2.new(1, -62, 0, 18)
DisplayName.Position = UDim2.new(0, 58, 0, 12)
DisplayName.BackgroundTransparency = 1
DisplayName.Text = LocalPlayer.DisplayName
DisplayName.TextColor3 = Color3.fromRGB(255, 255, 255)
DisplayName.TextSize = 10
DisplayName.Font = Enum.Font.GothamBold
DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
DisplayName.TextXAlignment = Enum.TextXAlignment.Left
DisplayName.Parent = LeftPanel

local StatusTag = Instance.new("TextLabel")
StatusTag.Size = UDim2.new(1, -62, 0, 14)
StatusTag.Position = UDim2.new(0, 58, 0, 30)
StatusTag.BackgroundTransparency = 1
StatusTag.Text = "● ACTIVE"
StatusTag.TextColor3 = Color3.fromRGB(0, 255, 120)
StatusTag.TextSize = 8
StatusTag.Font = Enum.Font.GothamBold
StatusTag.TextXAlignment = Enum.TextXAlignment.Left
StatusTag.Parent = LeftPanel

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, -20, 0, 1)
Separator.Position = UDim2.new(0, 10, 0, 58)
Separator.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
Separator.BorderSizePixel = 0
Separator.Parent = LeftPanel

local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size = UDim2.new(1, -12, 1, -70)
TabScroll.Position = UDim2.new(0, 6, 0, 64)
TabScroll.BackgroundTransparency = 1
TabScroll.ScrollBarThickness = 0
TabScroll.Parent = LeftPanel

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabScroll

-- ==================== [ ด้านขวา: พื้นที่แสดงเนื้อหา ] ==================== --
local ContentPanel = Instance.new("Frame")
ContentPanel.Size = UDim2.new(1, -160, 1, 0)
ContentPanel.Position = UDim2.new(0, 155, 0, 0)
ContentPanel.BackgroundTransparency = 1
ContentPanel.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 30)
Title.Position = UDim2.new(0, 5, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "EXC HUB MM2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = ContentPanel

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 10)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = ContentPanel
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- ==================== [ ระบบสร้าง TABS ] ==================== --
local tabFrames = {}
local tabButtons = {}

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(160, 160, 165)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = TabScroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -50)
    scroll.Position = UDim2.new(0, 0, 0, 42)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 3
    scroll.Visible = false
    scroll.Parent = ContentPanel

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = scroll

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 10)
    end)

    tabFrames[name] = scroll
    tabButtons[name] = btn

    btn.MouseButton1Click:Connect(function()
        playSound()
        for tName, tFrame in pairs(tabFrames) do
            tFrame.Visible = (tName == name)
            tabButtons[tName].BackgroundColor3 = (tName == name) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(28, 28, 32)
            tabButtons[tName].TextColor3 = (tName == name) and Color3.fromRGB(15, 15, 18) or Color3.fromRGB(160, 160, 165)
        end
    end)

    return scroll
end

local Tab_MM2 = createTab("MM2 / มอง")
local Tab_Move = createTab("เคลื่อนที่")
local Tab_TP = createTab("วาร์ป")
local Tab_Combat = createTab("ต่อสู้")
local Tab_Protect = createTab("ป้องกัน")

tabFrames["MM2 / มอง"].Visible = true
tabButtons["MM2 / มอง"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
tabButtons["MM2 / มอง"].TextColor3 = Color3.fromRGB(15, 15, 18)

-- ==================== [ ระบบสร้าง UI Switch / Slider ] ==================== --
local function createSwitch(parent, text, defaultState, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
    frame.Parent = parent

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(0, 6)
    fCorner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 9
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local switchBg = Instance.new("Frame")
    switchBg.Size = UDim2.new(0, 40, 0, 20)
    switchBg.Position = UDim2.new(1, -48, 0.5, -10)
    switchBg.BackgroundColor3 = defaultState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 55)
    switchBg.Parent = frame

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = switchBg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = defaultState and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = switchBg

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = frame

    local state = defaultState or false
    clickBtn.MouseButton1Click:Connect(function()
        playSound()
        state = not state
        if state then
            switchBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            knob.Position = UDim2.new(1, -18, 0.5, -8)
        else
            switchBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            knob.Position = UDim2.new(0, 2, 0.5, -8)
        end
        callback(state)
    end)

    return frame
end

local function createSlider(parent, text, minVal, maxVal, defaultVal, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -5, 0, 42)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
    sliderFrame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = sliderFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 8, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(defaultVal)
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 9
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -16, 0, 6)
    barBg.Position = UDim2.new(0, 8, 0, 25)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    barBg.Parent = sliderFrame

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = barBg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local dragging = false
    local function updateSlider(input)
        local pos = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        local val = math.floor(minVal + (maxVal - minVal) * pos)
        label.Text = text .. ": " .. tostring(val)
        callback(val)
    end

    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input)
        end
    end)
    return sliderFrame
end

-- ==================== [ 1. TAB: MM2 ESP ] ==================== --
local espRolesEnabled = false
local espGunEnabled = false
local autoPickGunEnabled = false
local espBoxEnabled = false
local espLineEnabled = false
local isPickingUpGun = false

createSwitch(Tab_MM2, "มองผู้เล่นแบ่งสีตามบทบาท", false, function(v) espRolesEnabled = v end)
createSwitch(Tab_MM2, "มองกรอบตัวละคร (Box ESP)", false, function(v) espBoxEnabled = v end)
createSwitch(Tab_MM2, "มองเส้นชี้เป้าจากล่างจอ (Line ESP)", false, function(v) espLineEnabled = v end)
createSwitch(Tab_MM2, "มองปืนตก (สีเหลือง)", false, function(v) espGunEnabled = v end)
createSwitch(Tab_MM2, "เก็บปืนให้อัตโนมัติ (วาร์ปเก็บแล้วกลับ)", false, function(v) autoPickGunEnabled = v end)

local espDrawings = {}

local function removeDrawings(plr)
    if espDrawings[plr] then
        pcall(function()
            if espDrawings[plr].Box then espDrawings[plr].Box:Remove() end
            if espDrawings[plr].Line then espDrawings[plr].Line:Remove() end
        end)
        espDrawings[plr] = nil
    end
end

local function getDrawings(plr)
    if not hasDrawing then return nil end
    if not espDrawings[plr] then
        local success, result = pcall(function()
            local box = Drawing.new("Square")
            box.Visible = false
            box.Color = Color3.fromRGB(255, 50, 50)
            box.Thickness = 1.5
            box.Filled = false

            local line = Drawing.new("Line")
            line.Visible = false
            line.Color = Color3.fromRGB(0, 255, 150)
            line.Thickness = 1.5

            return {Box = box, Line = line}
        end)
        if success then
            espDrawings[plr] = result
        else
            return nil
        end
    end
    return espDrawings[plr]
end

Players.PlayerRemoving:Connect(removeDrawings)

local function teleportPickGunAndReturn(targetPart)
    if isPickingUpGun or not autoPickGunEnabled then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    isPickingUpGun = true
    task.spawn(function()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp and targetPart and targetPart.Parent then
            local oldCFrame = hrp.CFrame
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 1, 0)
            task.wait(0.15)
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = oldCFrame
            end
        end
        task.wait(0.5)
        isPickingUpGun = false
    end)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        local cam = workspace.CurrentCamera

        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local role = getRole(plr)
                local roleColor = (role == "Murderer" and Color3.fromRGB(255, 40, 40)) or 
                                  (role == "Sheriff" and Color3.fromRGB(40, 150, 255)) or 
                                  Color3.fromRGB(40, 255, 120)

                if plr.Character and plr.Character:FindFirstChild("Head") then
                    local char = plr.Character
                    local hl = char:FindFirstChild("EXC_Highlight") or Instance.new("Highlight")
                    hl.Name = "EXC_Highlight"
                    hl.Parent = char

                    local bb = char.Head:FindFirstChild("EXC_Billboard") or Instance.new("BillboardGui")
                    bb.Name = "EXC_Billboard"
                    bb.Size = UDim2.new(0, 100, 0, 30)
                    bb.StudsOffset = Vector3.new(0, 2.5, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = char.Head

                    local txt = bb:FindFirstChild("TextLabel") or Instance.new("TextLabel")
                    txt.Size = UDim2.new(1, 0, 1, 0)
                    txt.BackgroundTransparency = 1
                    txt.TextSize = 9
                    txt.Font = Enum.Font.GothamBold
                    txt.Parent = bb

                    if espRolesEnabled then
                        hl.Enabled = true
                        bb.Enabled = true
                        hl.FillColor = roleColor
                        txt.TextColor3 = roleColor
                        if role == "Murderer" then txt.Text = plr.DisplayName .. "\n[ ฆาตกร ]"
                        elseif role == "Sheriff" then txt.Text = plr.DisplayName .. "\n[ นายอำเภอ ]"
                        else txt.Text = plr.DisplayName .. "\n[ คนดี ]" end
                    else
                        hl.Enabled = false
                        bb.Enabled = false
                    end
                end

                if hasDrawing then
                    local drawings = getDrawings(plr)
                    if drawings and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = plr.Character.HumanoidRootPart
                        local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)

                        if onScreen and (espBoxEnabled or espLineEnabled) then
                            if espBoxEnabled then
                                local boxWidth = 2000 / screenPos.Z
                                local boxHeight = 3000 / screenPos.Z
                                drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
                                drawings.Box.Position = Vector2.new(screenPos.X - boxWidth / 2, screenPos.Y - boxHeight / 2)
                                drawings.Box.Color = roleColor
                                drawings.Box.Visible = true
                            else
                                drawings.Box.Visible = false
                            end

                            if espLineEnabled then
                                drawings.Line.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                                drawings.Line.To = Vector2.new(screenPos.X, screenPos.Y)
                                drawings.Line.Color = roleColor
                                drawings.Line.Visible = true
                            else
                                drawings.Line.Visible = false
                            end
                        else
                            drawings.Box.Visible = false
                            drawings.Line.Visible = false
                        end
                    elseif drawings then
                        drawings.Box.Visible = false
                        drawings.Line.Visible = false
                    end
                end
            end
        end

        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name == "GunDrop" or (obj:IsA("Tool") and obj.Name == "Gun" and obj.Parent == workspace) then
                local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if targetPart then
                    local gHl = targetPart:FindFirstChild("EXC_GunHL") or Instance.new("Highlight")
                    gHl.Name = "EXC_GunHL"
                    gHl.FillColor = Color3.fromRGB(255, 230, 0)
                    gHl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    gHl.Enabled = espGunEnabled
                    gHl.Parent = targetPart

                    if autoPickGunEnabled then
                        teleportPickGunAndReturn(targetPart)
                    end
                end
            end
        end
    end)
end)

-- ==================== [ 2. TAB: เคลื่อนที่ ] ==================== --
local walkSpeedVal = 16
local speedEnabled = false

createSwitch(Tab_Move, "เปิดใช้วิ่งเร็ว", false, function(v)
    speedEnabled = v
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

createSlider(Tab_Move, "ความเร็ววิ่ง", 16, 120, 16, function(v)
    walkSpeedVal = v
end)

RunService.RenderStepped:Connect(function()
    if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = walkSpeedVal
    end
end)

local flyEnabled = false
local flySpeed = 50

createSwitch(Tab_Move, "เปิดบินอิสระ (ไม่พุ่งขึ้นฟ้า)", false, function(v) flyEnabled = v end)
createSlider(Tab_Move, "ความเร็วบิน", 20, 200, 50, function(v) flySpeed = v end)

local bodyVel, bodyGyro
RunService.RenderStepped:Connect(function()
    if flyEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local cam = workspace.CurrentCamera

        if not bodyVel or bodyVel.Parent ~= root then
            bodyVel = Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            bodyVel.Parent = root
        end

        if not bodyGyro or bodyGyro.Parent ~= root then
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bodyGyro.P = 9000
            bodyGyro.Parent = root
        end

        bodyGyro.CFrame = cam.CFrame

        local look = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local flatLook = Vector3.new(look.X, 0, look.Z).Unit
        local flatRight = Vector3.new(right.X, 0, right.Z).Unit

        local moveDirection = Vector3.new(0, 0, 0)
        local uis = UserInputService
        if uis:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + flatLook end
        if uis:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - flatLook end
        if uis:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + flatRight end
        if uis:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - flatRight end
        
        if uis:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end

        if moveDirection.Magnitude > 0 then
            bodyVel.Velocity = moveDirection.Unit * flySpeed
        else
            bodyVel.Velocity = Vector3.new(0, 0, 0)
        end
    else
        if bodyVel then bodyVel:Destroy() bodyVel = nil end
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    end
end)

local noclipEnabled = false
createSwitch(Tab_Move, "เดินทะลุสิ่งกีดขวาง", false, function(v) noclipEnabled = v end)
RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- ==================== [ 3. TAB: วาร์ป ] ==================== --
local function teleportToLobby()
    pcall(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local lobby = workspace:FindFirstChild("Lobby")
        if lobby then
            local spawnPart = nil
            for _, v in pairs(lobby:GetDescendants()) do
                if v:IsA("BasePart") and (v.Name:lower():find("spawn") or v.Name == "Pad" or v.Name == "Floor") then
                    spawnPart = v
                    break
                end
            end
            if not spawnPart then spawnPart = lobby:FindFirstChildWhichIsA("BasePart", true) end
            if spawnPart then
                char.HumanoidRootPart.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
                return
            end
        end
        
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("SpawnLocation") or (v:IsA("BasePart") and v.Name == "LobbySpawn") then
                char.HumanoidRootPart.CFrame = v.CFrame + Vector3.new(0, 3, 0)
                return
            end
        end
    end)
end

local function teleportToMap()
    pcall(function()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart

        local mapFolder = workspace:FindFirstChild("Normal") or workspace:FindFirstChild("Map")
        if not mapFolder then
            for _, obj in pairs(workspace:GetChildren()) do
                if obj:FindFirstChild("CoinContainer") or obj:FindFirstChild("Spawns") then
                    mapFolder = obj
                    break
                end
            end
        end

        if mapFolder then
            local spawns = mapFolder:FindFirstChild("Spawns") or mapFolder:FindFirstChild("Spawn")
            if spawns then
                local spawnPart = spawns:FindFirstChildWhichIsA("BasePart", true)
                if spawnPart then
                    hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
                    return
                end
            end
            
            local coinContainer = mapFolder:FindFirstChild("CoinContainer")
            if coinContainer then
                local coinPart = coinContainer:FindFirstChildWhichIsA("BasePart", true)
                if coinPart then
                    hrp.CFrame = coinPart.CFrame + Vector3.new(0, 3, 0)
                    return
                end
            end

            local anyPart = mapFolder:FindFirstChildWhichIsA("BasePart", true)
            if anyPart then
                hrp.CFrame = anyPart.CFrame + Vector3.new(0, 3, 0)
                return
            end
        end

        local lobby = workspace:FindFirstChild("Lobby")
        local lobbyPos = nil
        if lobby then
            local lPart = lobby:FindFirstChildWhichIsA("BasePart", true)
            if lPart then lobbyPos = lPart.Position end
        end

        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local targetHrp = p.Character.HumanoidRootPart
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local isTargetInLobby = false
                
                if lobbyPos then
                    if (targetHrp.Position - lobbyPos).Magnitude < 140 then
                        isTargetInLobby = true
                    end
                else
                    for _, spawnLoc in pairs(workspace:GetDescendants()) do
                        if spawnLoc:IsA("SpawnLocation") and (targetHrp.Position - spawnLoc.Position).Magnitude < 80 then
                            isTargetInLobby = true
                            break
                        end
                    end
                end

                if not isTargetInLobby and hum and hum.Health > 0 then
                    hrp.CFrame = targetHrp.CFrame + Vector3.new(0, 2, 0)
                    return
                end
            end
        end
    end)
end

local lBtn = Instance.new("TextButton")
lBtn.Size = UDim2.new(1, -5, 0, 32)
lBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
lBtn.Text = "🏰 วาร์ปไปหน้าล็อบบี้"
lBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lBtn.TextSize = 10
lBtn.Font = Enum.Font.GothamBold
lBtn.Parent = Tab_TP
local lC = Instance.new("UICorner") lC.CornerRadius = UDim.new(0, 6) lC.Parent = lBtn
lBtn.MouseButton1Click:Connect(function() playSound() teleportToLobby() end)

local mBtn = Instance.new("TextButton")
mBtn.Size = UDim2.new(1, -5, 0, 32)
mBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
mBtn.Text = "🗺️ วาร์ปเข้าในแมพแข่งขัน"
mBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
mBtn.TextSize = 10
mBtn.Font = Enum.Font.GothamBold
mBtn.Parent = Tab_TP
local mC = Instance.new("UICorner") mC.CornerRadius = UDim.new(0, 6) mC.Parent = mBtn
mBtn.MouseButton1Click:Connect(function() playSound() teleportToMap() end)

local selectedTargetPlayer = nil
local dropdownContainer = Instance.new("Frame")
dropdownContainer.Size = UDim2.new(1, -5, 0, 32)
dropdownContainer.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
dropdownContainer.Parent = Tab_TP
local dcC = Instance.new("UICorner") dcC.CornerRadius = UDim.new(0, 6) dcC.Parent = dropdownContainer

local dropdownLabel = Instance.new("TextLabel")
dropdownLabel.Size = UDim2.new(1, -10, 1, 0)
dropdownLabel.Position = UDim2.new(0, 8, 0, 0)
dropdownLabel.BackgroundTransparency = 1
dropdownLabel.Text = "👤 กดเพื่อเลือกชื่อผู้เล่น"
dropdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
dropdownLabel.TextSize = 9
dropdownLabel.Font = Enum.Font.GothamBold
dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
dropdownLabel.Parent = dropdownContainer

local playerListScroll = Instance.new("ScrollingFrame")
playerListScroll.Size = UDim2.new(1, -5, 0, 90)
playerListScroll.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
playerListScroll.BorderSizePixel = 0
playerListScroll.Visible = false
playerListScroll.ScrollBarThickness = 3
playerListScroll.Parent = Tab_TP

local plListLayout = Instance.new("UIListLayout")
plListLayout.Padding = UDim.new(0, 2)
plListLayout.Parent = playerListScroll

dropdownContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        playSound()
        playerListScroll.Visible = not playerListScroll.Visible
        for _, child in pairs(playerListScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local pBtn = Instance.new("TextButton")
                pBtn.Size = UDim2.new(1, 0, 0, 22)
                pBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
                pBtn.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                pBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
                pBtn.TextSize = 9
                pBtn.Font = Enum.Font.Gotham
                pBtn.Parent = playerListScroll
                pBtn.MouseButton1Click:Connect(function()
                    playSound()
                    selectedTargetPlayer = p
                    dropdownLabel.Text = "👤 เลือกแล้ว: " .. p.DisplayName
                    playerListScroll.Visible = false
                end)
            end
        end
    end
end)

local tpSelectedBtn = Instance.new("TextButton")
tpSelectedBtn.Size = UDim2.new(1, -5, 0, 32)
tpSelectedBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 180)
tpSelectedBtn.Text = "🚀 วาร์ปไปหาคนที่เลือก"
tpSelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpSelectedBtn.TextSize = 10
tpSelectedBtn.Font = Enum.Font.GothamBold
tpSelectedBtn.Parent = Tab_TP
local tpsC = Instance.new("UICorner") tpsC.CornerRadius = UDim.new(0, 6) tpsC.Parent = tpSelectedBtn

tpSelectedBtn.MouseButton1Click:Connect(function()
    playSound()
    if selectedTargetPlayer and selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = selectedTargetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    end
end)

-- ==================== [ 4. TAB: ต่อสู้ ] ==================== --
local lockSmoothness = 0.25

createSwitch(Tab_Combat, "เปิดใช้สวิตช์ล็อกฆาตกร (แสดงปุ่มบนหน้าจอ)", false, function(v)
    isAimlockSystemEnabled = v
    LockScreenBtn.Visible = v
    if not v then
        isAimlockActive = false
        LockScreenBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        LockScreenBtn.Text = "🎯 LOCK: OFF"
        LockScreenBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end)

createSlider(Tab_Combat, "ความนุ่มนวลในการล็อก", 10, 100, 25, function(v)
    lockSmoothness = v / 100
end)

local function isVisibleAndOnScreen(targetPart)
    if not targetPart or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local cam = workspace.CurrentCamera
    local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)

    if not onScreen then return false end

    local origin = cam.CFrame.Position
    local direction = targetPart.Position - origin

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude -- [FIXED]: ใส่ Enum. นำหน้าป้องกัน Error
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
    rayParams.IgnoreWater = true

    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        if isAimlockSystemEnabled and isAimlockActive then
            local murd = getMurderer()
            if murd and murd ~= LocalPlayer and murd.Character then
                local char = murd.Character
                local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                
                if targetPart and isVisibleAndOnScreen(targetPart) then
                    local cam = workspace.CurrentCamera
                    local targetCFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
                    cam.CFrame = cam.CFrame:Lerp(targetCFrame, lockSmoothness)
                end
            end
        end
    end)
end)

local pullAllBtn = Instance.new("TextButton")
pullAllBtn.Size = UDim2.new(1, -5, 0, 32)
pullAllBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
pullAllBtn.Text = "💀 ดึงทุกคนมาตรงหน้า (Bring All)"
pullAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pullAllBtn.TextSize = 10
pullAllBtn.Font = Enum.Font.GothamBold
pullAllBtn.Parent = Tab_Combat
local paC = Instance.new("UICorner") paC.CornerRadius = UDim.new(0, 6) paC.Parent = pullAllBtn

pullAllBtn.MouseButton1Click:Connect(function()
    playSound()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local targetCFrame = char.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    p.Character.HumanoidRootPart.CFrame = targetCFrame
                end)
            end
        end
    end
end)

local pullMurdBtn = Instance.new("TextButton")
pullMurdBtn.Size = UDim2.new(1, -5, 0, 32)
pullMurdBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
pullMurdBtn.Text = "🧲 ดึงตัวฆาตกรมาตรงหน้า"
pullMurdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pullMurdBtn.TextSize = 10
pullMurdBtn.Font = Enum.Font.GothamBold
pullMurdBtn.Parent = Tab_Combat
local pmC = Instance.new("UICorner") pmC.CornerRadius = UDim.new(0, 6) pmC.Parent = pullMurdBtn

pullMurdBtn.MouseButton1Click:Connect(function()
    playSound()
    local murd = getMurderer()
    if murd and murd.Character and murd.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            murd.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
        end
    end
end)

local pullSelectedBtn = Instance.new("TextButton")
pullSelectedBtn.Size = UDim2.new(1, -5, 0, 32)
pullSelectedBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 180)
pullSelectedBtn.Text = "🧲 ดึงคนที่เลือก (ในหมวดวาร์ป) มาหา"
pullSelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
pullSelectedBtn.TextSize = 10
pullSelectedBtn.Font = Enum.Font.GothamBold
pullSelectedBtn.Parent = Tab_Combat
local psC = Instance.new("UICorner") psC.CornerRadius = UDim.new(0, 6) psC.Parent = pullSelectedBtn

pullSelectedBtn.MouseButton1Click:Connect(function()
    playSound()
    if selectedTargetPlayer and selectedTargetPlayer.Character and selectedTargetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            selectedTargetPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
        end
    end
end)

-- ==================== [ 5. TAB: ป้องกัน ] ==================== --
local antiFlingEnabled = false
createSwitch(Tab_Protect, "กันโดนชนดีด (Anti-Fling)", false, function(v) antiFlingEnabled = v end)

RunService.Stepped:Connect(function()
    if antiFlingEnabled and LocalPlayer.Character then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                for _, part in pairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end
end)

-- ==================== [ แสดง FPS ] ==================== --
local StatsContainer = Instance.new("Frame")
StatsContainer.Size = UDim2.new(1, -10, 0, 22)
StatsContainer.Position = UDim2.new(0, 0, 1, -24)
StatsContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 25)
StatsContainer.Parent = ContentPanel

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 4)
StatsCorner.Parent = StatsContainer

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(1, 0, 1, 0)
FPSLabel.Position = UDim2.new(0, 8, 0, 0)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "⚡ FPS: --"
FPSLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FPSLabel.TextSize = 9
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextXAlignment = Enum.TextXAlignment.Left
FPSLabel.Parent = StatsContainer

local lastUpdate, frameCount = tick(), 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastUpdate >= 0.5 then
        FPSLabel.Text = "⚡ FPS: " .. tostring(math.floor(frameCount / (now - lastUpdate)))
        frameCount, lastUpdate = 0, now
    end
end)
-- Script by luxonixov | t.me/luxonixov
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local states = {fog=false, light=false, esp=false, espMode="all", potato=false, speed=false, espItems=false}
local espData = {}
local itemEspData = {}
local origFog = {Start=Lighting.FogStart, End=Lighting.FogEnd}
local origAmbient = Lighting.Ambient
local origBrightness = Lighting.Brightness
local origQuality = settings().Rendering.QualityLevel
local currentSpeed = 24
local slidDragging = false

local function isMurderer(plr)
    local char = plr.Character
    if not char then return false end
    return char:GetAttribute("Team") == "Killer"
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 80, 0, 25)
ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
ToggleBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
ToggleBtn.Text = "Menu"
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 5)

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 220, 0, 390)
Frame.Position = UDim2.new(0, 10, 0, 44)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
Frame.BorderSizePixel = 0
Frame.Visible = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", Frame)
stroke.Color = Color3.fromRGB(80, 80, 160)
stroke.Thickness = 1.2

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Frame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -10, 1, 0)
TitleLbl.Position = UDim2.new(0, 10, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "Script Menu"
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextSize = 12
TitleLbl.TextColor3 = Color3.fromRGB(180, 180, 255)
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = TitleBar

local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = Frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging and not slidDragging then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
ToggleBtn.MouseButton1Click:Connect(function() Frame.Visible = not Frame.Visible end)

local function makeToggle(text, yOffset)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 28)
    btn.Position = UDim2.new(0, 8, 0, yOffset)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    btn.TextColor3 = Color3.fromRGB(170, 170, 220)
    btn.Text = "o  " .. text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(60, 60, 100); s.Thickness = 1
    return btn
end

local function setActive(btn, on)
    btn.BackgroundColor3 = on and Color3.fromRGB(50,50,100) or Color3.fromRGB(35,35,60)
    btn.TextColor3 = on and Color3.fromRGB(140,200,255) or Color3.fromRGB(170,170,220)
    btn.Text = (on and "*  " or "o  ") .. btn.Text:sub(4)
end

local function makeSmallBtn(text, x, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 62, 0, 22)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    btn.TextColor3 = Color3.fromRGB(170, 170, 220)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.fromRGB(60, 60, 100); s.Thickness = 1
    return btn
end

local btn1 = makeToggle("Убрать туман",         34)
local btn2 = makeToggle("Полное освещение",      68)
local btn3 = makeToggle("ESP",                  102)

local modeLbl = Instance.new("TextLabel")
modeLbl.Size = UDim2.new(1, -16, 0, 14)
modeLbl.Position = UDim2.new(0, 8, 0, 136)
modeLbl.BackgroundTransparency = 1
modeLbl.Text = "Режим ESP:"
modeLbl.Font = Enum.Font.Gotham
modeLbl.TextSize = 10
modeLbl.TextColor3 = Color3.fromRGB(120,120,180)
modeLbl.TextXAlignment = Enum.TextXAlignment.Left
modeLbl.Parent = Frame

local btnAll  = makeSmallBtn("Все",     8,   152)
local btnSurv = makeSmallBtn("Выжив.", 78,   152)
local btnKill = makeSmallBtn("Убийца", 148,  152)

local btn4 = makeToggle("Картофельная графика", 182)
local btn5 = makeToggle("Скорость",             216)
local btn6 = makeToggle("ESP Items",            250)

local sLabel = Instance.new("TextLabel")
sLabel.Size = UDim2.new(1, -16, 0, 14)
sLabel.Position = UDim2.new(0, 8, 0, 284)
sLabel.BackgroundTransparency = 1
sLabel.Text = "Скорость: " .. currentSpeed
sLabel.Font = Enum.Font.Gotham
sLabel.TextSize = 10
sLabel.TextColor3 = Color3.fromRGB(120,120,180)
sLabel.TextXAlignment = Enum.TextXAlignment.Left
sLabel.Parent = Frame

local sBg = Instance.new("Frame")
sBg.Size = UDim2.new(1, -16, 0, 10)
sBg.Position = UDim2.new(0, 8, 0, 302)
sBg.BackgroundColor3 = Color3.fromRGB(35,35,60)
sBg.BorderSizePixel = 0
sBg.Parent = Frame
Instance.new("UICorner", sBg).CornerRadius = UDim.new(0, 5)

local sFill = Instance.new("Frame")
local initX = (currentSpeed - 1) / 99
sFill.Size = UDim2.new(initX, 0, 1, 0)
sFill.BackgroundColor3 = Color3.fromRGB(80,120,220)
sFill.BorderSizePixel = 0
sFill.Parent = sBg
Instance.new("UICorner", sFill).CornerRadius = UDim.new(0, 5)

local sKnob = Instance.new("Frame")
sKnob.Size = UDim2.new(0, 16, 0, 16)
sKnob.Position = UDim2.new(initX, -8, 0.5, -8)
sKnob.BackgroundColor3 = Color3.fromRGB(140,180,255)
sKnob.BorderSizePixel = 0
sKnob.Parent = sBg
Instance.new("UICorner", sKnob).CornerRadius = UDim.new(1, 0)

local function updateSlider(input)
    local x = math.clamp((input.Position.X - sBg.AbsolutePosition.X) / sBg.AbsoluteSize.X, 0, 1)
    sFill.Size = UDim2.new(x, 0, 1, 0)
    sKnob.Position = UDim2.new(x, -8, 0.5, -8)
    currentSpeed = math.floor(1 + x * 99)
    sLabel.Text = "Скорость: " .. currentSpeed
end

sBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        slidDragging = true; updateSlider(i)
    end
end)
sKnob.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        slidDragging = true
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if slidDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(i)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        slidDragging = false
    end
end)

local function updateModeButtons()
    local function hi(btn, mode)
        local on = states.espMode == mode
        btn.BackgroundColor3 = on and Color3.fromRGB(50,50,100) or Color3.fromRGB(35,35,60)
        btn.TextColor3 = on and Color3.fromRGB(140,200,255) or Color3.fromRGB(170,170,220)
    end
    hi(btnAll,"all"); hi(btnSurv,"survivors"); hi(btnKill,"murderer")
end
updateModeButtons()

local function applyFog()
    if states.fog then Lighting.FogStart=1e6; Lighting.FogEnd=1e6
    else Lighting.FogStart=origFog.Start; Lighting.FogEnd=origFog.End end
end
btn1.MouseButton1Click:Connect(function() states.fog=not states.fog; setActive(btn1,states.fog); applyFog() end)

local function applyLight()
    if states.light then
        Lighting.Ambient=Color3.fromRGB(255,255,255); Lighting.Brightness=10
        for _,v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then v.Enabled=false end
        end
    else
        Lighting.Ambient=origAmbient; Lighting.Brightness=origBrightness
        for _,v in pairs(Lighting:GetChildren()) do
            if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then v.Enabled=true end
        end
    end
end
btn2.MouseButton1Click:Connect(function() states.light=not states.light; setActive(btn2,states.light); applyLight() end)

local function removeESPFromPlayer(plr)
    if espData[plr] then
        if espData[plr].hl and espData[plr].hl.Parent then espData[plr].hl:Destroy() end
        if espData[plr].bb and espData[plr].bb.Parent then espData[plr].bb:Destroy() end
        espData[plr] = nil
    end
end

local function shouldShow(plr)
    if states.espMode == "all" then return true end
    local m = isMurderer(plr)
    if states.espMode == "murderer" then return m end
    if states.espMode == "survivors" then return not m end
    return true
end

local function applyESPToPlayer(plr)
    if plr == LocalPlayer then return end
    removeESPFromPlayer(plr)
    if not states.esp then return end
    if not shouldShow(plr) then return end
    local char = plr.Character
    if not char then return end
    local murder = isMurderer(plr)
    local hl = Instance.new("Highlight")
    hl.FillColor = murder and Color3.fromRGB(255,50,50) or Color3.fromRGB(50,120,255)
    hl.OutlineColor = murder and Color3.fromRGB(255,180,180) or Color3.fromRGB(180,210,255)
    hl.FillTransparency = 0.35; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = char; hl.Parent = char

    -- ищем любую BasePart в голове если Head не найден
    local head = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
    local bb, lbl
    if head then
        bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0,100,0,20); bb.StudsOffset = Vector3.new(0,3.5,0)
        bb.AlwaysOnTop = true; bb.Parent = head
        lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        lbl.TextColor3 = murder and Color3.fromRGB(255,100,100) or Color3.fromRGB(100,180,255)
        lbl.TextStrokeTransparency = 0.3; lbl.Text = "..."
    end
    espData[plr] = {hl=hl, bb=bb, lbl=lbl}
end

local function removeAllESP()
    for plr in pairs(espData) do removeESPFromPlayer(plr) end; espData = {}
end
local function applyESPToAll()
    for _,plr in pairs(Players:GetPlayers()) do applyESPToPlayer(plr) end
end

btn3.MouseButton1Click:Connect(function()
    states.esp = not states.esp; setActive(btn3, states.esp)
    if states.esp then applyESPToAll() else removeAllESP() end
end)
btnAll.MouseButton1Click:Connect(function()  states.espMode="all";       updateModeButtons(); if states.esp then removeAllESP(); applyESPToAll() end end)
btnSurv.MouseButton1Click:Connect(function() states.espMode="survivors"; updateModeButtons(); if states.esp then removeAllESP(); applyESPToAll() end end)
btnKill.MouseButton1Click:Connect(function() states.espMode="murderer";  updateModeButtons(); if states.esp then removeAllESP(); applyESPToAll() end end)

local function applyPotato()
    if states.potato then settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    else settings().Rendering.QualityLevel = origQuality end
end
btn4.MouseButton1Click:Connect(function() states.potato = not states.potato; setActive(btn4, states.potato); applyPotato() end)

btn5.MouseButton1Click:Connect(function() states.speed = not states.speed; setActive(btn5, states.speed) end)

RunService.Heartbeat:Connect(function()
    if not states.speed then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if root and hum and hum.MoveDirection.Magnitude > 0 then
        root.CFrame = root.CFrame + (hum.MoveDirection * (currentSpeed / 45))
    end
end)

local function removeAllItemESP()
    for obj, data in pairs(itemEspData) do
        pcall(function()
            if data.hl and data.hl.Parent then data.hl:Destroy() end
        end)
    end
    itemEspData = {}
end

local function applyHLToObject(obj, fillColor, outlineColor)
    if itemEspData[obj] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = fillColor
    hl.OutlineColor = outlineColor
    hl.FillTransparency = 0.3
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = obj
    hl.Parent = obj
    itemEspData[obj] = {hl=hl}
end

local function applyAllItemESP()
    local mapsFolder = workspace:FindFirstChild("MAPS")
    if not mapsFolder then return end
    local gameMap = mapsFolder:FindFirstChild("GAME MAP")
    if not gameMap then return end
    local generators = gameMap:FindFirstChild("Generators")
    if generators then
        for _, gen in pairs(generators:GetChildren()) do
            applyHLToObject(gen, Color3.fromRGB(255,200,0), Color3.fromRGB(255,240,100))
        end
    end
    local batteries = gameMap:FindFirstChild("Batteries")
    if batteries then
        for _, bat in pairs(batteries:GetChildren()) do
            applyHLToObject(bat, Color3.fromRGB(0,220,100), Color3.fromRGB(100,255,160))
        end
    end
end

btn6.MouseButton1Click:Connect(function()
    states.espItems = not states.espItems
    setActive(btn6, states.espItems)
    if states.espItems then applyAllItemESP() else removeAllItemESP() end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    applyFog(); applyLight(); applyPotato()
    if states.esp then task.wait(0.5); applyESPToAll() end
    if states.espItems then task.wait(0.5); removeAllItemESP(); applyAllItemESP() end
end)

local function hookPlayer(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(1)
        if states.esp then applyESPToPlayer(plr) end
    end)
end
for _,plr in pairs(Players:GetPlayers()) do if plr ~= LocalPlayer then hookPlayer(plr) end end
Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(plr) removeESPFromPlayer(plr) end)

local tickN = 0
RunService.Heartbeat:Connect(function()
    if not states.esp then return end
    tickN = tickN + 1
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    for plr, data in pairs(espData) do
        local c = plr.Character
        if not c then continue end
        local anyPart = c:FindFirstChild("Head") or c:FindFirstChildWhichIsA("BasePart")
        if anyPart and myRoot then
            local dist = (anyPart.Position - myRoot.Position).Magnitude
            local murder = isMurderer(plr)
            if tickN % 45 == 0 then
                if data.hl then
                    data.hl.FillColor    = murder and Color3.fromRGB(255,50,50)   or Color3.fromRGB(50,120,255)
                    data.hl.OutlineColor = murder and Color3.fromRGB(255,180,180) or Color3.fromRGB(180,210,255)
                end
                if data.lbl then
                    data.lbl.TextColor3 = murder and Color3.fromRGB(255,100,100) or Color3.fromRGB(100,180,255)
                end
            end
            if data.lbl then
                data.lbl.Text = (murder and "[!] " or "") .. math.floor(dist) .. " std"
            end
        end
    end
end)

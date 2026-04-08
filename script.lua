-- script by luxonixov | t.me/luxonixov
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
TitleBar.Size = UDim2.new(1, 0, 0, 24)
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
TitleLbl.TextSize = 11
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

local curY = 28
local W = 200

local function makeToggle(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, W-16, 0, 24)
    btn.Position = UDim2.new(0, 8, 0, curY)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    btn.TextColor3 = Color3.fromRGB(170, 170, 220)
    btn.Text = "o  " .. text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke", btn); s.Color = Color3.fromRGB(60,60,100); s.Thickness = 1
    curY = curY + 26
    return btn
end

local function setActive(btn, on)
    btn.BackgroundColor3 = on and Color3.fromRGB(50,50,100) or Color3.fromRGB(35,35,60)
    btn.TextColor3 = on and Color3.fromRGB(140,200,255) or Color3.fromRGB(170,170,220)
    btn.Text = (on and "*  " or "o  ") .. btn.Text:sub(4)
end

local function makeSmallBtn(text, x, w)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, 20)
    btn.Position = UDim2.new(0, x, 0, curY)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    btn.TextColor3 = Color3.fromRGB(170, 170, 220)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    local s = Instance.new("UIStroke", btn); s.Color = Color3.fromRGB(60,60,100); s.Thickness = 1
    return btn
end

local function makeSliderRow(labelText, initVal, minVal, maxVal, decimals, onChange)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, W-16, 0, 12)
    lbl.Position = UDim2.new(0, 8, 0, curY)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 9
    lbl.TextColor3 = Color3.fromRGB(120,120,180)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = Frame
    curY = curY + 13

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, W-16, 0, 8)
    bg.Position = UDim2.new(0, 8, 0, curY)
    bg.BackgroundColor3 = Color3.fromRGB(35,35,60)
    bg.BorderSizePixel = 0
    bg.Parent = Frame
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,4)

    local fill = Instance.new("Frame")
    local initX = (initVal - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(initX, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80,120,220)
    fill.BorderSizePixel = 0
    fill.Parent = bg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(initX, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(140,180,255)
    knob.BorderSizePixel = 0
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)

    curY = curY + 16

    local function fmt(v)
        if decimals == 0 then return tostring(math.floor(v))
        else return string.format("%." .. decimals .. "f", v) end
    end

    lbl.Text = labelText .. fmt(initVal)

    local function updateVal(input)
        local x = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(x, 0, 1, 0)
        knob.Position = UDim2.new(x, -7, 0.5, -7)
        local raw = minVal + x * (maxVal - minVal)
        local val
        if decimals == 0 then val = math.floor(raw + 0.5)
        else val = math.floor(raw * 10 + 0.5) / 10 end
        lbl.Text = labelText .. fmt(val)
        onChange(val)
    end

    local active = false
    bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            active = true; slidDragging = true; updateVal(i)
        end
    end)
    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            active = true; slidDragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if active and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            updateVal(i)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            active = false; slidDragging = false
        end
    end)
end

local function makeSep()
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(0, W-16, 0, 1)
    sep.Position = UDim2.new(0, 8, 0, curY)
    sep.BackgroundColor3 = Color3.fromRGB(60,60,100)
    sep.BorderSizePixel = 0
    sep.Parent = Frame
    curY = curY + 5
end

-- кнопки основные
local btn1 = makeToggle("Убрать туман")
local btn2 = makeToggle("Полное освещение")
local btn3 = makeToggle("ESP")

local btnAll  = makeSmallBtn("Все",    8,  56)
local btnSurv = makeSmallBtn("Выжив.",68,  56)
local btnKill = makeSmallBtn("Убийца",128, 56)
curY = curY + 24

local btn4 = makeToggle("Картофельная графика")
local btn5 = makeToggle("Скорость")

makeSliderRow("Скорость: ", currentSpeed, 1, 100, 0, function(v) currentSpeed = v end)

makeSep()

local btn7 = makeToggle("Починить генератор")

makeSep()

local btn6 = makeToggle("ESP Items")

curY = curY + 4
Frame.Size = UDim2.new(0, W, 0, curY)

-- ESP режим кнопки
local function updateModeButtons()
    local function hi(b, mode)
        local on = states.espMode == mode
        b.BackgroundColor3 = on and Color3.fromRGB(50,50,100) or Color3.fromRGB(35,35,60)
        b.TextColor3 = on and Color3.fromRGB(140,200,255) or Color3.fromRGB(170,170,220)
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

local function doRepair()
    pcall(function()
        local args = {
            [1] = {
                ["Wires"] = true,
                ["Switches"] = true,
                ["Lever"] = true
            }
        }
        LocalPlayer.PlayerGui.Gen.GeneratorMain.Event:FireServer(unpack(args))
    end)
end

btn7.MouseButton1Click:Connect(function()
    doRepair()
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

-- Virtual Cursor Menu for Delta Mobile v3
-- WASD pad + collapse + lock position + fixed cursor offset + fixed drag

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Удаляем старый gui если есть
local old = playerGui:FindFirstChild("VirtualCursorGui")
if old then old:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VirtualCursorGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

------------------------------------------------------------------------
-- КУРСОР
------------------------------------------------------------------------
local cursorSize = 22
local cursor = Instance.new("Frame")
cursor.Name = "Cursor"
cursor.Size = UDim2.new(0, cursorSize, 0, cursorSize)
cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
cursor.BorderSizePixel = 0
cursor.ZIndex = 200
cursor.Parent = screenGui
Instance.new("UICorner", cursor).CornerRadius = UDim.new(1, 0)

local cursorStroke = Instance.new("UIStroke", cursor)
cursorStroke.Color = Color3.fromRGB(0, 0, 0)
cursorStroke.Thickness = 1.5

local cursorDot = Instance.new("Frame")
cursorDot.Size = UDim2.new(0, 7, 0, 7)
cursorDot.Position = UDim2.new(0.5, -3, 0.5, -3)
cursorDot.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
cursorDot.BorderSizePixel = 0
cursorDot.ZIndex = 201
cursorDot.Parent = cursor
Instance.new("UICorner", cursorDot).CornerRadius = UDim.new(1, 0)

------------------------------------------------------------------------
-- СОСТОЯНИЕ КУРСОРА
------------------------------------------------------------------------
local cursorPos   = Vector2.new(400, 300)
local targetPos   = Vector2.new(400, 300)
local SMOOTH      = 0.3
local cursorLocked = false

-- Глобальный трекинг касания (для движения курсора)
local trackTouch     = nil   -- input object
local touchStartPos  = Vector2.new()
local touchStartCur  = Vector2.new()

------------------------------------------------------------------------
-- HELPER: точка внутри фрейма?
------------------------------------------------------------------------
local function insideFrame(frame, pos)
    local ap = frame.AbsolutePosition
    local as = frame.AbsoluteSize
    return pos.X >= ap.X and pos.X <= ap.X + as.X
       and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

------------------------------------------------------------------------
-- ПЛАШКА
------------------------------------------------------------------------
local PANEL_W = 230
local PANEL_H_FULL = 195
local PANEL_H_MINI = 30

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H_FULL)
panel.Position = UDim2.new(0, 20, 0.5, -97)
panel.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
panel.BorderSizePixel = 0
panel.Active = true
panel.ZIndex = 50
panel.ClipsDescendants = true
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(60, 60, 100)
panelStroke.Thickness = 1.5

------------------------------------------------------------------------
-- ЗАГОЛОВОК
------------------------------------------------------------------------
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 55
titleBar.Parent = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

-- Фикс нижних углов заголовка (перекрываем скруглением)
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 14)
titleFix.Position = UDim2.new(0, 0, 1, -14)
titleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 54
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⠿  Virtual Cursor"
titleLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 56
titleLabel.Parent = titleBar

-- Кнопка свернуть
local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 26, 0, 22)
collapseBtn.Position = UDim2.new(1, -54, 0, 4)
collapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
collapseBtn.BorderSizePixel = 0
collapseBtn.Text = "▼"
collapseBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
collapseBtn.TextSize = 11
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.ZIndex = 57
collapseBtn.Parent = titleBar
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 6)

-- Кнопка блокировки позиции плашки
local posLockBtn = Instance.new("TextButton")
posLockBtn.Size = UDim2.new(0, 26, 0, 22)
posLockBtn.Position = UDim2.new(1, -26, 0, 4)
posLockBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
posLockBtn.BorderSizePixel = 0
posLockBtn.Text = "🔓"
posLockBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
posLockBtn.TextSize = 11
posLockBtn.Font = Enum.Font.GothamBold
posLockBtn.ZIndex = 57
posLockBtn.Parent = titleBar
Instance.new("UICorner", posLockBtn).CornerRadius = UDim.new(0, 6)

------------------------------------------------------------------------
-- ТЕЛО ПЛАШКИ (контейнер для всех кнопок)
------------------------------------------------------------------------
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -30)
body.Position = UDim2.new(0, 0, 0, 30)
body.BackgroundTransparency = 1
body.ZIndex = 51
body.Parent = panel

------------------------------------------------------------------------
-- КНОПКА БЛОК ДВИЖЕНИЯ КУРСОРА
------------------------------------------------------------------------
local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(0, 100, 0, 38)
lockBtn.Position = UDim2.new(0, 8, 0, 8)
lockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
lockBtn.BorderSizePixel = 0
lockBtn.Text = "🟢 MOVE ON"
lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBtn.TextSize = 12
lockBtn.Font = Enum.Font.GothamBold
lockBtn.ZIndex = 52
lockBtn.Parent = body
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 8)

------------------------------------------------------------------------
-- LMB / RMB
------------------------------------------------------------------------
local lmbBtn = Instance.new("TextButton")
lmbBtn.Size = UDim2.new(0, 52, 0, 38)
lmbBtn.Position = UDim2.new(0, 116, 0, 8)
lmbBtn.BackgroundColor3 = Color3.fromRGB(45, 95, 200)
lmbBtn.BorderSizePixel = 0
lmbBtn.Text = "LMB"
lmbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lmbBtn.TextSize = 14
lmbBtn.Font = Enum.Font.GothamBold
lmbBtn.ZIndex = 52
lmbBtn.Parent = body
Instance.new("UICorner", lmbBtn).CornerRadius = UDim.new(0, 8)

local rmbBtn = Instance.new("TextButton")
rmbBtn.Size = UDim2.new(0, 52, 0, 38)
rmbBtn.Position = UDim2.new(0, 172, 0, 8)
rmbBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
rmbBtn.BorderSizePixel = 0
rmbBtn.Text = "RMB"
rmbBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rmbBtn.TextSize = 14
rmbBtn.Font = Enum.Font.GothamBold
rmbBtn.ZIndex = 52
rmbBtn.Parent = body
Instance.new("UICorner", rmbBtn).CornerRadius = UDim.new(0, 8)

------------------------------------------------------------------------
-- WASD PAD
------------------------------------------------------------------------
local padSize  = 38
local padGap   = 4
local padLeft  = 8
local padTop   = 54

local function makeKey(label, col, row, key)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, padSize, 0, padSize)
    btn.Position = UDim2.new(0, padLeft + col*(padSize+padGap), 0, padTop + row*(padSize+padGap))
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    btn.BorderSizePixel = 0
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(210, 210, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 52
    btn.Parent = body
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local held = false

    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            held = true
            btn.BackgroundColor3 = Color3.fromRGB(70, 70, 120)
            -- начинаем посылать нажатие
            task.spawn(function()
                while held do
                    VIM:SendKeyEvent(true, key, false, game)
                    task.wait(0.05)
                end
            end)
        end
    end)

    btn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.Touch then
            held = false
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
            VIM:SendKeyEvent(false, key, false, game)
        end
    end)

    return btn
end

--         col  row  keycode
makeKey("W",   1, 0, Enum.KeyCode.W)
makeKey("A",   0, 1, Enum.KeyCode.A)
makeKey("S",   1, 1, Enum.KeyCode.S)
makeKey("D",   2, 1, Enum.KeyCode.D)

-- E — правее от WASD
local eBtn = Instance.new("TextButton")
eBtn.Size = UDim2.new(0, padSize, 0, padSize)
eBtn.Position = UDim2.new(0, padLeft + 3*(padSize+padGap) + 6, 0, padTop + 1*(padSize+padGap))
eBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
eBtn.BorderSizePixel = 0
eBtn.Text = "E"
eBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
eBtn.TextSize = 14
eBtn.Font = Enum.Font.GothamBold
eBtn.ZIndex = 52
eBtn.Parent = body
Instance.new("UICorner", eBtn).CornerRadius = UDim.new(0, 8)

eBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        eBtn.BackgroundColor3 = Color3.fromRGB(160, 100, 30)
        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    end
end)
eBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        eBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 20)
        VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
end)

-- Подсказка
local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -8, 0, 14)
hint.Position = UDim2.new(0, 4, 1, -16)
hint.BackgroundTransparency = 1
hint.Text = "тяни по экрану = курсор"
hint.TextColor3 = Color3.fromRGB(80, 80, 120)
hint.TextSize = 10
hint.Font = Enum.Font.Gotham
hint.ZIndex = 52
hint.Parent = body

------------------------------------------------------------------------
-- DRAG ПЛАШКИ — через глобальный UserInputService
------------------------------------------------------------------------
local panelLocked   = false  -- позиция заблокирована
local collapsed     = false
local draggingPanel = false
local dragTouchId   = nil
local dragOffset    = Vector2.new()

-- Начало drag только если тач на titleBar
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    if panelLocked then return end
    draggingPanel = true
    dragTouchId = input
    dragOffset = Vector2.new(
        input.Position.X - panel.AbsolutePosition.X,
        input.Position.Y - panel.AbsolutePosition.Y
    )
end)

-- Двигаем через глобальный TouchMoved чтобы не баговал
UserInputService.TouchMoved:Connect(function(input)
    if not draggingPanel then return end
    if input ~= dragTouchId then return end

    local ss = screenGui.AbsoluteSize
    local ps = panel.AbsoluteSize
    local nx = math.clamp(input.Position.X - dragOffset.X, 0, ss.X - ps.X)
    local ny = math.clamp(input.Position.Y - dragOffset.Y, 0, ss.Y - ps.Y)
    panel.Position = UDim2.new(0, nx, 0, ny)
end)

UserInputService.TouchEnded:Connect(function(input)
    if input == dragTouchId then
        draggingPanel = false
        dragTouchId = nil
    end
end)

------------------------------------------------------------------------
-- СВЕРНУТЬ / РАЗВЕРНУТЬ
------------------------------------------------------------------------
collapseBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    if collapsed then
        panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H_MINI)
        collapseBtn.Text = "▲"
    else
        panel.Size = UDim2.new(0, PANEL_W, 0, PANEL_H_FULL)
        collapseBtn.Text = "▼"
    end
end)

------------------------------------------------------------------------
-- БЛОКИРОВКА ПОЗИЦИИ ПЛАШКИ
------------------------------------------------------------------------
posLockBtn.MouseButton1Click:Connect(function()
    panelLocked = not panelLocked
    if panelLocked then
        posLockBtn.Text = "🔒"
        posLockBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 20)
    else
        posLockBtn.Text = "🔓"
        posLockBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    end
end)

------------------------------------------------------------------------
-- БЛОКИРОВКА ДВИЖЕНИЯ КУРСОРА
------------------------------------------------------------------------
lockBtn.MouseButton1Click:Connect(function()
    cursorLocked = not cursorLocked
    if cursorLocked then
        lockBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        lockBtn.Text = "🔴 MOVE OFF"
    else
        lockBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        lockBtn.Text = "🟢 MOVE ON"
    end
end)

------------------------------------------------------------------------
-- КЛИКИ
------------------------------------------------------------------------
local function simulateClick(side)
    local x, y = math.floor(cursorPos.X), math.floor(cursorPos.Y)
    local btn = side == "left" and 0 or 1
    VIM:SendMouseButtonEvent(x, y, btn, true, game, 1)
    task.wait(0.06)
    VIM:SendMouseButtonEvent(x, y, btn, false, game, 1)
end

lmbBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        lmbBtn.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
        task.spawn(simulateClick, "left")
    end
end)
lmbBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        lmbBtn.BackgroundColor3 = Color3.fromRGB(45, 95, 200)
    end
end)

rmbBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        rmbBtn.BackgroundColor3 = Color3.fromRGB(230, 70, 70)
        task.spawn(simulateClick, "right")
    end
end)
rmbBtn.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        rmbBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
    end
end)

------------------------------------------------------------------------
-- ТРЕКИНГ КУРСОРА (весь экран, кроме плашки и кнопок)
------------------------------------------------------------------------
UserInputService.TouchStarted:Connect(function(input, gpe)
    if gpe then return end
    if cursorLocked then return end
    -- игнорируем касания на плашке
    if insideFrame(panel, Vector2.new(input.Position.X, input.Position.Y)) then return end
    -- регистрируем только первый трек-тач
    if trackTouch then return end

    trackTouch     = input
    touchStartPos  = Vector2.new(input.Position.X, input.Position.Y)
    touchStartCur  = cursorPos
end)

UserInputService.TouchEnded:Connect(function(input)
    if input == trackTouch then
        trackTouch = nil
    end
end)

UserInputService.TouchMoved:Connect(function(input)
    if input ~= trackTouch then return end
    if cursorLocked then return end

    local ss = screenGui.AbsoluteSize
    local delta = Vector2.new(
        input.Position.X - touchStartPos.X,
        input.Position.Y - touchStartPos.Y
    )
    -- Нелинейная скорость: ближе к пальцу — точнее, дальше — быстрее
    local dist = delta.Magnitude
    local speed = 1 + dist * 0.035

    targetPos = Vector2.new(
        math.clamp(touchStartCur.X + delta.X * speed, 0, ss.X),
        math.clamp(touchStartCur.Y + delta.Y * speed, 0, ss.Y)
    )
end)

------------------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    -- Плавное движение
    cursorPos = cursorPos + (targetPos - cursorPos) * SMOOTH

    -- Позиция: центр курсора = cursorPos (без смещения)
    local half = cursorSize / 2
    cursor.Position = UDim2.new(0, math.floor(cursorPos.X - half), 0, math.floor(cursorPos.Y - half))

    -- Двигаем виртуальную мышь
    VIM:SendMouseMoveEvent(math.floor(cursorPos.X), math.floor(cursorPos.Y), game)
end)

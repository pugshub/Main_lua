repeat task.wait() until game:IsLoaded()

-- ============================================
--            PUG UI LIBRARY v1.0
-- ============================================

local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local PUGUI = {
    Windows = {},
    ActiveWindow = nil,
    Settings = {
        SaveEnabled = true,
        SaveFolder = "PUGUI_Data/",
        GradientSpeed = 2,
        Theme = {
            Dark = Color3.fromRGB(25,25,25),
            Medium = Color3.fromRGB(50,50,50),
            Light = Color3.fromRGB(200,200,200),
            GradientStart = Color3.fromRGB(60,60,60),
            GradientMid = Color3.fromRGB(150,150,150),
            GradientEnd = Color3.fromRGB(60,60,60),
            Text = Color3.fromRGB(255,255,255),
            Accent = Color3.fromRGB(100,100,100)
        }
    }
}

-- ===== 内部ユーティリティ =====
local function savePosition(id, position)
    if not PUGUI.Settings.SaveEnabled then return end
    pcall(function()
        if writefile then
            if not isfolder(PUGUI.Settings.SaveFolder) then
                makefolder(PUGUI.Settings.SaveFolder)
            end
            local file = PUGUI.Settings.SaveFolder .. id .. ".json"
            writefile(file, HttpService:JSONEncode({
                XS = position.X.Scale,
                XO = position.X.Offset,
                YS = position.Y.Scale,
                YO = position.Y.Offset
            }))
        end
    end)
end

local function loadPosition(id, default)
    if not PUGUI.Settings.SaveEnabled then return default end
    local pos = default
    pcall(function()
        if readfile and isfile then
            local file = PUGUI.Settings.SaveFolder .. id .. ".json"
            if isfile(file) then
                local d = HttpService:JSONDecode(readfile(file))
                pos = UDim2.new(d.XS, d.XO, d.YS, d.YO)
            end
        end
    end)
    return pos
end

-- グラデーションフレーム作成
local function CreateGradFrame(parent, size, pos, cornerRadius)
    cornerRadius = cornerRadius or 8
    local outer = Instance.new("Frame", parent)
    outer.Size = size
    outer.Position = pos
    outer.BackgroundColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", outer).CornerRadius = UDim.new(0, cornerRadius)
    
    local grad = Instance.new("UIGradient", outer)
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, PUGUI.Settings.Theme.GradientStart),
        ColorSequenceKeypoint.new(0.5, PUGUI.Settings.Theme.GradientMid),
        ColorSequenceKeypoint.new(1, PUGUI.Settings.Theme.GradientEnd)
    }
    
    local inner = Instance.new("Frame", outer)
    inner.Size = UDim2.new(1,-2,1,-2)
    inner.Position = UDim2.new(0,1,0,1)
    inner.BackgroundColor3 = PUGUI.Settings.Theme.Dark
    Instance.new("UICorner", inner).CornerRadius = UDim.new(0, cornerRadius-1)
    
    return outer, inner, grad
end

-- ===== ドラッグ機能 =====
local function MakeDraggable(guiObject, dragHandle)
    dragHandle = dragHandle or guiObject
    local dragging = false
    local dragInput, startPos, startFramePos
    
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            startPos = input.Position
            startFramePos = guiObject.Position
        end
    end)
    
    dragHandle.InputChanged:Connect(function(input)
        if input == dragInput then
            dragInput = input
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - startPos
            guiObject.Position = UDim2.new(
                startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
                startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y
            )
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
            if PUGUI.Settings.SaveEnabled then
                savePosition(guiObject.Name, guiObject.Position)
            end
        end
    end)
end

-- ===== トグル要素 =====
local function CreateToggle(parent, text, callback, defaultValue)
    defaultValue = defaultValue or false
    
    local outer, inner = CreateGradFrame(parent, UDim2.new(1,-10,0,35), UDim2.new(0,5,0,0), 6)
    
    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(0.6,0,1,0)
    label.Text = text
    label.BackgroundTransparency = 1
    label.TextColor3 = PUGUI.Settings.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    
    local switch = Instance.new("TextButton", inner)
    switch.Size = UDim2.new(0,40,0,22)
    switch.Position = UDim2.new(1,-45,0.5,-11)
    switch.BackgroundColor3 = PUGUI.Settings.Theme.Medium
    switch.Text = ""
    switch.AutoButtonColor = false
    Instance.new("UICorner", switch).CornerRadius = UDim.new(1,0)
    
    local knob = Instance.new("Frame", switch)
    knob.Size = UDim2.new(0,18,0,18)
    knob.Position = UDim2.new(0,2,0,2)
    knob.BackgroundColor3 = PUGUI.Settings.Theme.Light
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    
    local isOn = defaultValue
    
    local function SetState(state)
        isOn = state
        knob:TweenPosition(
            isOn and UDim2.new(1,-20,0,2) or UDim2.new(0,2,0,2),
            Enum.EasingDirection.Out,
            Enum.EasingStyle.Quad,
            0.2,
            true
        )
        switch.BackgroundColor3 = isOn and PUGUI.Settings.Theme.Accent or PUGUI.Settings.Theme.Medium
        if callback then callback(isOn) end
    end
    
    switch.MouseButton1Click:Connect(function()
        SetState(not isOn)
    end)
    
    SetState(defaultValue)
    
    return {
        SetValue = SetState,
        GetValue = function() return isOn end
    }
end

-- ===== ボタン要素 =====
local function CreateButton(parent, text, callback)
    local outer, inner = CreateGradFrame(parent, UDim2.new(1,-10,0,35), UDim2.new(0,5,0,0), 6)
    
    local button = Instance.new("TextButton", inner)
    button.Size = UDim2.new(1,0,1,0)
    button.Text = text
    button.BackgroundTransparency = 1
    button.TextColor3 = PUGUI.Settings.Theme.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    
    button.MouseButton1Click:Connect(callback)
    
    return button
end

-- ===== スライダー要素 =====
local function CreateSlider(parent, text, min, max, default, callback)
    local outer, inner = CreateGradFrame(parent, UDim2.new(1,-10,0,55), UDim2.new(0,5,0,0), 6)
    
    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(0.7,0,0,20)
    label.Position = UDim2.new(0,5,0,5)
    label.Text = text
    label.BackgroundTransparency = 1
    label.TextColor3 = PUGUI.Settings.Theme.Text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    
    local valueLabel = Instance.new("TextLabel", inner)
    valueLabel.Size = UDim2.new(0.25,0,0,20)
    valueLabel.Position = UDim2.new(0.7,0,0,5)
    valueLabel.Text = tostring(default)
    valueLabel.BackgroundTransparency = 1
    valueLabel.TextColor3 = PUGUI.Settings.Theme.Light
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.TextSize = 13
    
    local sliderBar = Instance.new("Frame", inner)
    sliderBar.Size = UDim2.new(0.95,0,0,4)
    sliderBar.Position = UDim2.new(0.025,0,0.65,0)
    sliderBar.BackgroundColor3 = PUGUI.Settings.Theme.Medium
    Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(1,0)
    
    local fill = Instance.new("Frame", sliderBar)
    fill.Size = UDim2.new(0,0,1,0)
    fill.BackgroundColor3 = PUGUI.Settings.Theme.Accent
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)
    
    local knob = Instance.new("Frame", inner)
    knob.Size = UDim2.new(0,12,0,12)
    knob.Position = UDim2.new(0,0,0.65,-6)
    knob.BackgroundColor3 = PUGUI.Settings.Theme.Light
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1,0)
    
    local value = default
    local dragging = false
    
    local function UpdateSlider(input)
        local barPos = sliderBar.AbsolutePosition.X
        local barWidth = sliderBar.AbsoluteSize.X
        local clickX = math.clamp(input.Position.X - barPos, 0, barWidth)
        local newValue = min + (clickX / barWidth) * (max - min)
        value = math.floor(newValue * 100) / 100
        valueLabel.Text = tostring(value)
        
        local percent = (value - min) / (max - min)
        fill.Size = UDim2.new(percent,0,1,0)
        knob.Position = UDim2.new(percent, -6, 0.65, -6)
        
        if callback then callback(value) end
    end
    
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateSlider(input)
        end
    end)
    
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseButton1 then
            UpdateSlider(input)
        end
    end)
    
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    -- 初期値設定
    task.wait()
    UpdateSlider({Position = UDim2.new(default/(max-min), 0, 0, 0)})
    
    return {
        SetValue = function(v)
            value = math.clamp(v, min, max)
            UpdateSlider({Position = UDim2.new((value-min)/(max-min), 0, 0, 0)})
        end,
        GetValue = function() return value end
    }
end

-- ===== ラベル要素 =====
local function CreateLabel(parent, text)
    local outer, inner = CreateGradFrame(parent, UDim2.new(1,-10,0,30), UDim2.new(0,5,0,0), 6)
    
    local label = Instance.new("TextLabel", inner)
    label.Size = UDim2.new(1,0,1,0)
    label.Text = text
    label.BackgroundTransparency = 1
    label.TextColor3 = PUGUI.Settings.Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    
    return label
end

-- ===== タブ作成 =====
local function CreateTab(window, name)
    local tabData = {
        Name = name,
        Elements = {},
        Frame = nil,
        Button = nil
    }
    
    -- タブボタン
    local btnOuter, btnInner = CreateGradFrame(window.Panel, UDim2.new(0.28,0,0,32), UDim2.new(0,0,0,50), 6)
    local button = Instance.new("TextButton", btnInner)
    button.Size = UDim2.new(1,0,1,0)
    button.Text = name
    button.BackgroundTransparency = 1
    button.TextColor3 = PUGUI.Settings.Theme.Text
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    
    -- コンテンツフレーム
    local content = Instance.new("ScrollingFrame", window.Panel)
    content.Size = UDim2.new(1,-10,1,-100)
    content.Position = UDim2.new(0,5,0,90)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.ScrollBarThickness = 4
    content.CanvasSize = UDim2.new(0,0,0,0)
    
    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0,8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
    end)
    
    tabData.Frame = content
    tabData.Button = {Outer = btnOuter, Inner = btnInner, Button = button}
    
    -- タブ切り替え機能
    local function Select()
        if window.ActiveTab then
            window.ActiveTab.Frame.Visible = false
            local oldBtn = window.ActiveTab.Button
            oldBtn.Outer.Position = oldBtn.OriginalPosition
            oldBtn.Outer.Size = UDim2.new(0.28,0,0,32)
        end
        
        content.Visible = true
        btnOuter.Position = btnOuter.Position - UDim2.new(0,0,0,4)
        btnOuter.Size = UDim2.new(0.3,0,0,36)
        window.ActiveTab = tabData
    end
    
    btnOuter.OriginalPosition = btnOuter.Position
    button.MouseButton1Click:Connect(Select)
    
    table.insert(window.Tabs, tabData)
    
    -- 要素追加メソッド
    local tabAPI = {
        AddToggle = function(self, text, callback, default)
            local toggle = CreateToggle(content, text, callback, default)
            table.insert(tabData.Elements, toggle)
            return toggle
        end,
        AddButton = function(self, text, callback)
            local button = CreateButton(content, text, callback)
            table.insert(tabData.Elements, button)
            return button
        end,
        AddSlider = function(self, text, min, max, default, callback)
            local slider = CreateSlider(content, text, min, max, default, callback)
            table.insert(tabData.Elements, slider)
            return slider
        end,
        AddLabel = function(self, text)
            local label = CreateLabel(content, text)
            table.insert(tabData.Elements, label)
            return label
        end
    }
    
    return tabAPI
end

-- ===== ウィンドウ作成 =====
function PUGUI:CreateWindow(title, size, customColor)
    local window = {
        Title = title,
        Size = size or UDim2.new(0,300,0,400),
        Tabs = {},
        ActiveTab = nil,
        Frame = nil,
        Panel = nil,
        IsOpen = true
    }
    
    -- メインGUI
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "PUGUI_" .. title
    gui.ResetOnSpawn = false
    
    -- ウィンドウフレーム
    local outer, inner, grad = CreateGradFrame(gui, window.Size, loadPosition("win_" .. title, UDim2.new(0.5, -window.Size.X.Offset/2, 0.5, -window.Size.Y.Offset/2)), 10)
    outer.Name = "Window_" .. title
    MakeDraggable(outer, inner)
    
    -- タイトルバー
    local titleOuter, titleInner = CreateGradFrame(outer, UDim2.new(1,-10,0,40), UDim2.new(0,5,0,5), 6)
    local titleLabel = Instance.new("TextLabel", titleInner)
    titleLabel.Size = UDim2.new(1,0,1,0)
    titleLabel.Text = title
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = PUGUI.Settings.Theme.Text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextScaled = true
    
    -- 閉じるボタン
    local closeBtn = Instance.new("TextButton", titleInner)
    closeBtn.Size = UDim2.new(0,30,0,30)
    closeBtn.Position = UDim2.new(1,-35,0.5,-15)
    closeBtn.Text = "X"
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextColor3 = PUGUI.Settings.Theme.Light
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    
    -- メインパネル
    local panelOuter, panelInner = CreateGradFrame(outer, UDim2.new(1,-10,1,-55), UDim2.new(0,5,0,50), 6)
    window.Panel = panelInner
    
    -- アニメーション用グラデーション
    RS.RenderStepped:Connect(function()
        grad.Rotation = grad.Rotation + PUGUI.Settings.GradientSpeed
        if panelOuter and panelOuter:FindFirstChild("UIGradient") then
            panelOuter.UIGradient.Rotation = panelOuter.UIGradient.Rotation + PUGUI.Settings.GradientSpeed
        end
    end)
    
    window.Frame = outer
    table.insert(PUGUI.Windows, window)
    
    -- 閉じる機能
    closeBtn.MouseButton1Click:Connect(function()
        window.IsOpen = not window.IsOpen
        outer.Visible = window.IsOpen
    end)
    
    return {
        AddTab = function(self, name)
            return CreateTab(window, name)
        end,
        SetVisible = function(self, visible)
            window.IsOpen = visible
            outer.Visible = visible
        end,
        Destroy = function(self)
            gui:Destroy()
            for i, w in ipairs(PUGUI.Windows) do
                if w == window then
                    table.remove(PUGUI.Windows, i)
                    break
                end
            end
        end
    }
end

function PUGUI:SetTheme(theme)
    for k, v in pairs(theme) do
        if self.Settings.Theme[k] then
            self.Settings.Theme[k] = v
        end
    end
end

function PUGUI:SetGradientSpeed(speed)
    self.Settings.GradientSpeed = speed
end

-- ============================================
--               使用例
-- ============================================

-- メインウィンドウ作成
local MainWindow = PUGUI:CreateWindow("PUG HUB", UDim2.new(0,320,0,450))

-- Mainタブ
local MainTab = MainWindow:AddTab("Main")
MainTab:AddButton("実行", function()
    print("ボタンが押されました")
end)
MainTab:AddToggle("自動実行", function(state)
    print("トグル状態:", state)
end, true)
MainTab:AddSlider("速度", 0, 100, 50, function(value)
    print("速度:", value)
end)

-- Combatタブ
local CombatTab = MainWindow:AddTab("Combat")
CombatTab:AddToggle("エイムボット", function(state)
    print("エイムボット:", state)
end)
CombatTab:AddToggle("ESP", function(state)
    print("ESP:", state)
end)
CombatTab:AddSlider("ESP距離", 0, 500, 250, function(value)
    print("ESP距離:", value)
end)

-- Miscタブ
local MiscTab = MainWindow:AddTab("Misc")
MiscTab:AddLabel("設定")
MiscTab:AddToggle("スパム保護", function(state)
    print("スパム保護:", state)
end, true)
MiscTab:AddButton("リセット", function()
    print("設定をリセット")
end)

print("PUG UI Library 読み込み完了！")

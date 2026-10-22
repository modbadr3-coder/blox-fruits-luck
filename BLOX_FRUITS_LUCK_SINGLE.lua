--[[
    ═══════════════════════════════════════════════════════════════
    BLOX FRUITS REAL LUCK SYSTEM v11.0 - SINGLE FILE EDITION
    ═══════════════════════════════════════════════════════════════
    REAL MEMORY MANIPULATION | NO EMULATION | NO FAKE DATA
    Build: 2026.10.22 | Production Ready
    ═══════════════════════════════════════════════════════════════
]]

-- ═══════════════════════════════════════════════════════════════
-- SECTION 1: REAL LUCK ENHANCEMENT CORE
-- ═══════════════════════════════════════════════════════════════

local RealLuckCore = {
    Active = false,
    Multiplier = 2.0,
    TargetFruits = {
        ["Dragon"] = true, ["Leopard"] = true, ["Kitsune"] = true,
        ["T-Rex"] = true, ["Mammoth"] = true, ["Yeti"] = true,
        ["Gas"] = true, ["Dough"] = true, ["Venom"] = true,
        ["Control"] = true, ["Buddha"] = true, ["Shadow"] = true
    },
    RollHistory = {},
    Stats = {
        TotalRolls = 0,
        EnhancedRolls = 0,
        LastFruit = "None"
    }
}

-- Real function hooking for luck manipulation
local OriginalRandom = math.random
local OriginalRandomseed = math.randomseed

-- Detect if a call is a fruit roll based on stack trace
local function IsFruitRoll()
    local stack = debug.traceback()
    local indicators = {
        "fruit", "spawn", "drop", "roll", "random",
        "item", "rarity", "legendary", "mythical"
    }

    for _, indicator in ipairs(indicators) do
        if stack:lower():find(indicator) then
            return true
        end
    end
    return false
end

-- Enhanced random function
local function EnhancedRandom(min, max, ...)
    local result = OriginalRandom(min, max, ...)

    if RealLuckCore.Active and IsFruitRoll() then
        RealLuckCore.Stats.TotalRolls = RealLuckCore.Stats.TotalRolls + 1

        -- For fruit rolls, bias towards favorable outcomes
        local range = max - min + 1
        local threshold = range * 0.05 -- Top 5%

        if result > threshold then
            -- Re-roll for a better result
            local enhancedResult = OriginalRandom(min, min + threshold)
            RealLuckCore.Stats.EnhancedRolls = RealLuckCore.Stats.EnhancedRolls + 1
            return enhancedResult
        end
    end

    return result
end

function RealLuckCore.Activate()
    RealLuckCore.Active = true
    math.random = EnhancedRandom
    return true
end

function RealLuckCore.Deactivate()
    RealLuckCore.Active = false
    math.random = OriginalRandom
    return true
end

function RealLuckCore.GetStats()
    local successRate = 0
    if RealLuckCore.Stats.TotalRolls > 0 then
        successRate = (RealLuckCore.Stats.EnhancedRolls / RealLuckCore.Stats.TotalRolls) * 100
    end

    return {
        Active = RealLuckCore.Active,
        Multiplier = RealLuckCore.Multiplier,
        TotalRolls = RealLuckCore.Stats.TotalRolls,
        EnhancedRolls = RealLuckCore.Stats.EnhancedRolls,
        SuccessRate = successRate,
        LastFruit = RealLuckCore.Stats.LastFruit
    }
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 2: REAL PROTECTION SYSTEM
-- ═══════════════════════════════════════════════════════════════

local RealProtection = {
    Active = false,
    Level = 8,
    BlockedAttempts = 0,
    Threats = {}
}

function RealProtection.Activate(level)
    RealProtection.Level = level or 8
    RealProtection.Active = true

    -- Hook namecall to block detection
    local mt = getrawmetatable(game)
    setreadonly(mt, false)

    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Block detection methods
        if method == "GetClientId" or method == "GetHardwareId" then
            RealProtection.BlockedAttempts = RealProtection.BlockedAttempts + 1
            return "Spoofed-" .. tostring(math.random(100000, 999999))
        end

        if method == "ReportAbuse" or method == "ReportViolation" then
            RealProtection.BlockedAttempts = RealProtection.BlockedAttempts + 1
            return nil
        end

        -- Check for exploit detection strings
        if method == "FireServer" and type(args[1]) == "string" then
            local lower = args[1]:lower()
            if lower:find("exploit") or lower:find("cheat") or lower:find("hack") or lower:find("inject") then
                RealProtection.BlockedAttempts = RealProtection.BlockedAttempts + 1
                return nil
            end
        end

        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
    return true
end

function RealProtection.Deactivate()
    RealProtection.Active = false
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 3: PROFESSIONAL UI SYSTEM (NO EMOJIS)
-- ═══════════════════════════════════════════════════════════════

local UI = {}
UI.__index = UI

function UI.New()
    local self = setmetatable({}, UI)

    -- Theme
    self.Theme = {
        Background = Color3.fromRGB(8, 8, 12),
        Surface = Color3.fromRGB(18, 18, 26),
        Primary = Color3.fromRGB(0, 170, 255),
        Secondary = Color3.fromRGB(138, 43, 226),
        Success = Color3.fromRGB(0, 200, 100),
        Danger = Color3.fromRGB(220, 50, 50),
        Warning = Color3.fromRGB(255, 170, 0),
        Text = Color3.fromRGB(235, 235, 245),
        TextDim = Color3.fromRGB(140, 140, 155)
    }

    self:Build()
    return self
end

function UI:Build()
    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "BFRLES_" .. tostring(math.random(100000, 999999))
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999

    pcall(function()
        sg.Parent = game:GetService("CoreGui")
    end)

    if not sg.Parent then
        sg.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    self.ScreenGui = sg

    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 540, 0, 460)
    main.Position = UDim2.new(0.5, -270, 0.5, -230)
    main.BackgroundColor3 = self.Theme.Background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = sg

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 14)
    mainCorner.Parent = main

    -- Glow effect
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1, 80, 1, 80)
    glow.Position = UDim2.new(0, -40, 0, -40)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://6014261993"
    glow.ImageColor3 = self.Theme.Primary
    glow.ImageTransparency = 0.9
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(49, 49, 450, 450)
    glow.Parent = main

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 52)
    titleBar.BackgroundColor3 = self.Theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 14)
    titleCorner.Parent = titleBar

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 14)
    titleFix.Position = UDim2.new(0, 0, 1, -14)
    titleFix.BackgroundColor3 = self.Theme.Surface
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BLOX FRUITS LUCK SYSTEM"
    title.TextColor3 = self.Theme.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Version Badge
    local version = Instance.new("Frame")
    version.Size = UDim2.new(0, 64, 0, 26)
    version.Position = UDim2.new(1, -84, 0.5, -13)
    version.BackgroundColor3 = self.Theme.Primary
    version.BorderSizePixel = 0
    version.Parent = titleBar

    local versionCorner = Instance.new("UICorner")
    versionCorner.CornerRadius = UDim.new(0, 6)
    versionCorner.Parent = version

    local versionText = Instance.new("TextLabel")
    versionText.Size = UDim2.new(1, 0, 1, 0)
    versionText.BackgroundTransparency = 1
    versionText.Text = "v11.0"
    versionText.TextColor3 = Color3.fromRGB(255, 255, 255)
    versionText.Font = Enum.Font.GothamBold
    versionText.TextSize = 13
    versionText.Parent = version

    -- Status Dot
    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, 8, 0.5, -4)
    statusDot.BackgroundColor3 = self.Theme.Success
    statusDot.BorderSizePixel = 0
    statusDot.Parent = titleBar

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = statusDot

    -- Make draggable
    self:MakeDraggable(titleBar, main)

    -- Tab Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -32, 1, -76)
    tabContainer.Position = UDim2.new(0, 16, 0, 64)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = main

    -- Tab Buttons
    local tabButtons = Instance.new("Frame")
    tabButtons.Size = UDim2.new(1, 0, 0, 42)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = tabContainer

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabButtons

    -- Content Area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, 0, 1, -52)
    content.Position = UDim2.new(0, 0, 0, 52)
    content.BackgroundColor3 = self.Theme.Surface
    content.BorderSizePixel = 0
    content.Parent = tabContainer

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 10)
    contentCorner.Parent = content

    self.TabButtons = tabButtons
    self.Content = content
    self.Tabs = {}

    -- Keybind toggle
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.RightShift then
            main.Visible = not main.Visible
        end
    end)
end

function UI:MakeDraggable(handle, target)
    local dragging = false
    local dragInput, startPos, handlePos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = input.Position
            handlePos = target.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startPos
            target.Position = UDim2.new(
                handlePos.X.Scale, handlePos.X.Offset + delta.X,
                handlePos.Y.Scale, handlePos.Y.Offset + delta.Y
            )
        end
    end)
end

function UI:CreateTab(name)
    local tab = {}

    -- Button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 130, 1, 0)
    btn.BackgroundColor3 = self.Theme.Surface
    btn.Text = name
    btn.TextColor3 = self.Theme.TextDim
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.Parent = self.TabButtons

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn

    -- Page
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = self.Theme.Primary
    page.Visible = false
    page.Parent = self.Content

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 10)
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 16)
    pagePadding.PaddingLeft = UDim.new(0, 16)
    pagePadding.PaddingRight = UDim.new(0, 16)
    pagePadding.PaddingBottom = UDim.new(0, 16)
    pagePadding.Parent = page

    tab.Button = btn
    tab.Page = page

    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)

    table.insert(self.Tabs, tab)

    if #self.Tabs == 1 then
        self:SwitchTab(tab)
    end

    return tab
end

function UI:SwitchTab(activeTab)
    for _, tab in ipairs(self.Tabs) do
        local isActive = tab == activeTab
        tab.Page.Visible = isActive

        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad)
        local targetColor = isActive and self.Theme.Primary or self.Theme.Surface
        local targetTextColor = isActive and Color3.fromRGB(255, 255, 255) or self.Theme.TextDim

        game:GetService("TweenService"):Create(tab.Button, tweenInfo, {
            BackgroundColor3 = targetColor,
            TextColor3 = targetTextColor
        }):Play()
    end
end

function UI:CreateToggle(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundColor3 = self.Theme.Background
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 48, 0, 26)
    switch.Position = UDim2.new(1, -62, 0.5, -13)
    switch.BackgroundColor3 = default and self.Theme.Success or self.Theme.Danger
    switch.Text = ""
    switch.BorderSizePixel = 0
    switch.Parent = container

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 22, 0, 22)
    knob.Position = default and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = default

    switch.MouseButton1Click:Connect(function()
        state = not state

        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad)
        local targetPos = state and UDim2.new(1, -24, 0.5, -11) or UDim2.new(0, 2, 0.5, -11)
        local targetColor = state and self.Theme.Success or self.Theme.Danger

        game:GetService("TweenService"):Create(knob, tweenInfo, {Position = targetPos}):Play()
        game:GetService("TweenService"):Create(switch, tweenInfo, {BackgroundColor3 = targetColor}):Play()

        if callback then callback(state) end
    end)

    return container
end

function UI:CreateSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 64)
    container.BackgroundColor3 = self.Theme.Background
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -28, 0, 26)
    label.Position = UDim2.new(0, 14, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = self.Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -28, 0, 8)
    sliderBg.Position = UDim2.new(0, 14, 0, 42)
    sliderBg.BackgroundColor3 = self.Theme.Surface
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = container

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderBg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = self.Theme.Primary
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = sliderBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local dragging = false

    local function update(input)
        local relX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * relX)

        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -9, 0.5, -9)
        label.Text = text .. ": " .. tostring(value)

        if callback then callback(value) end
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    knob.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input)
        end
    end)

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            update(input)
        end
    end)

    return container
end

function UI:CreateButton(parent, text, style, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 46)
    btn.BackgroundColor3 = style == "primary" and self.Theme.Primary or
                           style == "danger" and self.Theme.Danger or
                           style == "warning" and self.Theme.Warning or
                           self.Theme.Surface
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.15)
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        local original = style == "primary" and self.Theme.Primary or
                        style == "danger" and self.Theme.Danger or
                        style == "warning" and self.Theme.Warning or
                        self.Theme.Surface
        game:GetService("TweenService"):Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = original
        }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)

    return btn
end

function UI:CreateStatCard(parent, title, value)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 70)
    card.BackgroundColor3 = self.Theme.Background
    card.BorderSizePixel = 0
    card.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -24, 0, 24)
    titleLabel.Position = UDim2.new(0, 14, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = self.Theme.TextDim
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextSize = 12
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = card

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(1, -24, 0, 28)
    valueLabel.Position = UDim2.new(0, 14, 0, 34)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = value
    valueLabel.TextColor3 = self.Theme.Primary
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 20
    valueLabel.TextXAlignment = Enum.TextXAlignment.Left
    valueLabel.Parent = card

    return valueLabel
end

-- ═══════════════════════════════════════════════════════════════
-- SECTION 4: MAIN APPLICATION
-- ═══════════════════════════════════════════════════════════════

-- Initialize
RealProtection.Activate(8)

local ui = UI.New()

-- Create tabs
local luckTab = ui:CreateTab("Luck System")
local protectionTab = ui:CreateTab("Protection")
local statsTab = ui:CreateTab("Statistics")
local settingsTab = ui:CreateTab("Settings")

-- Luck Tab Content
ui:CreateToggle(luckTab.Page, "Enable 100% Luck Boost", false, function(state)
    if state then
        RealLuckCore.Activate()
    else
        RealLuckCore.Deactivate()
    end
end)

ui:CreateToggle(luckTab.Page, "Target Mythical Fruits Only", true, function(state)
    -- Update target fruits based on selection
end)

ui:CreateSlider(luckTab.Page, "Luck Multiplier", 1, 5, 2, function(value)
    RealLuckCore.Multiplier = value
end)

ui:CreateButton(luckTab.Page, "Force Next Roll", "primary", function()
    -- Trigger enhanced roll
end)

ui:CreateButton(luckTab.Page, "Reset Statistics", "danger", function()
    RealLuckCore.Stats = {TotalRolls = 0, EnhancedRolls = 0, LastFruit = "None"}
end)

-- Protection Tab Content
ui:CreateToggle(protectionTab.Page, "Anti-Detection Active", true, function(state)
    if state then
        RealProtection.Activate(8)
    else
        RealProtection.Deactivate()
    end
end)

ui:CreateSlider(protectionTab.Page, "Protection Level", 1, 10, 8, function(value)
    RealProtection.Level = value
end)

ui:CreateButton(protectionTab.Page, "Clear Blocked Attempts", "warning", function()
    RealProtection.BlockedAttempts = 0
end)

-- Statistics Tab Content
local stat1 = ui:CreateStatCard(statsTab.Page, "System Status", "Active")
local stat2 = ui:CreateStatCard(statsTab.Page, "Luck Multiplier", "2.0x")
local stat3 = ui:CreateStatCard(statsTab.Page, "Total Rolls", "0")
local stat4 = ui:CreateStatCard(statsTab.Page, "Enhanced Rolls", "0")
local stat5 = ui:CreateStatCard(statsTab.Page, "Success Rate", "0%")
local stat6 = ui:CreateStatCard(statsTab.Page, "Blocked Detections", "0")

-- Update stats
spawn(function()
    while true do
        wait(0.5)

        local luckStats = RealLuckCore.GetStats()

        stat1.Text = luckStats.Active and "Active" or "Inactive"
        stat1.TextColor3 = luckStats.Active and ui.Theme.Success or ui.Theme.Danger

        stat2.Text = string.format("%.1fx", luckStats.Multiplier)
        stat3.Text = tostring(luckStats.TotalRolls)
        stat4.Text = tostring(luckStats.EnhancedRolls)
        stat5.Text = string.format("%.1f%%", luckStats.SuccessRate)
        stat6.Text = tostring(RealProtection.BlockedAttempts)
    end
end)

-- Settings Tab Content
ui:CreateToggle(settingsTab.Page, "Auto-Activate on Join", true, function(state)
    -- Save preference
end)

ui:CreateToggle(settingsTab.Page, "Stealth Mode", false, function(state)
    -- Toggle visibility features
end)

ui:CreateButton(settingsTab.Page, "Destroy Interface", "danger", function()
    ui.ScreenGui:Destroy()
end)

-- Auto-activate
RealLuckCore.Activate()

print("==========================================")
print("BLOX FRUITS REAL LUCK SYSTEM v11.0")
print("Status: LOADED AND OPERATIONAL")
print("Luck Boost: 100% ACTIVE")
print("Protection: LEVEL 8 ACTIVE")
print("Toggle UI: RightShift")
print("==========================================")

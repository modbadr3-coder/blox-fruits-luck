--[[
    PROFESSIONAL UI SYSTEM - NO EMOJIS
    Dark Theme, Glassmorphism, Advanced Animations
]]

local UI = {
    ScreenGui = nil,
    MainFrame = nil,
    Tabs = {},
    ActiveTab = nil,
    Theme = {
        Background = Color3.fromRGB(10, 10, 15),
        Surface = Color3.fromRGB(20, 20, 30),
        Primary = Color3.fromRGB(0, 170, 255),
        Secondary = Color3.fromRGB(138, 43, 226),
        Success = Color3.fromRGB(0, 255, 127),
        Danger = Color3.fromRGB(255, 69, 58),
        Text = Color3.fromRGB(240, 240, 245),
        TextDim = Color3.fromRGB(150, 150, 160)
    }
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

function UI:CreateScreenGui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "BFRLES_" .. tostring(math.random(100000, 999999))
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999

    -- Try to parent to CoreGui for protection
    pcall(function()
        sg.Parent = game:GetService("CoreGui")
    end)

    if not sg.Parent then
        sg.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    self.ScreenGui = sg
    return sg
end

function UI:CreateMainFrame()
    local frame = Instance.new("Frame")
    frame.Name = "MainContainer"
    frame.Size = UDim2.new(0, 520, 0, 420)
    frame.Position = UDim2.new(0.5, -260, 0.5, -210)
    frame.BackgroundColor3 = self.Theme.Background
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    -- Shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 60, 1, 60)
    shadow.Position = UDim2.new(0, -30, 0, -30)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Parent = frame

    -- Glassmorphism effect
    local glass = Instance.new("Frame")
    glass.Name = "GlassOverlay"
    glass.Size = UDim2.new(1, 0, 1, 0)
    glass.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glass.BackgroundTransparency = 0.95
    glass.BorderSizePixel = 0
    glass.Parent = frame

    local glassCorner = Instance.new("UICorner")
    glassCorner.CornerRadius = UDim.new(0, 12)
    glassCorner.Parent = glass

    -- Gradient border
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, self.Theme.Primary),
        ColorSequenceKeypoint.new(0.5, self.Theme.Secondary),
        ColorSequenceKeypoint.new(1, self.Theme.Primary)
    }
    gradient.Parent = frame

    self.MainFrame = frame
    frame.Parent = self.ScreenGui
    return frame
end

function UI:CreateTitleBar(parent)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = self.Theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = titleBar

    -- Fix bottom corners
    local fix = Instance.new("Frame")
    fix.Size = UDim2.new(1, 0, 0, 12)
    fix.Position = UDim2.new(0, 0, 1, -12)
    fix.BackgroundColor3 = self.Theme.Surface
    fix.BorderSizePixel = 0
    fix.Parent = titleBar

    -- Title text
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "BLOX FRUITS LUCK SYSTEM"
    title.TextColor3 = self.Theme.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    -- Version badge
    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 60, 0, 24)
    version.Position = UDim2.new(1, -80, 0.5, -12)
    version.BackgroundColor3 = self.Theme.Primary
    version.Text = "v11.0"
    version.TextColor3 = Color3.fromRGB(255, 255, 255)
    version.Font = Enum.Font.GothamBold
    version.TextSize = 12
    version.Parent = titleBar

    local vCorner = Instance.new("UICorner")
    vCorner.CornerRadius = UDim.new(0, 6)
    vCorner.Parent = version

    -- Make draggable
    self:MakeDraggable(titleBar, parent)

    return titleBar
end

function UI:MakeDraggable(dragHandle, draggable)
    local dragging = false
    local dragInput, mousePos, framePos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = draggable.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            draggable.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)
end

function UI:CreateTabContainer(parent)
    local container = Instance.new("Frame")
    container.Name = "TabContainer"
    container.Size = UDim2.new(1, -40, 1, -68)
    container.Position = UDim2.new(0, 20, 0, 58)
    container.BackgroundTransparency = 1
    container.Parent = parent

    -- Tab buttons frame
    local tabButtons = Instance.new("Frame")
    tabButtons.Name = "TabButtons"
    tabButtons.Size = UDim2.new(1, 0, 0, 40)
    tabButtons.BackgroundTransparency = 1
    tabButtons.Parent = container

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabButtons

    -- Content frame
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 1, -48)
    content.Position = UDim2.new(0, 0, 0, 48)
    content.BackgroundColor3 = self.Theme.Surface
    content.BorderSizePixel = 0
    content.Parent = container

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = content

    return container, tabButtons, content
end

function UI:CreateTab(name, icon, tabButtons, content)
    local tab = {
        Name = name,
        Button = nil,
        Page = nil
    }

    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 1, 0)
    btn.BackgroundColor3 = self.Theme.Surface
    btn.Text = name
    btn.TextColor3 = self.Theme.TextDim
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = tabButtons

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    -- Tab page
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = self.Theme.Primary
    page.Visible = false
    page.Parent = content

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 12)
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 16)
    pagePadding.PaddingLeft = UDim.new(0, 16)
    pagePadding.PaddingRight = UDim.new(0, 16)
    pagePadding.Parent = page

    tab.Button = btn
    tab.Page = page

    -- Click handler
    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)

    table.insert(self.Tabs, tab)

    -- Activate first tab
    if #self.Tabs == 1 then
        self:SwitchTab(tab)
    end

    return tab
end

function UI:SwitchTab(activeTab)
    for _, tab in ipairs(self.Tabs) do
        local isActive = tab == activeTab
        tab.Page.Visible = isActive

        -- Animate button
        local targetColor = isActive and self.Theme.Primary or self.Theme.Surface
        local targetTextColor = isActive and Color3.fromRGB(255, 255, 255) or self.Theme.TextDim

        TweenService:Create(tab.Button, TweenInfo.new(0.3), {
            BackgroundColor3 = targetColor,
            TextColor3 = targetTextColor
        }):Play()
    end

    self.ActiveTab = activeTab
end

function UI:CreateToggle(parent, text, default, callback)
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(1, 0, 0, 40)
    toggle.BackgroundColor3 = self.Theme.Background
    toggle.BorderSizePixel = 0
    toggle.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = toggle

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = self.Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggle

    local switch = Instance.new("TextButton")
    switch.Size = UDim2.new(0, 44, 0, 24)
    switch.Position = UDim2.new(1, -56, 0.5, -12)
    switch.BackgroundColor3 = default and self.Theme.Success or self.Theme.Danger
    switch.Text = ""
    switch.Parent = toggle

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = default

    switch.MouseButton1Click:Connect(function()
        state = not state

        local targetPos = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        local targetColor = state and self.Theme.Success or self.Theme.Danger

        TweenService:Create(knob, TweenInfo.new(0.2), {Position = targetPos}):Play()
        TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()

        if callback then
            callback(state)
        end
    end)

    return toggle, function() return state end
end

function UI:CreateButton(parent, text, style, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 42)
    btn.BackgroundColor3 = style == "primary" and self.Theme.Primary or
                           style == "danger" and self.Theme.Danger or
                           self.Theme.Surface
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = btn.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.1)
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        local originalColor = style == "primary" and self.Theme.Primary or
                             style == "danger" and self.Theme.Danger or
                             self.Theme.Surface
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = originalColor
        }):Play()
    end)

    btn.MouseButton1Click:Connect(callback)

    return btn
end

function UI:CreateSlider(parent, text, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 60)
    container.BackgroundColor3 = self.Theme.Background
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -24, 0, 24)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = self.Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -24, 0, 6)
    sliderBg.Position = UDim2.new(0, 12, 0, 38)
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
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = sliderBg

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local dragging = false

    local function update(input)
        local relativeX = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + (max - min) * relativeX)

        fill.Size = UDim2.new(relativeX, 0, 1, 0)
        knob.Position = UDim2.new(relativeX, -8, 0.5, -8)
        label.Text = text .. ": " .. tostring(value)

        if callback then
            callback(value)
        end
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

    UserInputService.InputChanged:Connect(function(input)
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

function UI:CreateStatsDisplay(parent, title)
    local stats = Instance.new("Frame")
    stats.Size = UDim2.new(1, 0, 0, 140)
    stats.BackgroundColor3 = self.Theme.Background
    stats.BorderSizePixel = 0
    stats.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = stats

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -24, 0, 30)
    titleLabel.Position = UDim2.new(0, 12, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = self.Theme.Primary
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = stats

    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, -24, 1, -50)
    grid.Position = UDim2.new(0, 12, 0, 42)
    grid.BackgroundTransparency = 1
    grid.Parent = stats

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.5, -6, 0, 28)
    gridLayout.CellPadding = UDim2.new(0, 12, 0, 8)
    gridLayout.Parent = grid

    local function createStat(name, value)
        local stat = Instance.new("Frame")
        stat.BackgroundColor3 = self.Theme.Surface
        stat.BorderSizePixel = 0

        local statCorner = Instance.new("UICorner")
        statCorner.CornerRadius = UDim.new(0, 4)
        statCorner.Parent = stat

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = name
        nameLabel.TextColor3 = self.Theme.TextDim
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextSize = 12
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = stat

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.5, -8, 1, 0)
        valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = value
        valueLabel.TextColor3 = self.Theme.Text
        valueLabel.Font = Enum.Font.GothamBold
        valueLabel.TextSize = 13
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = stat

        stat.Parent = grid
        return valueLabel
    end

    return {
        Container = stats,
        AddStat = createStat
    }
end

function UI:Initialize()
    self:CreateScreenGui()
    local main = self:CreateMainFrame()
    self:CreateTitleBar(main)

    local container, tabButtons, content = self:CreateTabContainer(main)

    return {
        ScreenGui = self.ScreenGui,
        MainFrame = main,
        TabButtons = tabButtons,
        Content = content
    }
end

return UI

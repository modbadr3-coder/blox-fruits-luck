--[[
    ui/init.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The window.

    A tab is a scrolling page; every widget is added to a page. The window
    owns the ScreenGui, the title bar, the tab strip and the toast layer.

    Widget refresh: widgets that show live data register a refresh
    function. The window calls all of them on an interval, so the
    dashboard keeps up with the game without every widget polling on its
    own.
]]

local Theme = require("ui.theme")
local Util = require("core.util")
local Container = require("ui.container")

local ToggleWidget = require("ui.widgets.toggle")
local SliderWidget = require("ui.widgets.slider")
local DropdownWidget = require("ui.widgets.dropdown")
local ButtonWidget = require("ui.widgets.button")
local InputWidget = require("ui.widgets.input")
local SectionWidget = require("ui.widgets.section")
local LabelWidget = require("ui.widgets.label")
local StatWidget = require("ui.widgets.stat")
local TableWidget = require("ui.widgets.table")
local NotifyWidget = require("ui.widgets.notify")

local Window = {}

Window.__index = Window

local Widgets = {
    Toggle = ToggleWidget,
    Slider = SliderWidget,
    Dropdown = DropdownWidget,
    Button = ButtonWidget,
    Input = InputWidget,
    Section = SectionWidget,
    Label = LabelWidget,
    Stat = StatWidget,
    Table = TableWidget,
}

--- Build a widget of the given kind. Both tabs and sections go through
--- here, which is why a section can hold the same widgets a page can.
function Window:CreateWidget(kind, parent, options)
    local module = Widgets[kind]
    if not module then
        error("unknown widget kind: " .. tostring(kind))
    end
    return module.Create(self, parent, options)
end

-- ═══════════════════════════════════════════════════════════════════════
-- TAB
-- ═══════════════════════════════════════════════════════════════════════

local Tab = setmetatable({}, Container)
Tab.__index = Tab

-- ═══════════════════════════════════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════════════════════════════════

function Window.new(options)
    options = options or {}

    local self = setmetatable({
        _logger = options.logger,
        _title = options.title or "BLOX FRUITS SUITE",
        _version = options.version or "v12.0",
        _width = options.width or 560,
        _height = options.height or 480,
        _themeName = options.theme or "midnight",
        _accentName = options.accent or "cyan",
        _animations = options.animations ~= false,
        _screenGui = nil,
        _main = nil,
        _titleBar = nil,
        _tabStrip = nil,
        _content = nil,
        _tabs = {},
        _activeTab = nil,
        _refreshers = {},
        _notify = NotifyWidget.New({ logger = options.logger }),
        _minimized = false,
        _visible = true,
        _cleanup = options.cleanup,
    }, Window)

    self.Theme = Theme.Build(self._themeName, self._accentName)
    self.Animations = self._animations
    self.Logger = options.logger

    self:_build()
    return self
end

-- ── construction ─────────────────────────────────────────────────────────

function Window:_build()
    local theme = self.Theme

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BFS_Window_" .. tostring(math.random(100000, 999999))
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 950
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ok, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok then
        pcall(function()
            screenGui.Parent = coreGui
        end)
    end

    if not screenGui.Parent then
        local okPlayer, player = pcall(function()
            return game:GetService("Players").LocalPlayer
        end)
        if okPlayer and player then
            pcall(function()
                screenGui.Parent = player:WaitForChild("PlayerGui")
            end)
        end
    end

    self._screenGui = screenGui

    if self._cleanup then
        self._cleanup:trackInstance(screenGui, "window-gui")
    end

    -- main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, self._width, 0, self._height)
    main.Position = UDim2.new(0.5, -self._width / 2, 0.5, -self._height / 2)
    main.BackgroundColor3 = theme.background
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = theme.border
    mainStroke.Thickness = 1
    mainStroke.Transparency = 0.4
    mainStroke.Parent = main

    self._main = main

    -- title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.BackgroundColor3 = theme.surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 12)
    titleFix.Position = UDim2.new(0, 0, 1, -12)
    titleFix.BackgroundColor3 = theme.surface
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -190, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = self._title
    title.TextColor3 = theme.text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar

    local version = Instance.new("TextLabel")
    version.Size = UDim2.new(0, 52, 0, 20)
    version.Position = UDim2.new(1, -158, 0.5, -10)
    version.BackgroundColor3 = theme.accent
    version.Text = self._version
    version.TextColor3 = Color3.fromRGB(255, 255, 255)
    version.Font = Enum.Font.GothamBold
    version.TextSize = 10
    version.Parent = titleBar

    local versionCorner = Instance.new("UICorner")
    versionCorner.CornerRadius = UDim.new(0, 5)
    versionCorner.Parent = version

    -- minimise and close buttons
    local minimize = Instance.new("TextButton")
    minimize.Name = "Minimize"
    minimize.Size = UDim2.new(0, 24, 0, 24)
    minimize.Position = UDim2.new(1, -100, 0.5, -12)
    minimize.BackgroundTransparency = 1
    minimize.Text = "-"
    minimize.TextColor3 = theme.textDim
    minimize.Font = Enum.Font.GothamBold
    minimize.TextSize = 16
    minimize.Parent = titleBar

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.Size = UDim2.new(0, 24, 0, 24)
    close.Position = UDim2.new(1, -68, 0.5, -12)
    close.BackgroundTransparency = 1
    close.Text = "x"
    close.TextColor3 = theme.textDim
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.Parent = titleBar

    close.MouseButton1Click:Connect(function()
        self:Close()
    end)

    minimize.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)

    self._titleBar = titleBar

    -- tab strip
    local tabStrip = Instance.new("ScrollingFrame")
    tabStrip.Name = "TabStrip"
    tabStrip.Size = UDim2.new(1, -24, 0, 36)
    tabStrip.Position = UDim2.new(0, 12, 0, 50)
    tabStrip.BackgroundTransparency = 1
    tabStrip.BorderSizePixel = 0
    tabStrip.ScrollBarThickness = 2
    tabStrip.ScrollBarImageColor3 = theme.accent
    tabStrip.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabStrip.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabStrip.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabStrip

    self._tabStrip = tabStrip

    -- content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -24, 1, -96)
    content.Position = UDim2.new(0, 12, 0, 92)
    content.BackgroundColor3 = theme.surface
    content.BorderSizePixel = 0
    content.Parent = main

    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 10)
    contentCorner.Parent = content

    self._content = content

    self:_makeDraggable(titleBar, main)
end

function Window:_makeDraggable(handle, target)
    local dragging = false
    local startPos, startOffset

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = input.Position
            startOffset = target.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local ok, UserInputService = pcall(function()
        return game:GetService("UserInputService")
    end)
    if not ok then
        return
    end

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startPos
            target.Position = UDim2.new(
                startOffset.X.Scale,
                startOffset.X.Offset + delta.X,
                startOffset.Y.Scale,
                startOffset.Y.Offset + delta.Y
            )
        end
    end)
end

-- ── tabs ─────────────────────────────────────────────────────────────────

function Window:AddTab(name)
    local theme = self.Theme

    local button = Instance.new("TextButton")
    button.Name = name
    button.LayoutOrder = #self._tabs + 1
    button.Size = UDim2.new(0, self._tabWidth or 128, 1, 0)
    button.BackgroundColor3 = theme.surface
    button.Text = name
    button.TextColor3 = theme.textDim
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = self._tabStrip

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 7)
    buttonCorner.Parent = button

    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = theme.accent
    page.Visible = false
    page.Parent = self._content

    local pageLayout = Instance.new("UIListLayout")
    pageLayout.Padding = UDim.new(0, 8)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Parent = page

    local pagePadding = Instance.new("UIPadding")
    pagePadding.PaddingTop = UDim.new(0, 14)
    pagePadding.PaddingLeft = UDim.new(0, 14)
    pagePadding.PaddingRight = UDim.new(0, 14)
    pagePadding.PaddingBottom = UDim.new(0, 14)
    pagePadding.Parent = page

    local tab = setmetatable({
        Name = name,
        Button = button,
        Page = page,
        _window = self,
        _container = page,
        _widgets = {},
    }, Tab)

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    table.insert(self._tabs, tab)

    if not self._activeTab then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    if not tab then
        return
    end

    local theme = self.Theme

    for _, other in ipairs(self._tabs) do
        local isActive = (other == tab)
        other.Page.Visible = isActive

        if self.Animations then
            self:Animate(other.Button, {
                BackgroundColor3 = isActive and theme.accent or theme.surface,
                TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or theme.textDim,
            }, 0.18)
        else
            other.Button.BackgroundColor3 = isActive and theme.accent or theme.surface
            other.Button.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or theme.textDim
        end
    end

    self._activeTab = tab
end

function Window:ActiveTab()
    return self._activeTab
end

function Window:Tabs()
    return self._tabs
end

-- ── live refresh ─────────────────────────────────────────────────────────

--- Register a function that is called on every interface refresh.
function Window:AddRefresher(callback)
    table.insert(self._refreshers, callback)
    return function()
        for index = #self._refreshers, 1, -1 do
            if self._refreshers[index] == callback then
                table.remove(self._refreshers, index)
            end
        end
    end
end

function Window:Refresh()
    for _, refresher in ipairs(self._refreshers) do
        pcall(refresher)
    end
end

-- ── appearance ───────────────────────────────────────────────────────────

function Window:SetTheme(themeName, accentName)
    self._themeName = themeName or self._themeName
    self._accentName = accentName or self._accentName
    self.Theme = Theme.Build(self._themeName, self._accentName)
    self:_applyTheme()
end

function Window:_applyTheme()
    local theme = self.Theme

    if self._main then
        self._main.BackgroundColor3 = theme.background
        local stroke = self._main:FindFirstChildOfClass("UIStroke")
        if stroke then
            stroke.Color = theme.border
        end
    end
    if self._titleBar then
        self._titleBar.BackgroundColor3 = theme.surface
    end
    if self._content then
        self._content.BackgroundColor3 = theme.surface
    end

    for _, tab in ipairs(self._tabs) do
        local isActive = (tab == self._activeTab)
        tab.Button.BackgroundColor3 = isActive and theme.accent or theme.surface
        tab.Button.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or theme.textDim
    end
end

function Window:SetAnimations(enabled)
    self._animations = enabled and true or false
    self.Animations = self._animations
end

function Window:SetSize(width, height)
    self._width = width or self._width
    self._height = height or self._height
    if self._main then
        self._main.Size = UDim2.new(0, self._width, 0, self._height)
    end
end

function Window:SetTabWidth(width)
    self._tabWidth = width
    for _, tab in ipairs(self._tabs) do
        tab.Button.Size = UDim2.new(0, width, 1, 0)
    end
end

-- ── behaviour ────────────────────────────────────────────────────────────

function Window:Notify(title, message, kind)
    return self._notify:Show(title, message, kind)
end

function Window:SetNotificationsEnabled(enabled)
    self._notify:SetEnabled(enabled)
end

function Window:Toggle()
    self._visible = not self._visible
    if self._screenGui then
        self._screenGui.Enabled = self._visible
    end
    return self._visible
end

function Window:IsVisible()
    return self._visible
end

function Window:ToggleMinimize()
    self._minimized = not self._minimized
    if self._main then
        self._main.Size = UDim2.new(0, self._width, 0, self._minimized and 42 or self._height)
    end
    return self._minimized
end

function Window:IsMinimized()
    return self._minimized
end

--- Tween helper used by the widgets.
function Window:Animate(instance, properties, duration)
    return Util.tween(instance, properties, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Window:Close()
    self._notify:Destroy()
    if self._screenGui then
        pcall(function()
            self._screenGui:Destroy()
        end)
        self._screenGui = nil
    end
    return true
end

return Window

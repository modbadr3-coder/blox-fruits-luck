--[[
    ui/widgets/stat.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A statistic card: a small title and a large value that can be updated
    every frame.
]]

local Widget = {}

Widget.__index = Widget

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local container = Instance.new("Frame")
    container.Name = "Stat_" .. (options.title or "")
    container.Size = UDim2.new(1, 0, 0, 56)
    container.BackgroundColor3 = theme.surfaceAlt
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 18)
    title.Position = UDim2.new(0, 10, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = options.title or "Stat"
    title.TextColor3 = theme.textDim
    title.Font = Enum.Font.Gotham
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container

    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Size = UDim2.new(1, -20, 0, 24)
    value.Position = UDim2.new(0, 10, 0, 26)
    value.BackgroundTransparency = 1
    value.Text = options.value or "-"
    value.TextColor3 = options.color or theme.accent
    value.Font = Enum.Font.GothamBold
    value.TextSize = 17
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Parent = container

    self.Element = container

    function self:SetValue(newValue)
        value.Text = tostring(newValue)
    end

    function self:SetColor(color)
        value.TextColor3 = color
    end

    function self:GetValue()
        return value.Text
    end

    function self:Destroy()
        pcall(function()
            container:Destroy()
        end)
    end

    return self
end

return Widget

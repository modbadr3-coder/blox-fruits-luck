--[[
    ui/widgets/label.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Static text, optionally with a live value on the right.
]]

local Widget = {}

Widget.__index = Widget

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local container = Instance.new("Frame")
    container.Name = "Label_" .. (options.text or "")
    container.Size = UDim2.new(1, 0, 0, options.height or 22)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0.6, -12, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = options.text or ""
    title.TextColor3 = options.color or theme.textDim
    title.Font = Enum.Font.Gotham
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextWrapped = options.wrap or false
    title.Parent = container

    local value = Instance.new("TextLabel")
    value.Name = "Value"
    value.Size = UDim2.new(0.4, -12, 1, 0)
    value.Position = UDim2.new(0.6, 0, 0, 0)
    value.BackgroundTransparency = 1
    value.Text = options.value or ""
    value.TextColor3 = options.valueColor or theme.text
    value.Font = Enum.Font.GothamBold
    value.TextSize = 12
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.TextWrapped = options.wrap or false
    value.Parent = container

    self.Element = container

    function self:SetValue(newValue)
        value.Text = tostring(newValue)
    end

    function self:GetValue()
        return value.Text
    end

    function self:SetText(newText)
        title.Text = tostring(newText)
    end

    function self:Destroy()
        pcall(function()
            container:Destroy()
        end)
    end

    return self
end

return Widget

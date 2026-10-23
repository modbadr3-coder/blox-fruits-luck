--[[
    ui/widgets/section.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A collapsible group with a header.

    The widgets added to a section are parented to the section's content
    frame, so the whole group can be folded away. A section exposes the
    same Add* methods as a tab page.
]]

local Container = require("ui.container")

local Widget = {}

Widget.__index = function(self, key)
    local method = rawget(Widget, key)
    if method ~= nil then
        return method
    end
    return Container[key]
end

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local container = Instance.new("Frame")
    container.Name = "Section_" .. (options.text or "")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = container

    local header = Instance.new("TextButton")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = theme.surface
    header.Text = ""
    header.BorderSizePixel = 0
    header.AutoButtonColor = false
    header.Parent = container

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 7)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = (options.text or "Section"):upper()
    title.TextColor3 = theme.accent
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local indicator = Instance.new("TextLabel")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 20, 1, 0)
    indicator.Position = UDim2.new(1, -28, 0, 0)
    indicator.BackgroundTransparency = 1
    indicator.Text = "-"
    indicator.TextColor3 = theme.textDim
    indicator.Font = Enum.Font.GothamBold
    indicator.TextSize = 14
    indicator.Parent = header

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 34)
    content.BackgroundTransparency = 1
    content.Parent = container

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 6)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = content

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 8)
    contentPadding.PaddingLeft = UDim.new(0, 2)
    contentPadding.PaddingRight = UDim.new(0, 2)
    contentPadding.PaddingBottom = UDim.new(0, 2)
    contentPadding.Parent = content

    local expanded = options.expanded ~= false

    local function resize()
        local height = 0
        local count = 0
        for _, child in ipairs(content:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIComponent") then
                height = height + (child.Size.Y.Offset or 0)
                count = count + 1
            end
        end
        height = height + math.max(0, (count - 1) * 6)
        content.Size = UDim2.new(1, 0, 0, expanded and math.max(height, 0) or 0)
    end

    header.MouseButton1Click:Connect(function()
        expanded = not expanded
        indicator.Text = expanded and "-" or "+"
        content.Visible = expanded
        resize()
    end)

    indicator.Text = expanded and "-" or "+"
    content.Visible = expanded

    self.Element = container
    self.Content = content
    self._window = window
    self._container = content

    function self:Refresh()
        resize()
    end

    function self:Destroy()
        pcall(function()
            container:Destroy()
        end)
    end

    return self
end

return Widget

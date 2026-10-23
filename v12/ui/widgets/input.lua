--[[
    ui/widgets/input.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A single line text field.
]]

local Widget = {}

Widget.__index = Widget

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local container = Instance.new("Frame")
    container.Name = "Input_" .. (options.text or "")
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundColor3 = theme.surfaceAlt
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -24, 0, 18)
    label.Position = UDim2.new(0, 12, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = options.text or "Input"
    label.TextColor3 = theme.textDim
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local box = Instance.new("TextBox")
    box.Name = "Box"
    box.Size = UDim2.new(1, -24, 0, 24)
    box.Position = UDim2.new(0, 12, 0, 18)
    box.BackgroundTransparency = 1
    box.Text = options.default or ""
    box.PlaceholderText = options.placeholder or "type here..."
    box.PlaceholderColor3 = theme.textDim
    box.TextColor3 = theme.text
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.Parent = container

    local function commit()
        if options.callback then
            local ok, err = pcall(options.callback, box.Text)
            if not ok and window.Logger then
                window.Logger:warn("Input '%s' callback failed: %s", options.text, tostring(err))
            end
        end
    end

    box.FocusLost:Connect(commit)

    self.Element = container

    function self:GetValue()
        return box.Text
    end

    function self:SetValue(text)
        box.Text = text or ""
    end

    function self:Destroy()
        pcall(function()
            container:Destroy()
        end)
    end

    return self
end

return Widget

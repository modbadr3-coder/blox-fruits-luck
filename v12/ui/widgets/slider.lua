--[[
    ui/widgets/slider.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A labelled slider with a numeric readout.
]]

local Widget = {}

Widget.__index = Widget

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local min = options.min or 0
    local max = options.max or 100
    local step = options.step or 1
    local suffix = options.suffix or ""
    local decimals = options.decimals or 0

    local container = Instance.new("Frame")
    container.Name = "Slider_" .. (options.text or "")
    container.Size = UDim2.new(1, 0, 0, 58)
    container.BackgroundColor3 = theme.surfaceAlt
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(0.6, -12, 0, 24)
    label.Position = UDim2.new(0, 12, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = options.text or "Slider"
    label.TextColor3 = theme.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local value = options.default or min
    local readout = Instance.new("TextLabel")
    readout.Name = "Value"
    readout.Size = UDim2.new(0.4, -12, 0, 24)
    readout.Position = UDim2.new(0.6, 0, 0, 6)
    readout.BackgroundTransparency = 1
    readout.Text = ""
    readout.TextColor3 = theme.accent
    readout.Font = Enum.Font.GothamBold
    readout.TextSize = 13
    readout.TextXAlignment = Enum.TextXAlignment.Right
    readout.Parent = container

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 40)
    track.BackgroundColor3 = theme.surface
    track.BorderSizePixel = 0
    track.Parent = container

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = theme.accent
    fill.BorderSizePixel = 0
    fill.Parent = track

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, -8, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local function format(v)
        if decimals > 0 then
            return string.format("%." .. decimals .. "f", v) .. suffix
        end
        return tostring(math.floor(v)) .. suffix
    end

    local function ratio()
        if max <= min then
            return 0
        end
        return (value - min) / (max - min)
    end

    local function paint()
        local r = ratio()
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -8, 0.5, -8)
        readout.Text = format(value)
    end

    local function setValue(newValue, silent)
        newValue = math.floor(newValue / step + 0.5) * step
        newValue = math.max(min, math.min(max, newValue))
        if math.abs(newValue - value) < 0.0001 then
            return
        end
        value = newValue
        paint()

        if not silent and options.callback then
            local ok, err = pcall(options.callback, value)
            if not ok and window.Logger then
                window.Logger:warn("Slider '%s' callback failed: %s", options.text, tostring(err))
            end
        end
    end

    local dragging = false

    local function update(input)
        local width = track.AbsoluteSize.X
        if width <= 0 then
            return
        end
        local relative = (input.Position.X - track.AbsolutePosition.X) / width
        if relative < 0 then relative = 0 elseif relative > 1 then relative = 1 end
        setValue(min + (max - min) * relative)
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

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            update(input)
        end
    end)

    local connections = {}
    local ok, UserInputService = pcall(function()
        return game:GetService("UserInputService")
    end)
    if ok then
        local connection = UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                update(input)
            end
        end)
        table.insert(connections, connection)
    end

    paint()

    self.Element = container
    self._value = value

    function self:GetValue()
        return value
    end

    function self:SetValue(newValue, silent)
        setValue(newValue, silent)
    end

    function self:Destroy()
        for _, connection in ipairs(connections) do
            pcall(function()
                connection:Disconnect()
            end)
        end
        pcall(function()
            container:Destroy()
        end)
    end

    return self
end

return Widget

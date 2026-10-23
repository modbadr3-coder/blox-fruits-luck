--[[
    ui/widgets/toggle.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A labelled on/off switch.
]]

local Widget = {}

Widget.__index = Widget

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. (options.text or "")
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundColor3 = theme.surfaceAlt
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -74, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = options.text or "Toggle"
    label.TextColor3 = theme.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local switch = Instance.new("TextButton")
    switch.Name = "Switch"
    switch.Size = UDim2.new(0, 46, 0, 24)
    switch.Position = UDim2.new(1, -58, 0.5, -12)
    switch.BackgroundColor3 = theme.danger
    switch.Text = ""
    switch.BorderSizePixel = 0
    switch.AutoButtonColor = false
    switch.Parent = container

    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switch

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = options.default and true or false

    local function paint(animated)
        local target = state and theme.success or theme.danger
        local knobTarget = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

        if animated and window.Animations then
            window:Animate(switch, { BackgroundColor3 = target }, 0.18)
            window:Animate(knob, { Position = knobTarget }, 0.18)
        else
            switch.BackgroundColor3 = target
            knob.Position = knobTarget
        end
    end

    switch.MouseButton1Click:Connect(function()
        state = not state
        paint(true)

        if options.callback then
            local ok, err = pcall(options.callback, state)
            if not ok and window.Logger then
                window.Logger:warn("Toggle '%s' callback failed: %s", options.text, tostring(err))
            end
        end
    end)

    paint(false)

    self.Element = container
    self.Switch = switch
    self.Label = label
    self._state = state
    self._options = options

    function self:GetValue()
        return self._state
    end

    function self:SetValue(newValue, silent)
        newValue = newValue and true or false
        if newValue == self._state then
            return
        end
        self._state = newValue
        paint(false)
        if not silent and options.callback then
            pcall(options.callback, newValue)
        end
    end

    function self:Destroy()
        pcall(function()
            container:Destroy()
        end)
    end

    return self
end

return Widget

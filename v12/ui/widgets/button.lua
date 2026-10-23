--[[
    ui/widgets/button.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A styled action button.
]]

local Widget = {}

Widget.__index = Widget

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local style = options.style or "primary"

    local function styleColor()
        if style == "primary" then
            return theme.accent
        elseif style == "danger" then
            return theme.danger
        elseif style == "warning" then
            return theme.warning
        elseif style == "success" then
            return theme.success
        end
        return theme.surface
    end

    local button = Instance.new("TextButton")
    button.Name = "Button_" .. (options.text or "")
    button.Size = UDim2.new(1, 0, 0, 38)
    button.BackgroundColor3 = styleColor()
    button.Text = options.text or "Button"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 13
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    local base = styleColor()

    button.MouseEnter:Connect(function()
        if window.Animations then
            window:Animate(button, { BackgroundColor3 = base:Lerp(Color3.fromRGB(255, 255, 255), 0.18) }, 0.15)
        end
    end)

    button.MouseLeave:Connect(function()
        if window.Animations then
            window:Animate(button, { BackgroundColor3 = base }, 0.15)
        end
    end)

    button.MouseButton1Click:Connect(function()
        if options.callback then
            local ok, err = pcall(options.callback)
            if not ok and window.Logger then
                window.Logger:warn("Button '%s' failed: %s", options.text, tostring(err))
            end
        end
    end)

    self.Element = button

    function self:SetText(text)
        button.Text = text
    end

    function self:SetEnabled(enabled)
        button.AutoButtonColor = enabled and true or false
        button.BackgroundColor3 = enabled and base or theme.surface
        button.TextColor3 = enabled and Color3.fromRGB(255, 255, 255) or theme.textDim
    end

    function self:Destroy()
        pcall(function()
            button:Destroy()
        end)
    end

    return self
end

return Widget

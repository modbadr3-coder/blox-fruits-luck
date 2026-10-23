--[[
    ui/widgets/dropdown.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A dropdown selector with a scrollable option list.
]]

local Widget = {}

Widget.__index = Widget

function Widget.Create(window, parent, options)
    options = options or {}

    local theme = window.Theme
    local self = setmetatable({}, Widget)

    local items = options.options or {}
    local selected = options.default or (items[1] and items[1].name or nil)

    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. (options.text or "")
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundColor3 = theme.surfaceAlt
    container.BorderSizePixel = 0
    container.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = options.text or "Select"
    label.TextColor3 = theme.text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Size = UDim2.new(0, 140, 0, 28)
    button.Position = UDim2.new(1, -152, 0.5, -14)
    button.BackgroundColor3 = theme.surface
    button.Text = tostring(selected or "-")
    button.TextColor3 = theme.text
    button.Font = Enum.Font.GothamSemibold
    button.TextSize = 12
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Parent = container

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = button

    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.TextColor3 = theme.textDim
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 13
    arrow.Parent = button

    -- option list
    local list = Instance.new("ScrollingFrame")
    list.Name = "Options"
    list.Size = UDim2.new(0, 140, 0, 0)
    list.Position = UDim2.new(1, -152, 1, 6)
    list.BackgroundColor3 = theme.surface
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = theme.accent
    list.Visible = false
    list.ZIndex = 10
    list.Parent = container

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 6)
    listCorner.Parent = list

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 4)
    listPadding.PaddingBottom = UDim.new(0, 4)
    listPadding.Parent = list

    local optionButtons = {}

    local function close()
        list.Visible = false
        arrow.Text = "v"
    end

    local function open()
        list.Visible = true
        arrow.Text = "^"
    end

    local function select(item)
        selected = item.name
        button.Text = item.name
        close()
        if options.callback then
            local ok, err = pcall(options.callback, item.name, item)
            if not ok and window.Logger then
                window.Logger:warn("Dropdown '%s' callback failed: %s", options.text, tostring(err))
            end
        end
    end

    for index, item in ipairs(items) do
        local entry = item
        if type(entry) == "string" then
            entry = { name = entry }
        end

        local optionButton = Instance.new("TextButton")
        optionButton.Name = entry.name
        optionButton.LayoutOrder = index
        optionButton.Size = UDim2.new(1, -6, 0, 26)
        optionButton.BackgroundColor3 = theme.surface
        optionButton.Text = entry.name
        optionButton.TextColor3 = theme.textDim
        optionButton.Font = Enum.Font.Gotham
        optionButton.TextSize = 12
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.BorderSizePixel = 0
        optionButton.AutoButtonColor = false
        optionButton.ZIndex = 11
        optionButton.Parent = list

        local optionCorner = Instance.new("UICorner")
        optionCorner.CornerRadius = UDim.new(0, 4)
        optionCorner.Parent = optionButton

        optionButton.MouseButton1Click:Connect(function()
            select(entry)
        end)

        optionButton.MouseEnter:Connect(function()
            optionButton.BackgroundColor3 = theme.accent
            optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        end)

        optionButton.MouseLeave:Connect(function()
            optionButton.BackgroundColor3 = theme.surface
            optionButton.TextColor3 = theme.textDim
        end)

        table.insert(optionButtons, optionButton)
    end

    local function resize()
        local count = math.min(#optionButtons, 8)
        list.Size = UDim2.new(0, 140, 0, count * 28)
    end
    resize()

    button.MouseButton1Click:Connect(function()
        if list.Visible then
            close()
        else
            open()
        end
    end)

    self.Element = container
    self.List = list

    function self:GetValue()
        return selected
    end

    function self:SetValue(name, silent)
        for _, item in ipairs(items) do
            local entry = item
            if type(entry) == "string" then
                entry = { name = entry }
            end
            if entry.name == name then
                selected = name
                button.Text = name
                if not silent and options.callback then
                    pcall(options.callback, name, entry)
                end
                return true
            end
        end
        return false
    end

    function self:SetOptions(newItems)
        items = newItems or {}
    end

    function self:Destroy()
        pcall(function()
            container:Destroy()
        end)
    end

    return self
end

return Widget

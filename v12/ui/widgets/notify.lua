--[[
    ui/widgets/notify.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Toast notifications.

    The toast layer lives in its own ScreenGui so it survives the main
    window being closed, and toasts clean themselves up.
]]

local Widget = {}

Widget.__index = Widget

Widget.KINDS = {
    info = "accent",
    success = "success",
    warning = "warning",
    error = "danger",
}

function Widget.New(options)
    options = options or {}

    local self = setmetatable({
        _logger = options.logger,
        _screenGui = nil,
        _toasts = {},
        _enabled = true,
        _maxToasts = options.maxToasts or 4,
        _duration = options.duration or 3.5,
    }, Widget)

    return self
end

function Widget:SetEnabled(enabled)
    self._enabled = enabled and true or false
end

function Widget:_createScreenGui()
    if self._screenGui then
        return self._screenGui
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BFS_Toasts_" .. tostring(math.random(100000, 999999))
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 1000
    screenGui.IgnoreGuiInset = true
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
    return screenGui
end

--- Show a toast.
--- kind: "info" | "success" | "warning" | "error"
function Widget:Show(title, message, kind)
    if not self._enabled then
        return nil
    end

    self:_createScreenGui()
    if not self._screenGui then
        return nil
    end

    local theme = require("ui.theme").Build("midnight", "cyan")
    local colorKey = Widget.KINDS[kind or "info"] or "accent"
    local color = theme[colorKey] or theme.accent

    local holder = Instance.new("Frame")
    holder.Name = "Toast"
    holder.Size = UDim2.new(0, 300, 0, 58)
    holder.Position = UDim2.new(1, -312, 0, -20)
    holder.BackgroundColor3 = theme.surface
    holder.BackgroundTransparency = 0.05
    holder.BorderSizePixel = 0
    holder.Parent = self._screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = holder

    local stroke = Instance.new("Frame")
    stroke.Size = UDim2.new(0, 4, 1, 0)
    stroke.BackgroundColor3 = color
    stroke.BorderSizePixel = 0
    stroke.Parent = holder

    local strokeCorner = Instance.new("UICorner")
    strokeCorner.CornerRadius = UDim.new(0, 2)
    strokeCorner.Parent = stroke

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -24, 0, 20)
    titleLabel.Position = UDim2.new(0, 14, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(title or "")
    titleLabel.TextColor3 = theme.text
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = holder

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -24, 0, 26)
    messageLabel.Position = UDim2.new(0, 14, 0, 28)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = tostring(message or "")
    messageLabel.TextColor3 = theme.textDim
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextSize = 11
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextWrapped = true
    messageLabel.Parent = holder

    -- stack the toasts
    local index = #self._toasts
    for _, toast in ipairs(self._toasts) do
        toast.holder:Destroy()
    end
    self._toasts = {}

    local offset = 0
    for _, toast in ipairs(self._toasts) do
        offset = offset + 62
    end
    index = 0

    -- position the new toast
    holder.Position = UDim2.new(1, -312, 0, -20 + offset)

    local ok, TweenService = pcall(function()
        return game:GetService("TweenService")
    end)
    if ok then
        pcall(function()
            TweenService:Create(holder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(1, -312, 0, 14 + offset),
            }):Play()
        end)
    end

    local toast = { holder = holder, title = titleLabel, message = messageLabel }
    table.insert(self._toasts, toast)

    -- remove the oldest when there are too many
    while #self._toasts > self._maxToasts do
        local oldest = table.remove(self._toasts, 1)
        pcall(function()
            oldest.holder:Destroy()
        end)
    end

    -- auto dismiss
    task.delay(self._duration, function()
        if ok then
            pcall(function()
                TweenService:Create(holder, TweenInfo.new(0.2), {
                    Position = UDim2.new(1, -312, 0, -20),
                    BackgroundTransparency = 1,
                }):Play()
            end)
        end
        task.wait(0.25)
        pcall(function()
            holder:Destroy()
        end)
        for index = #self._toasts, 1, -1 do
            if self._toasts[index].holder == holder then
                table.remove(self._toasts, index)
            end
        end
    end)

    return toast
end

function Widget:Destroy()
    for _, toast in ipairs(self._toasts) do
        pcall(function()
            toast.holder:Destroy()
        end)
    end
    self._toasts = {}
    if self._screenGui then
        pcall(function()
            self._screenGui:Destroy()
        end)
        self._screenGui = nil
    end
end

return Widget

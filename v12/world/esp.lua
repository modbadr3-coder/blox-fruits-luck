--[[
    world/esp.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The ESP overlay.

    Every tracked entity gets a BillboardGui with a label, and optionally a
    Highlight so the model itself is tinted. The overlay lives in its own
    ScreenGui so it can be toggled without touching the main interface.

    The overlay is rebuilt from the scanner's buckets rather than patched
    in place, which keeps it simple and correct at the cost of recreating
    the billboards on every refresh. With the default cap of 150 objects
    that is cheap enough to do a few times a second.
]]

local Util = require("core.util")

local Esp = {}

Esp.__index = Esp

function Esp.new(options)
    options = options or {}

    local self = setmetatable({
        _logger = options.logger,
        _cleanup = options.cleanup,
        _screenGui = nil,
        _enabled = false,
        _maxObjects = options.maxObjects or 150,
        _showLabel = true,
        _showDistance = true,
        _useHighlight = true,
        _billboards = {},
        _highlights = {},
    }, Esp)

    return self
end

function Esp:_createScreenGui()
    if self._screenGui then
        return self._screenGui
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BFS_ESP_" .. tostring(math.random(100000, 999999))
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 900
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

    if self._cleanup then
        self._cleanup:trackInstance(screenGui, "esp-gui")
    end

    return screenGui
end

function Esp:SetEnabled(enabled)
    self._enabled = enabled and true or false

    if not self._enabled then
        self:Clear()
        return
    end

    self:_createScreenGui()
    if self._screenGui then
        self._screenGui.Enabled = true
    end
end

function Esp:IsEnabled()
    return self._enabled
end

function Esp:SetMaxObjects(max)
    self._maxObjects = math.max(1, tonumber(max) or 150)
end

function Esp:SetShowLabel(show)
    self._showLabel = show and true or false
end

function Esp:SetShowDistance(show)
    self._showDistance = show and true or false
end

function Esp:SetUseHighlight(use)
    self._useHighlight = use and true or false
end

--- Remove every billboard and highlight.
function Esp:Clear()
    for _, billboard in ipairs(self._billboards) do
        pcall(function()
            billboard:Destroy()
        end)
    end
    for _, highlight in ipairs(self._highlights) do
        pcall(function()
            highlight:Destroy()
        end)
    end
    self._billboards = {}
    self._highlights = {}
end

function Esp:_makeBillboard(entity, label, distance, color)
    local instance = entity.instance
    if not Util.isInstance(instance) then
        return nil
    end

    -- attach to the part so the label follows the model
    local anchor = instance
    if Util.isInstance(instance, "Model") then
        local ok, part = pcall(function()
            return instance:FindFirstChildWhichIsA("BasePart")
        end)
        if ok and part then
            anchor = part
        end
    end

    if not Util.isInstance(anchor, "BasePart") then
        return nil
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BFS_Label"
    billboard.Adornee = anchor
    billboard.Size = UDim2.new(0, 220, 0, 26)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 4000
    billboard.Parent = self._screenGui

    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = label
    text.TextColor3 = color
    text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    text.TextStrokeTransparency = 0.35
    text.Font = Enum.Font.GothamBold
    text.TextSize = 13
    text.TextScaled = false
    text.TextWrapped = false
    text.Parent = billboard

    return billboard
end

function Esp:_makeHighlight(entity, color)
    local instance = entity.instance
    if not Util.isInstance(instance) then
        return nil
    end

    local ok, highlight = pcall(function()
        local h = Instance.new("Highlight")
        h.Adornee = instance
        h.FillColor = color
        h.FillTransparency = 0.75
        h.OutlineColor = color
        h.OutlineTransparency = 0.1
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = self._screenGui
        return h
    end)

    if not ok then
        return nil
    end
    return highlight
end

--- Refresh the overlay from a list of entities.
--- `entries` is an array of { entity = entity, label = string, distance = number }
function Esp:Render(entries, options)
    if not self._enabled then
        return 0
    end

    self:_createScreenGui()
    self:Clear()

    if not self._screenGui then
        return 0
    end

    options = options or {}
    local labelBuilder = options.labelBuilder
    local colorBuilder = options.colorBuilder

    local rendered = 0
    for _, entry in ipairs(entries or {}) do
        if rendered >= self._maxObjects then
            break
        end

        local entity = entry.entity
        if entity and Util.isInstance(entity.instance) and entity.instance.Parent then
            local distance = entry.distance
            local label
            if labelBuilder then
                label = labelBuilder(entity, distance)
            else
                label = entry.label or entity.name or "?"
            end

            if self._showDistance and distance then
                label = label .. string.format("  [%d]", math.floor(distance))
            end

            local color = colorBuilder and colorBuilder(entity) or Color3.fromRGB(255, 255, 255)

            local billboard = self:_makeBillboard(entity, label, distance, color)
            if billboard then
                table.insert(self._billboards, billboard)
                rendered = rendered + 1
            end

            if self._useHighlight then
                local highlight = self:_makeHighlight(entity, color)
                if highlight then
                    table.insert(self._highlights, highlight)
                end
            end
        end
    end

    return rendered
end

function Esp:Count()
    return #self._billboards
end

function Esp:Destroy()
    self:Clear()
    if self._screenGui then
        pcall(function()
            self._screenGui:Destroy()
        end)
        self._screenGui = nil
    end
end

return Esp

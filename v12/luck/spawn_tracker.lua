--[[
    luck/spawn_tracker.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Observes the fruit that actually spawns in the world.

    The tracker walks the live workspace on an interval, looks for fruit
    models, and works out which fruit it is. Every new fruit is recorded
    with a timestamp, which gives the suite something the v11 build never
    had: a real, measured picture of how the spawns are distributed on
    *this* server, and a luck rating based on real results instead of on
    a simulation.

    Fruit models in Blox Fruits are not standardised, so the name is
    recovered in several ways and the first one that works wins:
        1. an attribute (FruitName / Name / Fruit / Rarity)
        2. a StringValue child
        3. a child model named after a known fruit
        4. the model's own name matched against the fruit database
]]

local Fruits = require("data.fruits")
local Rarity = require("luck.rarity")
local Util = require("core.util")

local SpawnTracker = {}

SpawnTracker.__index = SpawnTracker

-- Attribute names the game has used over time.
local NAME_ATTRIBUTES = { "FruitName", "Fruit", "Name", "DisplayName", "Rarity" }

--- A stable identifier for an instance. GetDebugId is not available in
--- every environment, so the instance itself is the fallback.
function SpawnTracker.DebugId(instance)
    local ok, id = pcall(function()
        return instance:GetDebugId()
    end)
    if ok and id then
        return tostring(id)
    end
    return tostring(instance)
end

function SpawnTracker.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _engine = options.engine,
        _scanInterval = options.scanInterval or 2.0,
        _active = {},
        _seen = {},
        _history = {},
        _maxHistory = options.maxHistory or 100,
        _lastScan = 0,
        _scanCount = 0,
        _root = options.root,
    }, SpawnTracker)
end

function SpawnTracker:Start()
    if self._root == nil then
        local ok, Players = pcall(function()
            return game:GetService("Players")
        end)
        if not ok then
            return false
        end
        local okPlayer, player = pcall(function()
            return Players.LocalPlayer
        end)
        if okPlayer and player then
            self._root = player:FindFirstChild("Character")
        end
    end
    return true
end

function SpawnTracker:_getWorkspace()
    if self._workspace then
        return self._workspace
    end
    local ok, workspace = pcall(function()
        return game:GetService("Workspace")
    end)
    if ok then
        self._workspace = workspace
    end
    return self._workspace
end

--- Extract a fruit record from an instance, or nil.
function SpawnTracker:Identify(instance)
    if not Util.isInstance(instance) then
        return nil
    end

    -- 1. attributes
    for _, attributeName in ipairs(NAME_ATTRIBUTES) do
        local ok, value = pcall(function()
            return instance:GetAttribute(attributeName)
        end)
        if ok and type(value) == "string" then
            local record = Fruits.Resolve(value)
            if record then
                return record
            end
        end
    end

    -- 2. StringValue children
    for _, child in ipairs(instance:GetChildren()) do
        if Util.isInstance(child, "StringValue") then
            local record = Fruits.Resolve(child.Value)
            if record then
                return record
            end
        end
    end

    -- 3. child models named after a fruit
    for _, child in ipairs(instance:GetChildren()) do
        if Util.isInstance(child, "Model") then
            local record = Fruits.Resolve(child.Name)
            if record then
                return record
            end
        end
    end

    -- 4. the instance name itself
    local record = Fruits.Resolve(instance.Name)
    if record then
        return record
    end

    return nil
end

--- True when an instance looks like a fruit model.
function SpawnTracker:LooksLikeFruit(instance)
    if not Util.isInstance(instance) then
        return false
    end

    local name = string.lower(instance.Name or "")
    if name:find("fruit", 1, true) then
        return true
    end

    -- some spawns are named after the fruit directly
    return Fruits.Resolve(instance.Name) ~= nil
end

--- Scan the workspace once and return the list of live fruit spawns.
function SpawnTracker:Scan()
    local workspace = self:_getWorkspace()
    if not workspace then
        return {}
    end

    local found = {}
    local seen = {}

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if Util.isInstance(descendant) and self:LooksLikeFruit(descendant) then
            local record = self:Identify(descendant)
            if record then
                local entry = {
                    instance = descendant,
                    fruit = record.name,
                    rarity = record.rarity,
                    type = record.type,
                    position = descendant.Position,
                    instanceId = SpawnTracker.DebugId(descendant),
                }
                found[#found + 1] = entry
                seen[entry.instanceId] = true

                if not self._seen[entry.instanceId] then
                    self._seen[entry.instanceId] = true
                    self:_onNewSpawn(entry)
                end
            end
        end
    end

    -- forget spawns that are gone
    for id in pairs(self._seen) do
        if not seen[id] then
            self._seen[id] = nil
        end
    end

    self._active = found
    self._scanCount = self._scanCount + 1
    self._lastScan = os.clock()

    return found
end

function SpawnTracker:_onNewSpawn(entry)
    local event = {
        fruit = entry.fruit,
        rarity = entry.rarity,
        rank = Rarity.Rank(entry.rarity),
        type = entry.type,
        timestamp = os.time(),
        source = "spawn",
    }

    table.insert(self._history, event)
    while #self._history > self._maxHistory do
        table.remove(self._history, 1)
    end

    if self._engine then
        self._engine:RecordExternal(event)
    end

    if self._logger then
        self._logger:info("Fruit spawn observed: %s (%s)", entry.fruit, entry.rarity)
    end

    if self._onSpawn then
        self._onSpawn(event)
    end
end

--- Register a callback fired whenever a new fruit spawns.
function SpawnTracker:OnSpawn(callback)
    self._onSpawn = callback
end

function SpawnTracker:Active()
    return self._active
end

function SpawnTracker:History()
    return self._history
end

function SpawnTracker:ScanCount()
    return self._scanCount
end

--- Observed rarity distribution of real spawns.
function SpawnTracker:Distribution()
    local counts = {}
    for _, rarity in ipairs(Rarity.Order) do
        counts[rarity] = 0
    end

    local total = 0
    for _, event in ipairs(self._history) do
        counts[event.rarity] = (counts[event.rarity] or 0) + 1
        total = total + 1
    end

    local out = {}
    for _, rarity in ipairs(Rarity.Order) do
        out[rarity] = {
            count = counts[rarity],
            percent = total > 0 and (counts[rarity] / total) * 100 or 0,
        }
    end
    return out
end

function SpawnTracker:Reset()
    self._history = {}
    self._seen = {}
    self._active = {}
end

return SpawnTracker

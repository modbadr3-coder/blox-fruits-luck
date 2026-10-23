--[[
    luck/gacha_tracker.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Observes the results the game sends to the client.

    When the Blox Fruit Gacha resolves, the server pushes the outcome to
    the client over a RemoteEvent. This tracker listens on the remote
    events it can find and inspects the payload for a fruit name, which
    gives a truthful record of what the gacha actually produced.

    The payload shape changes between game updates, so the matcher is
    deliberately forgiving: any argument (string or table) is searched for
    a known fruit name, and the deepest match wins.
]]

local Fruits = require("data.fruits")
local Rarity = require("luck.rarity")
local Util = require("core.util")

local GachaTracker = {}

GachaTracker.__index = GachaTracker

-- Remote names that have carried gacha results in the past.
local CANDIDATE_REMOTE_NAMES = {
    "Gacha", "FruitGacha", "GachaResult", "GachaRoll", "PurchaseFruits",
    "FruitPurchase", "RandomFruits", "BuyFruit", "FruitResult",
}

--- A stable identifier for an instance (GetDebugId is not always there).
local function DebugId(instance)
    local ok, id = pcall(function()
        return instance:GetDebugId()
    end)
    if ok and id then
        return tostring(id)
    end
    return tostring(instance)
end

function GachaTracker.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _engine = options.engine,
        _history = {},
        _maxHistory = options.maxHistory or 100,
        _connections = {},
        _active = false,
        _listenedRemotes = {},
    }, GachaTracker)
end

--- Walk a payload and return the most specific fruit record found.
function GachaTracker:MatchPayload(payload, depth)
    depth = depth or 0
    if depth > 3 then
        return nil
    end

    if type(payload) == "string" then
        return Fruits.Resolve(payload)
    end

    if type(payload) ~= "table" then
        return nil
    end

    -- direct table fields first
    for _, key in ipairs({ "Fruit", "FruitName", "Name", "Rarity", "Reward", "Item" }) do
        local value = payload[key]
        if type(value) == "string" then
            local record = Fruits.Resolve(value)
            if record then
                return record
            end
        end
    end

    for _, value in pairs(payload) do
        if type(value) == "table" then
            local record = self:MatchPayload(value, depth + 1)
            if record then
                return record
            end
        elseif type(value) == "string" then
            local record = Fruits.Resolve(value)
            if record then
                return record
            end
        end
    end

    return nil
end

function GachaTracker:_handle(remoteName, ...)
    local record = self:MatchPayload({ ... })
    if not record then
        return
    end

    local event = {
        fruit = record.name,
        rarity = record.rarity,
        rank = Rarity.Rank(record.rarity),
        type = record.type,
        timestamp = os.time(),
        source = "gacha",
        remote = remoteName,
    }

    table.insert(self._history, event)
    while #self._history > self._maxHistory do
        table.remove(self._history, 1)
    end

    if self._engine then
        self._engine:RecordExternal(event)
    end

    if self._logger then
        self._logger:info("Gacha result observed: %s (%s) via %s", event.fruit, event.rarity, remoteName)
    end

    if self._onResult then
        self._onResult(event)
    end
end

function GachaTracker:OnResult(callback)
    self._onResult = callback
end

function GachaTracker:Start()
    if self._active then
        return false
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return false
    end

    local connected = 0

    for _, descendant in ipairs(replicatedStorage:GetDescendants()) do
        if Util.isInstance(descendant, "RemoteEvent") then
            local lowered = string.lower(descendant.Name)
            local interesting = false
            for _, candidate in ipairs(CANDIDATE_REMOTE_NAMES) do
                if lowered:find(candidate:lower(), 1, true) then
                    interesting = true
                    break
                end
            end

            if interesting and not self._listenedRemotes[DebugId(descendant)] then
                local connection
                connection = descendant.OnClientEvent:Connect(function(...)
                    self:_handle(descendant.Name, ...)
                end)
                table.insert(self._connections, connection)
                connected = connected + 1
            end
        end
    end

    self._active = true

    if self._logger then
        self._logger:debug("Gacha tracker listening on %d remote(s)", connected)
    end

    return true
end

function GachaTracker:Stop()
    for _, connection in ipairs(self._connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    self._connections = {}
    self._active = false
end

function GachaTracker:IsActive()
    return self._active
end

function GachaTracker:History()
    return self._history
end

function GachaTracker:Reset()
    self._history = {}
end

return GachaTracker

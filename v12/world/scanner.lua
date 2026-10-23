--[[
    world/scanner.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    One pass over the workspace, classified into buckets.

    The scan is the expensive part (a Blox Fruits workspace holds tens of
    thousands of descendants), so the scanner runs on an interval rather
    than every frame, keeps a registry of the instances it has seen, and
    exposes the buckets as plain arrays.
]]

local Entity = require("world.entity")
local Util = require("core.util")

local Scanner = {}

Scanner.__index = Scanner

function Scanner.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _scanInterval = options.scanInterval or 2.0,
        _buckets = {
            fruit = {},
            mob = {},
            boss = {},
            chest = {},
            npc = {},
        },
        _registry = {},
        _scanCount = 0,
        _lastScan = 0,
        _lastDuration = 0,
        _maxRegistry = 4000,
    }, Scanner)
end

function Scanner:_workspace()
    local ok, workspace = pcall(function()
        return game:GetService("Workspace")
    end)
    if ok then
        return workspace
    end
    return nil
end

--- Run a scan. Returns the buckets.
function Scanner:Scan()
    local workspace = self:_workspace()
    if not workspace then
        return self._buckets
    end

    local startTime = os.clock()

    local buckets = {
        fruit = {},
        mob = {},
        boss = {},
        chest = {},
        npc = {},
    }

    local registry = {}
    local classifier = Entity

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if Util.isInstance(descendant) then
            local className = Util.getClass(descendant)
            -- skip the parts that make up a character, they are not targets
            if className ~= "Accessory" and className ~= "BodyPart" then
                local entity = classifier:Classify(descendant)
                if entity then
                    local bucket = buckets[entity.kind]
                    if bucket then
                        entity.instance = descendant
                        entity.position = descendant.Position
                        bucket[#bucket + 1] = entity
                    end
                end
            end
        end
    end

    self._buckets = buckets
    self._registry = registry
    self._scanCount = self._scanCount + 1
    self._lastScan = os.clock()
    self._lastDuration = self._lastScan - startTime

    if self._logger then
        self._logger:debug("Scan finished in %.1f ms (%d fruits, %d mobs, %d chests, %d npcs)",
            self._lastDuration * 1000,
            #buckets.fruit, #buckets.mob, #buckets.chest, #buckets.npc)
    end

    return buckets
end

function Scanner:Buckets()
    return self._buckets
end

function Scanner:Fruits()
    return self._buckets.fruit
end

function Scanner:Mobs()
    return self._buckets.mob
end

function Scanner:Bosses()
    return self._buckets.boss
end

function Scanner:Chests()
    return self._buckets.chest
end

function Scanner:NPCs()
    return self._buckets.npc
end

function Scanner:ScanCount()
    return self._scanCount
end

function Scanner:LastDuration()
    return self._lastDuration
end

--- Distance of every entity in a bucket from the local player, sorted
--- from nearest to furthest.
function Scanner:SortedByDistance(bucketName, playerRoot)
    local list = self._buckets[bucketName]
    if not list then
        return {}
    end

    local origin = playerRoot and playerRoot.Position or Vector3.new(0, 0, 0)

    local copy = {}
    for index = 1, #list do
        copy[index] = list[index]
    end

    table.sort(copy, function(a, b)
        local da = (a.position - origin).Magnitude
        local db = (b.position - origin).Magnitude
        return da < db
    end)

    return copy
end

return Scanner

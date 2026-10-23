--[[
    luck/drop_table.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    A generic weighted drop table with optional pity progress.

    The table keeps a running total of rolls and can be asked for the
    chance of the next roll, which is what a "pity" system needs.
]]

local Rng = require("luck.rng")

local DropTable = {}

DropTable.__index = DropTable

--- entries: array of { name = string, weight = number, ...payload }
function DropTable.new(entries, options)
    options = options or {}

    local self = setmetatable({
        _entries = {},
        _total = 0,
        _rolls = 0,
        _pity = 0,
        _pityTarget = options.pityTarget or 0,
        _history = {},
        _maxHistory = options.maxHistory or 100,
    }, DropTable)

    for _, entry in ipairs(entries or {}) do
        self:Add(entry)
    end

    return self
end

function DropTable:Add(entry)
    if type(entry) ~= "table" or type(entry.name) ~= "string" then
        return false
    end
    entry.weight = tonumber(entry.weight) or 0
    table.insert(self._entries, entry)
    self._total = self._total + entry.weight
    return true
end

function DropTable:Remove(name)
    for index = #self._entries, 1, -1 do
        if self._entries[index].name == name then
            self._total = self._total - self._entries[index].weight
            table.remove(self._entries, index)
            return true
        end
    end
    return false
end

function DropTable:SetWeight(name, weight)
    weight = tonumber(weight) or 0
    for _, entry in ipairs(self._entries) do
        if entry.name == name then
            self._total = self._total - entry.weight + weight
            entry.weight = weight
            return true
        end
    end
    return false
end

function DropTable:Entries()
    return self._entries
end

function DropTable:Total()
    return self._total
end

function DropTable:Count()
    return #self._entries
end

function DropTable:Rolls()
    return self._rolls
end

--- Percentage chance for a specific entry.
function DropTable:Chance(name)
    if self._total <= 0 then
        return 0
    end
    for _, entry in ipairs(self._entries) do
        if entry.name == name then
            return (entry.weight / self._total) * 100
        end
    end
    return 0
end

--- Percentage chance of rolling any of the given names.
function DropTable:ChanceOfAny(names)
    if self._total <= 0 then
        return 0
    end
    local weight = 0
    for _, name in ipairs(names) do
        for _, entry in ipairs(self._entries) do
            if entry.name == name then
                weight = weight + entry.weight
            end
        end
    end
    return (weight / self._total) * 100
end

--- Roll one entry.
function DropTable:Roll(generator)
    generator = generator or Rng.new()

    if self._total <= 0 or #self._entries == 0 then
        return nil
    end

    local roll = generator:NextFloat() * self._total
    local running = 0
    local picked = self._entries[#self._entries]

    for _, entry in ipairs(self._entries) do
        running = running + entry.weight
        if roll <= running then
            picked = entry
            break
        end
    end

    self._rolls = self._rolls + 1
    self._pity = self._pity + 1

    table.insert(self._history, picked.name)
    if #self._history > self._maxHistory then
        table.remove(self._history, 1)
    end

    return picked
end

--- Reset the roll counter and the pity progress.
function DropTable:Reset()
    self._rolls = 0
    self._pity = 0
    self._history = {}
end

function DropTable:History()
    return self._history
end

--- Number of rolls since the last "target" entry was hit.
function DropTable:Pity(targetName)
    if targetName then
        for index = #self._history, 1, -1 do
            if self._history[index] == targetName then
                return index
            end
        end
        return #self._history
    end
    return self._pity
end

--- Pity progress towards the target (0..1).
function DropTable:PityProgress(targetName, targetCount)
    targetCount = targetCount or 1
    if self._pityTarget <= 0 then
        return 0
    end
    local progress = self:Pity(targetName) / (self._pityTarget * targetCount)
    if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end
    return progress
end

return DropTable

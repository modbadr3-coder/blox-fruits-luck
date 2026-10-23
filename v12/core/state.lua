--[[
    core/state.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Reactive key/value store.

    Every module reads configuration through this store instead of keeping
    its own copies, so a change in the UI is instantly visible everywhere
    and the settings file is a straight serialisation of the store.

        local State = require("core.state")
        State:set("luck.multiplier", 3)
        State:get("luck.multiplier")        --> 3
        State:onChange("luck.multiplier", function(value, old) ... end)
]]

local Util = require("core.util")

local State = {}

State.__index = State

function State.new(defaults)
    return setmetatable({
        _values = Util.deepCopy(defaults or {}),
        _subscribers = {},
    }, State)
end

--- Read a value using a dotted path ("luck.multiplier").
function State:get(path, fallback)
    local value = Util.pathGet(self._values, path)
    if value == nil then
        return fallback
    end
    return value
end

--- Write a value using a dotted path. Returns the stored value.
function State:set(path, value)
    local old = Util.pathGet(self._values, path)
    if old == value then
        return value
    end

    Util.pathSet(self._values, path, value)
    self:_notify(path, value, old)
    return value
end

--- Toggle a boolean path.
function State:toggle(path)
    local newValue = not self:get(path, false)
    self:set(path, newValue)
    return newValue
end

--- Increment a numeric path.
function State:increment(path, amount)
    local newValue = (self:get(path, 0) or 0) + (amount or 1)
    self:set(path, newValue)
    return newValue
end

--- Subscribe to a path. A path of "*" listens to every change.
--- Returns a disconnect function.
function State:onChange(path, callback)
    if type(callback) ~= "function" then
        return function() end
    end

    self._subscribers[path] = self._subscribers[path] or {}
    local handle = { path = path, callback = callback, active = true }
    table.insert(self._subscribers[path], handle)

    return function()
        handle.active = false
    end
end

function State:_notify(path, value, old)
    local exact = self._subscribers[path]
    if exact then
        for i = 1, #exact do
            if exact[i].active then
                pcall(exact[i].callback, value, old, path)
            end
        end
    end

    -- parent paths also fire, e.g. setting "luck.multiplier" notifies "luck"
    local parent = path:match("^(.*)%.[^%.]+$")
    while parent do
        local list = self._subscribers[parent]
        if list then
            for i = 1, #list do
                if list[i].active then
                    pcall(list[i].callback, Util.pathGet(self._values, parent), old, parent)
                end
            end
        end
        parent = parent:match("^(.*)%.[^%.]+$")
    end

    local wildcards = self._subscribers["*"]
    if wildcards then
        for i = 1, #wildcards do
            if wildcards[i].active then
                pcall(wildcards[i].callback, value, old, path)
            end
        end
    end
end

--- Snapshot of the whole store (a deep copy).
function State:snapshot()
    return Util.deepCopy(self._values)
end

--- Replace the whole store. `merge` keeps existing keys that are absent
--- from the new table.
function State:replace(values, merge)
    if merge then
        Util.deepMerge(self._values, values)
    else
        self._values = Util.deepCopy(values or {})
    end
    self:_notify("*", self._values, nil)
    return self._values
end

--- Merge a table into the store path by path.
function State:merge(values)
    for key, value in pairs(values or {}) do
        self:set(key, value)
    end
end

function State:clearSubscribers()
    self._subscribers = {}
end

return State

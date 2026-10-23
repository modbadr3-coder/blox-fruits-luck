--[[
    core/events.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Minimal, allocation-friendly event bus.

    * on()     -> disconnect handle
    * once()   -> fires a single time
    * off()    -> remove by handle or by (event, callback) pair
    * emit()   -> synchronous dispatch, never errors out on a bad listener
]]

local Events = {}

Events.__index = Events

function Events.new()
    return setmetatable({
        _handlers = {},
        _wildcard = {},
        _muted = false,
    }, Events)
end

--- Register a listener. Returns a function that removes the listener.
function Events:on(eventName, callback)
    if type(eventName) ~= "string" or type(callback) ~= "function" then
        return function() end
    end

    self._handlers[eventName] = self._handlers[eventName] or {}
    local handle = { event = eventName, callback = callback, active = true }
    table.insert(self._handlers[eventName], handle)

    return function()
        handle.active = false
    end
end

--- Register a listener that is removed after its first invocation.
function Events:once(eventName, callback)
    local disconnect
    disconnect = self:on(eventName, function(...)
        disconnect()
        callback(...)
    end)
    return disconnect
end

--- Remove a listener. Pass a handle returned by on(), or (event, callback).
function Events:off(eventName, target)
    if type(target) == "function" then
        local list = self._handlers[eventName]
        if not list then
            return false
        end
        for i = #list, 1, -1 do
            if list[i].callback == target or list[i].active == false then
                table.remove(list, i)
            end
        end
        return true
    end

    if type(target) == "table" then
        target.active = false
        return true
    end

    return false
end

--- Fire an event. Listener errors are swallowed so one bad listener cannot
--- break the emit loop (and therefore the whole suite).
function Events:emit(eventName, ...)
    if self._muted then
        return
    end

    local list = self._handlers[eventName]
    if list then
        -- iterate over a copy: listeners may disconnect themselves
        local snapshot = {}
        for i = 1, #list do
            snapshot[i] = list[i]
        end

        for i = 1, #snapshot do
            local handle = snapshot[i]
            if handle.active then
                pcall(handle.callback, ...)
            end
        end

        -- prune dead handles
        for i = #list, 1, -1 do
            if not list[i].active then
                table.remove(list, i)
            end
        end
    end

    if #self._wildcard > 0 then
        for i = 1, #self._wildcard do
            local handle = self._wildcard[i]
            if handle.active then
                pcall(handle.callback, eventName, ...)
            end
        end
    end
end

--- Listen to every event. Callback receives (eventName, ...).
function Events:onAny(callback)
    if type(callback) ~= "function" then
        return function() end
    end
    local handle = { callback = callback, active = true }
    table.insert(self._wildcard, handle)
    return function()
        handle.active = false
    end
end

--- Temporarily suppress dispatch (used while tearing the suite down).
function Events:muted(shouldMute)
    if shouldMute == nil then
        return self._muted
    end
    self._muted = shouldMute
    return self._muted
end

--- Drop every registered listener.
function Events:clear()
    self._handlers = {}
    self._wildcard = {}
end

--- Number of listeners currently registered for an event.
function Events:count(eventName)
    local list = self._handlers[eventName]
    if not list then
        return 0
    end
    local n = 0
    for i = 1, #list do
        if list[i].active then
            n = n + 1
        end
    end
    return n
end

return Events

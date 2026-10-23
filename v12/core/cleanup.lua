--[[
    core/cleanup.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Teardown registry.

    Every module registers its teardown callbacks here. Unloading the suite
    then restores the environment exactly: connections are disconnected,
    overridden globals are put back, instances are destroyed and every
    scheduler task is removed.

    The v11 build overrode `print` at protection level >= 7 and never undid
    it, which meant the executor's own logging was gone for the rest of the
    session. Nothing in this suite overrides a global without registering a
    matching restore.
]]

local Cleanup = {}

Cleanup.__index = Cleanup

function Cleanup.new(logger)
    return setmetatable({
        _entries = {},
        _logger = logger,
        _done = false,
    }, Cleanup)
end

--- Register a teardown callback. `label` is only used for logging.
function Cleanup:onDestroy(label, callback)
    if type(callback) ~= "function" then
        return function() end
    end
    local entry = { label = label or "anonymous", callback = callback, active = true }
    table.insert(self._entries, entry)

    return function()
        entry.active = false
    end
end

--- Register a Roblox connection for automatic disconnection.
function Cleanup:trackConnection(connection, label)
    if not connection then
        return
    end
    self:onDestroy(label or "connection", function()
        pcall(function()
            connection:Disconnect()
        end)
    end)
end

--- Register an instance for destruction on unload.
function Cleanup:trackInstance(instance, label)
    if not instance then
        return
    end
    self:onDestroy(label or "instance", function()
        pcall(function()
            instance:Destroy()
        end)
    end)
end

--- Register a restore for a global that the suite overwrote.
function Cleanup:trackGlobal(name, original)
    self:onDestroy("global:" .. tostring(name), function()
        _G[name] = original
    end)
end

--- Run every teardown callback. Safe to call more than once.
function Cleanup:run()
    if self._done then
        return
    end
    self._done = true

    -- newest first: later registrations usually depend on earlier ones
    for i = #self._entries, 1, -1 do
        local entry = self._entries[i]
        if entry.active then
            entry.active = false
            local ok, err = pcall(entry.callback)
            if not ok and self._logger then
                self._logger:warn("Cleanup failed for %s: %s", entry.label, tostring(err))
            end
        end
    end

    self._entries = {}
end

function Cleanup:count()
    return #self._entries
end

return Cleanup

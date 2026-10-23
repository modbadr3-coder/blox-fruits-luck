--[[
    core/init.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Suite root. Owns the shared services and the module lifecycle.

        local Suite = require("core")
        local suite = Suite.new()
        suite:Register("luck", require("luck"))
        suite:Start()
]]

local Logger = require("core.logger")
local Settings = require("core.settings")
local Scheduler = require("core.scheduler")
local Hotkeys = require("core.hotkeys")
local Events = require("core.events")
local Cleanup = require("core.cleanup")
local Util = require("core.util")

local Suite = {}

Suite.__index = Suite
Suite.Version = "12.0.0"
Suite.Name = "BLOX FRUITS SUITE"

function Suite.new(options)
    options = options or {}

    local logger = options.logger or Logger.new({
        prefix = "[BFS]",
        level = Logger.LEVELS.INFO,
    })

    local settings = options.settings or Settings.new({ logger = logger })

    local self = setmetatable({
        _logger = logger,
        _settings = settings,
        _scheduler = Scheduler.new(logger),
        _hotkeys = Hotkeys.new(settings, logger),
        _events = Events.new(),
        _cleanup = Cleanup.new(logger),
        _modules = {},
        _moduleOrder = {},
        _started = false,
        _startTime = os.time(),
        _uptime = 0,
    }, Suite)

    return self
end

function Suite:logger()
    return self._logger
end

function Suite:settings()
    return self._settings
end

function Suite:state()
    return self._settings:store()
end

function Suite:events()
    return self._events
end

function Suite:scheduler()
    return self._scheduler
end

function Suite:hotkeys()
    return self._hotkeys
end

function Suite:cleanup()
    return self._cleanup
end

--- Register a module. A module is a table with optional
--- Start(suite) / Stop(suite) / Name fields.
function Suite:Register(name, module)
    if type(module) ~= "table" then
        self._logger:warn("Cannot register module '%s': not a table", tostring(name))
        return false
    end

    self._modules[name] = module
    table.insert(self._moduleOrder, name)
    return true
end

function Suite:Get(name)
    return self._modules[name]
end

function Suite:ModuleNames()
    local out = {}
    for i = 1, #self._moduleOrder do
        out[i] = self._moduleOrder[i]
    end
    return out
end

--- Start the suite: settings, scheduler, hotkeys and every module.
function Suite:Start()
    if self._started then
        return false
    end
    self._started = true
    self._startTime = os.time()

    self._logger:info("==========================================")
    self._logger:info("%s v%s", Suite.Name, Suite.Version)
    self._logger:info("==========================================")

    self._settings:load()
    self._logger:info("Settings loaded (persistent: %s)", tostring(self._settings:isPersistent()))

    self._scheduler:start()
    self._hotkeys:start()

    for i = 1, #self._moduleOrder do
        local name = self._moduleOrder[i]
        local module = self._modules[name]
        if type(module.Start) == "function" then
            -- the module is the receiver, the suite is the argument
            local ok, err = pcall(module.Start, module, self)
            if ok then
                self._logger:info("Module '%s' started", name)
            else
                self._logger:error("Module '%s' failed to start: %s", name, tostring(err))
            end
        end
    end

    self._events:emit("suite.started", self)
    return true
end

--- Stop the suite and restore the environment.
function Suite:Stop()
    if not self._started then
        return false
    end
    self._started = false

    for i = #self._moduleOrder, 1, -1 do
        local name = self._moduleOrder[i]
        local module = self._modules[name]
        if type(module.Stop) == "function" then
            local ok, err = pcall(module.Stop, module, self)
            if not ok then
                self._logger:warn("Module '%s' failed to stop cleanly: %s", name, tostring(err))
            end
        end
    end

    self._scheduler:stop()
    self._hotkeys:stop()
    self._cleanup:run()
    self._events:emit("suite.stopped", self)

    self._logger:info("Suite stopped, environment restored")
    return true
end

function Suite:IsRunning()
    return self._started
end

function Suite:Uptime()
    return os.time() - self._startTime
end

--- Aggregate statistics for the dashboard.
function Suite:Snapshot()
    return {
        version = Suite.Version,
        uptime = self:Uptime(),
        modules = #self._moduleOrder,
        tasks = #self._scheduler._tasks,
        bindings = #self._hotkeys:list(),
        persistent = self._settings:isPersistent(),
    }
end

return Suite

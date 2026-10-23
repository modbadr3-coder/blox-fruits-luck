--[[
    core/scheduler.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    One Heartbeat connection drives every recurring task in the suite.

    v11 used `spawn(function() while true do wait(0.5) ... end end)` in a
    dozen places, which cannot be stopped and keeps running after the
    interface is destroyed. This scheduler can be paused, torn down and
    inspected.
]]

local Scheduler = {}

Scheduler.__index = Scheduler

function Scheduler.new(logger)
    return setmetatable({
        _tasks = {},
        _running = false,
        _paused = false,
        _logger = logger,
        _connection = nil,
        _lastRun = {},
        _frame = 0,
    }, Scheduler)
end

function Scheduler:start()
    if self._running then
        return
    end

    local ok, RunService = pcall(function()
        return game:GetService("RunService")
    end)
    if not ok then
        return
    end

    self._running = true
    self._connection = RunService.Heartbeat:Connect(function(deltaTime)
        self:tick(deltaTime)
    end)
end

function Scheduler:tick(deltaTime)
    self._frame = self._frame + 1
    if self._paused then
        return
    end

    local now = os.clock()
    for name, task in pairs(self._tasks) do
        if task.active then
            if task.interval then
                local last = self._lastRun[name] or 0
                if now - last >= task.interval then
                    self._lastRun[name] = now
                    pcall(task.callback, deltaTime)
                end
            else
                -- frame task
                pcall(task.callback, deltaTime)
            end
        end
    end
end

--- Register a recurring task.
---   name     unique identifier
---   interval seconds between runs (nil = every frame)
---   callback function(deltaTime)
function Scheduler:every(name, interval, callback)
    if type(callback) ~= "function" then
        return function() end
    end

    self._tasks[name] = {
        interval = interval,
        callback = callback,
        active = true,
    }
    self._lastRun[name] = 0

    return function()
        self:remove(name)
    end
end

--- Run a task on every frame.
function Scheduler:frame(name, callback)
    return self:every(name, nil, callback)
end

--- Run a task once, after `delay` seconds.
function Scheduler:after(name, delay, callback)
    if type(callback) ~= "function" then
        return
    end
    task.delay(delay or 0, function()
        self:remove(name)
        pcall(callback)
    end)
end

--- Remove a task by name.
function Scheduler:remove(name)
    if self._tasks[name] then
        self._tasks[name].active = false
        self._tasks[name] = nil
        self._lastRun[name] = nil
        return true
    end
    return false
end

function Scheduler:has(name)
    return self._tasks[name] ~= nil
end

function Scheduler:pause()
    self._paused = true
end

function Scheduler:resume()
    self._paused = false
end

function Scheduler:isPaused()
    return self._paused
end

function Scheduler:frameCount()
    return self._frame
end

--- Stop every task and drop the Heartbeat connection.
function Scheduler:stop()
    self._tasks = {}
    self._lastRun = {}
    if self._connection then
        pcall(function()
            self._connection:Disconnect()
        end)
        self._connection = nil
    end
    self._running = false
end

return Scheduler

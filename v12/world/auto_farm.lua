--[[
    world/auto_farm.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Automatic farming loop.

    The loop is deliberately simple and observable:
        1. pick a target mob (nearest one that matches the level filter)
        2. walk the character to it
        3. attack until it dies or the character leaves the area
        4. repeat

    Everything it does is reported through the status fields, so the
    interface can show what the loop is actually doing instead of a
    vague "running" label.
]]

local Movement = require("world.movement")
local Util = require("core.util")

local AutoFarm = {}

AutoFarm.__index = AutoFarm

function AutoFarm.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _scanner = options.scanner,
        _input = options.input,
        _stats = options.stats,
        _settings = options.settings,
        _active = false,
        _target = nil,
        _targetId = nil,
        _kills = 0,
        _lastKill = 0,
        _startedAt = 0,
        _state = "idle",
    }, AutoFarm)
end

function AutoFarm:Start()
    self._active = true
    self._startedAt = os.time()
    self._state = "scanning"
    if self._logger then
        self._logger:info("Auto farm enabled")
    end
end

function AutoFarm:Stop()
    self._active = false
    self._target = nil
    self._targetId = nil
    self._state = "idle"
    if self._logger then
        self._logger:info("Auto farm disabled after %d kill(s)", self._kills)
    end
end

function AutoFarm:IsActive()
    return self._active
end

function AutoFarm:_settingsValue(path, fallback)
    if not self._settings then
        return fallback
    end
    local value = self._settings:get(path, fallback)
    if value == nil then
        return fallback
    end
    return value
end

--- Choose a mob to attack.
---
--- `targetLevel` of 0 means "use the player's level". Mobs up to
--- `levelTolerance` above the target level are accepted, which is how the
--- suite avoids running into a wall.
function AutoFarm:PickTarget()
    if not self._scanner then
        return nil
    end

    local mobs = self._scanner:Mobs()
    if #mobs == 0 then
        return nil
    end

    local root = Movement.GetRoot()
    local origin = root and root.Position or Vector3.new(0, 0, 0)

    local playerLevel = 0
    if self._stats then
        playerLevel = self._stats:GetLevel()
    end

    local targetLevel = self:_settingsValue("farm.targetLevel", 0) or 0
    if targetLevel <= 0 then
        targetLevel = playerLevel
    end
    if targetLevel <= 0 then
        targetLevel = 100
    end

    local tolerance = 25
    local attackRange = self:_settingsValue("farm.attackRange", 12) or 12
    local searchRadius = (attackRange + 60) * 3

    local best, bestScore = nil, nil

    for _, mob in ipairs(mobs) do
        local level = mob.level or 0
        if level > 0 and level <= targetLevel + tolerance then
            local distance = (mob.position - origin).Magnitude
            if distance <= searchRadius then
                -- prefer mobs close to the target level, then close by
                local levelDelta = math.abs(level - targetLevel)
                local score = levelDelta * 10 + distance
                if bestScore == nil or score < bestScore then
                    best, bestScore = mob, score
                end
            end
        end
    end

    return best
end

--- One iteration of the loop. Called by the scheduler.
function AutoFarm:Step(deltaTime)
    if not self._active then
        return
    end

    if not Movement.IsAlive() then
        self._state = "waiting for respawn"
        self._target = nil
        return
    end

    -- safety stop
    if self:_settingsValue("farm.safeMode", true) then
        local minimum = self:_settingsValue("farm.safeHealth", 30) or 30
        if Movement.GetHealthPercent() < minimum then
            self._state = string.format("stopped: health below %d%%", minimum)
            self:Stop()
            return
        end
    end

    -- keep the current target while it is alive and close
    if self._target and Util.isInstance(self._target.instance) then
        local humanoid = self._target.instance:FindFirstChildOfClass("Humanoid")
        local alive = true
        if humanoid then
            alive = humanoid.Health > 0
        end
        if alive then
            self:_engage(self._target, deltaTime)
            return
        end

        self._kills = self._kills + 1
        self._lastKill = os.time()
        self._target = nil
        self._targetId = nil
    end

    local target = self:PickTarget()
    if not target then
        self._state = "no target in range"
        return
    end

    self._target = target
    self._state = "moving to " .. target.name
end

function AutoFarm:_engage(target, deltaTime)
    local root = Movement.GetRoot()
    if not root then
        return
    end

    local attackRange = self:_settingsValue("farm.attackRange", 12) or 12
    local distance = (target.position - root.Position).Magnitude

    if distance > attackRange then
        self._state = "closing distance to " .. target.name
        local step = (deltaTime or 0.016) * 90
        Movement.MoveTowards(target.position, math.max(step, 3))
        return
    end

    self._state = "attacking " .. target.name
    Movement.LookAt(target.position)
    if self._input then
        self._input:Click()
    end
end

--- Status for the interface.
function AutoFarm:GetStatus()
    return {
        active = self._active,
        state = self._state,
        target = self._target and self._target.name or nil,
        targetLevel = self._target and self._target.level or nil,
        kills = self._kills,
        uptime = self._startedAt > 0 and (os.time() - self._startedAt) or 0,
        lastKill = self._lastKill,
    }
end

function AutoFarm:Reset()
    self._kills = 0
    self._lastKill = 0
end

return AutoFarm

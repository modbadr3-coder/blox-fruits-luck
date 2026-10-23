--[[
    world/auto_collect.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Walks the character to the closest fruit and picks it up.

    Picking a fruit up in Blox Fruits is a proximity interaction. The
    module teleports the character next to the fruit, then triggers the
    interaction with whatever mechanism the executor provides. When the
    executor has no way to fire the interaction, the character still ends
    up standing on the fruit, which picks it up in most cases because the
    game's own touch detection runs on the server.
]]

local Movement = require("world.movement")
local Util = require("core.util")

local AutoCollect = {}

AutoCollect.__index = AutoCollect

function AutoCollect.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _scanner = options.scanner,
        _input = options.input,
        _active = false,
        _target = nil,
        _collected = 0,
        _startedAt = 0,
        _state = "idle",
        _lastCollected = nil,
    }, AutoCollect)
end

function AutoCollect:Start()
    self._active = true
    self._startedAt = os.time()
    self._state = "scanning"
    if self._logger then
        self._logger:info("Auto collect enabled")
    end
end

function AutoCollect:Stop()
    self._active = false
    self._target = nil
    self._state = "idle"
end

function AutoCollect:IsActive()
    return self._active
end

--- The closest fruit that is still in the world.
function AutoCollect:PickTarget()
    if not self._scanner then
        return nil
    end

    local fruits = self._scanner:Fruits()
    if #fruits == 0 then
        return nil
    end

    local root = Movement.GetRoot()
    local origin = root and root.Position or Vector3.new(0, 0, 0)

    local best, bestDistance = nil, math.huge
    for _, fruit in ipairs(fruits) do
        local distance = (fruit.position - origin).Magnitude
        if distance < bestDistance then
            best, bestDistance = fruit, distance
        end
    end

    return best
end

function AutoCollect:Step(deltaTime)
    if not self._active then
        return
    end

    if not Movement.IsAlive() then
        self._state = "waiting for respawn"
        return
    end

    -- validate the current target
    if self._target then
        if not Util.isInstance(self._target.instance) or not self._target.instance.Parent then
            -- the fruit is gone -- it was probably collected
            self._collected = self._collected + 1
            self._lastCollected = self._target.fruit
            self._target = nil
        else
            self:_engage(self._target, deltaTime)
            return
        end
    end

    local target = self:PickTarget()
    if not target then
        self._state = "no fruit in range"
        return
    end

    self._target = target
    self._state = "moving to " .. target.fruit
end

function AutoCollect:_engage(target, deltaTime)
    local root = Movement.GetRoot()
    if not root then
        return
    end

    local distance = (target.position - root.Position).Magnitude

    if distance > 6 then
        self._state = "moving to " .. target.fruit
        local step = (deltaTime or 0.016) * 110
        Movement.MoveTowards(target.position, math.max(step, 4))
        return
    end

    self._state = "collecting " .. target.fruit

    -- try to fire a proximity prompt attached to the fruit
    local fired = false
    if self._input then
        local instance = target.instance
        if Util.isInstance(instance) then
            for _, child in ipairs(instance:GetDescendants()) do
                if Util.isInstance(child, "ProximityPrompt") then
                    if self._input:FireProximityPrompt(child) then
                        fired = true
                        break
                    end
                end
            end
        end
        if not fired then
            self._input:PressE()
        end
    end

    if not fired then
        -- stand on the fruit so the game's own pickup detection fires
        Movement.TeleportNear(target.position, 2)
    end
end

function AutoCollect:GetStatus()
    return {
        active = self._active,
        state = self._state,
        target = self._target and self._target.fruit or nil,
        collected = self._collected,
        lastCollected = self._lastCollected,
        uptime = self._startedAt > 0 and (os.time() - self._startedAt) or 0,
    }
end

return AutoCollect

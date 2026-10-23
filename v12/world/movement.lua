--[[
    world/movement.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Character and movement helpers.

    The suite moves the player by writing to the HumanoidRootPart's
    CFrame. That is the same technique every Blox Fruits utility uses, and
    it is the only client-side approach that works without the server
    agreeing to move the character.
]]

local Util = require("core.util")

local Movement = {}

function Movement.GetPlayer()
    local ok, Players = pcall(function()
        return game:GetService("Players")
    end)
    if not ok then
        return nil
    end
    local okPlayer, player = pcall(function()
        return Players.LocalPlayer
    end)
    if okPlayer then
        return player
    end
    return nil
end

function Movement.GetCharacter()
    local player = Movement.GetPlayer()
    if not player then
        return nil
    end
    local ok, character = pcall(function()
        return player.Character
    end)
    if ok then
        return character
    end
    return nil
end

function Movement.GetRoot(character)
    character = character or Movement.GetCharacter()
    if not Util.isInstance(character) then
        return nil
    end
    local ok, root = pcall(function()
        return character:FindFirstChild("HumanoidRootPart")
    end)
    if ok then
        return root
    end
    return nil
end

function Movement.GetHumanoid(character)
    character = character or Movement.GetCharacter()
    if not Util.isInstance(character) then
        return nil
    end
    local ok, humanoid = pcall(function()
        return character:FindFirstChildOfClass("Humanoid")
    end)
    if ok then
        return humanoid
    end
    return nil
end

--- True when the character exists and is alive.
function Movement.IsAlive()
    local humanoid = Movement.GetHumanoid()
    if not humanoid then
        return false
    end
    local ok, health = pcall(function()
        return humanoid.Health
    end)
    return ok and health > 0
end

function Movement.GetHealth()
    local humanoid = Movement.GetHumanoid()
    if not humanoid then
        return 0
    end
    local ok, health = pcall(function()
        return humanoid.Health
    end)
    if ok then
        return health
    end
    return 0
end

function Movement.GetMaxHealth()
    local humanoid = Movement.GetHumanoid()
    if not humanoid then
        return 0
    end
    local ok, maxHealth = pcall(function()
        return humanoid.MaxHealth
    end)
    if ok then
        return maxHealth
    end
    return 0
end

function Movement.GetHealthPercent()
    local maxHealth = Movement.GetMaxHealth()
    if maxHealth <= 0 then
        return 0
    end
    return (Movement.GetHealth() / maxHealth) * 100
end

--- Place the character at a world position, keeping the current facing.
function Movement.TeleportTo(position, lookAt)
    local root = Movement.GetRoot()
    if not root or type(position) ~= "Vector3" then
        return false
    end

    local target = CFrame.new(position)
    if lookAt then
        target = CFrame.lookAt(position, lookAt)
    end

    local ok = pcall(function()
        root.CFrame = target
    end)
    return ok
end

--- Place the character a given distance away from a target, looking at it.
function Movement.TeleportNear(targetPosition, distance)
    if type(targetPosition) ~= "Vector3" then
        return false
    end

    local root = Movement.GetRoot()
    if not root then
        return false
    end

    local origin = root.Position
    local offset = targetPosition - origin
    if offset.Magnitude < 0.001 then
        offset = Vector3.new(0, 0, 1)
    end
    offset = offset.Unit * (distance or 8)

    local destination = targetPosition - offset
    local ok = pcall(function()
        root.CFrame = CFrame.lookAt(destination, targetPosition)
    end)
    return ok
end

--- Step the character towards a target by a distance in studs.
function Movement.MoveTowards(targetPosition, step)
    local root = Movement.GetRoot()
    if not root or type(targetPosition) ~= "Vector3" then
        return false
    end

    local origin = root.Position
    local delta = targetPosition - origin
    local distance = delta.Magnitude

    if distance < 0.5 then
        return false
    end

    local moved = delta.Unit * math.min(step or 5, distance)
    local ok = pcall(function()
        root.CFrame = CFrame.new(origin + moved) * root.CFrame.Rotation
    end)
    return ok
end

--- Face a target without moving.
function Movement.LookAt(targetPosition)
    local root = Movement.GetRoot()
    if not root or type(targetPosition) ~= "Vector3" then
        return false
    end
    local ok = pcall(function()
        root.CFrame = CFrame.lookAt(root.Position, targetPosition)
    end)
    return ok
end

return Movement

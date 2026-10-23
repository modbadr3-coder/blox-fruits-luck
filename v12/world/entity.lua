--[[
    world/entity.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Classifies a live workspace instance into something the suite understands.

    Blox Fruits does not expose a clean API for "what is this model?", so
    the classification is heuristic: the name is matched against the fruit,
    mob, boss, chest and NPC tables, and the level is recovered from
    attributes, child values, or the display name.
]]

local Fruits = require("data.fruits")
local Mobs = require("data.mobs")
local Chests = require("data.chests")
local NPCs = require("data.npcs")
local Util = require("core.util")

local Entity = {}

Entity.KINDS = { "fruit", "mob", "boss", "chest", "npc", "player" }

--- Look for a level value on an instance.
--- Looks at attributes first, then at IntValue / NumberValue children, and
--- finally parses the display name ("Bandit [Lv. 35]").
function Entity:ExtractLevel(instance)
    if not Util.isInstance(instance) then
        return nil
    end

    for _, attributeName in ipairs({ "Level", "MobLevel", "Level_" }) do
        local ok, value = pcall(function()
            return instance:GetAttribute(attributeName)
        end)
        if ok and type(value) == "number" then
            return value
        end
    end

    for _, child in ipairs(instance:GetChildren()) do
        if Util.isInstance(child) then
            local className = Util.getClass(child)
            if className == "IntValue" or className == "NumberValue" or className == "StringValue" then
                if string.lower(child.Name):find("level") then
                    local ok, value = pcall(function()
                        return child.Value
                    end)
                    if ok then
                        if type(value) == "number" then
                            return value
                        end
                        if type(value) == "string" then
                            local parsed = tonumber(value:match("%d+"))
                            if parsed then
                                return parsed
                            end
                        end
                    end
                end
            end
        end
    end

    -- parse the display name
    local okName, name = pcall(function()
        return instance.Name
    end)
    if okName and type(name) == "string" then
        local parsed = tonumber(name:match("Lv%.?%s*(%d+)")) or tonumber(name:match("(%d+)"))
        if parsed then
            return parsed
        end
    end

    return nil
end

--- Classify an instance.
--- Returns nil when the instance is not something the suite tracks.
function Entity:Classify(instance)
    if not Util.isInstance(instance) then
        return nil
    end

    local okName, name = pcall(function()
        return instance.Name
    end)
    if not okName or type(name) ~= "string" then
        return nil
    end

    -- players are handled separately
    if Util.getClass(instance) == "Player" then
        return { kind = "player", name = name }
    end

    -- fruit
    local fruit = Fruits.Resolve(name)
    if fruit and (name:lower():find("fruit", 1, true) or self:_looksLikeFruitModel(instance)) then
        return {
            kind = "fruit",
            name = fruit.name,
            display = name,
            rarity = fruit.rarity,
            type = fruit.type,
            record = fruit,
        }
    end

    -- chests
    if Chests.IsChest(name) then
        return {
            kind = "chest",
            name = name,
            display = name,
            tier = Chests.TierOf(name),
        }
    end

    -- bosses
    local boss = Mobs.BossByName[name:lower()]
    if boss then
        return {
            kind = "boss",
            name = boss.name,
            display = name,
            level = self:ExtractLevel(instance) or boss.level,
            record = boss,
        }
    end

    -- NPCs
    local npcRole = NPCs.RoleFromName(name)
    if npcRole then
        return {
            kind = "npc",
            name = name,
            display = name,
            role = npcRole,
        }
    end

    -- mobs
    local mob = Mobs.ByName[name:lower()]
    if mob then
        return {
            kind = "mob",
            name = mob.name,
            display = name,
            level = self:ExtractLevel(instance) or mob.level,
            record = mob,
        }
    end

    -- last resort: does it carry a Humanoid and a readable level?
    local level = self:ExtractLevel(instance)
    if level and self:_hasHumanoid(instance) then
        return {
            kind = "mob",
            name = name,
            display = name,
            level = level,
            guessed = true,
        }
    end

    return nil
end

function Entity:_looksLikeFruitModel(instance)
    if not Util.isInstance(instance) then
        return false
    end
    for _, child in ipairs(instance:GetChildren()) do
        if Util.isInstance(child, "StringValue") then
            if Fruits.Resolve(child.Value) then
                return true
            end
        end
    end
    for _, attributeName in ipairs({ "FruitName", "Fruit", "Rarity" }) do
        local ok, value = pcall(function()
            return instance:GetAttribute(attributeName)
        end)
        if ok and type(value) == "string" and Fruits.Resolve(value) then
            return true
        end
    end
    return false
end

function Entity:_hasHumanoid(instance)
    if not Util.isInstance(instance) then
        return false
    end
    local ok, humanoid = pcall(function()
        return instance:FindFirstChildOfClass("Humanoid")
    end)
    return ok and humanoid ~= nil
end

--- Human readable label for an entity, used by the ESP overlay.
function Entity:Label(entity, distance)
    if not entity then
        return ""
    end

    local parts = {}
    if entity.kind == "fruit" then
        parts[#parts + 1] = entity.name
        parts[#parts + 1] = entity.rarity or ""
    elseif entity.kind == "mob" or entity.kind == "boss" then
        parts[#parts + 1] = entity.name
        if entity.level then
            parts[#parts + 1] = "Lv." .. tostring(entity.level)
        end
    elseif entity.kind == "chest" then
        parts[#parts + 1] = entity.name
    elseif entity.kind == "npc" then
        parts[#parts + 1] = entity.name
    else
        parts[#parts + 1] = entity.name or "?"
    end

    if distance then
        parts[#parts + 1] = string.format("%d studs", math.floor(distance))
    end

    return table.concat(parts, "  |  ")
end

--- Colour used for the ESP overlay.
function Entity:Color(entity)
    if not entity then
        return Color3.fromRGB(200, 200, 200)
    end

    if entity.kind == "fruit" then
        local Rarity = require("luck.rarity")
        return Rarity.Color(entity.rarity)
    elseif entity.kind == "boss" then
        return Color3.fromRGB(255, 60, 60)
    elseif entity.kind == "chest" then
        return Color3.fromRGB(255, 210, 70)
    elseif entity.kind == "npc" then
        return Color3.fromRGB(120, 220, 255)
    elseif entity.kind == "mob" then
        return Color3.fromRGB(200, 120, 255)
    end

    return Color3.fromRGB(200, 200, 200)
end

return Entity

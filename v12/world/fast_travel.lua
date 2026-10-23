--[[
    world/fast_travel.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Teleports the character to a named destination.

    Because the islands are laid out differently in every server, the
    destination is resolved by finding a live NPC whose name matches the
    request and walking to it. The catalogue in data/islands.lua is used
    to turn "Third Sea" into a list of candidate NPCs.
]]

local Movement = require("world.movement")
local NPCs = require("data.npcs")
local Islands = require("data.islands")
local Util = require("core.util")

local FastTravel = {}

FastTravel.__index = FastTravel

function FastTravel.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _scanner = options.scanner,
        _lastDestination = nil,
        _lastError = nil,
        _tripCount = 0,
    }, FastTravel)
end

--- All destinations the suite can currently see in the world.
function FastTravel:Available()
    local out = {}

    if self._scanner then
        for _, npc in ipairs(self._scanner:NPCs()) do
            out[#out + 1] = {
                name = npc.name,
                role = npc.role,
                position = npc.position,
            }
        end
    end

    return out
end

--- Find a live NPC whose name matches the query.
function FastTravel:FindNpc(query)
    if type(query) ~= "string" or query == "" then
        return nil
    end

    if not self._scanner then
        return nil
    end

    local lowered = query:lower()

    -- exact match first
    for _, npc in ipairs(self._scanner:NPCs()) do
        if npc.name:lower() == lowered then
            return npc
        end
    end

    -- then a partial match
    local best = nil
    for _, npc in ipairs(self._scanner:NPCs()) do
        if npc.name:lower():find(lowered, 1, true) then
            best = npc
            break
        end
    end

    if best then
        return best
    end

    -- fall back to a known NPC signature
    local role = NPCs.RoleFromName(query)
    if role then
        for _, npc in ipairs(self._scanner:NPCs()) do
            if npc.role == role then
                return npc
            end
        end
    end

    return nil
end

--- Teleport to a destination by NPC name.
function FastTravel:TravelTo(query)
    local npc = self:FindNpc(query)
    if not npc then
        self._lastError = "no NPC matching '" .. tostring(query) .. "'"
        if self._logger then
            self._logger:warn("Fast travel failed: %s", self._lastError)
        end
        return false
    end

    local ok = Movement.TeleportNear(npc.position, 6)
    if ok then
        self._lastDestination = npc.name
        self._lastError = nil
        self._tripCount = self._tripCount + 1
        if self._logger then
            self._logger:info("Travelled to %s", npc.name)
        end
    end

    return ok
end

--- Teleport to the island that fits a level.
function FastTravel:TravelToIslandForLevel(level)
    local island = Islands.ForLevel(level)
    if not island then
        return false
    end

    -- the island is identified by the NPCs that live on it
    for _, npc in ipairs(NPCs.List) do
        if npc.island == island.name and npc.role ~= "quest" then
            if self:TravelTo(npc.name) then
                return true
            end
        end
    end

    self._lastError = "no NPC found for " .. island.name
    return false
end

function FastTravel:GetStatus()
    return {
        lastDestination = self._lastDestination,
        lastError = self._lastError,
        trips = self._tripCount,
    }
end

return FastTravel

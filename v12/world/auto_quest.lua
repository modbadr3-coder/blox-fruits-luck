--[[
    world/auto_quest.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Quest runner.

    The flow:
        1. walk to the closest quest giver
        2. read the quest target from the quest panel in the HUD
        3. if the target is a mob we recognise, go and defeat it
        4. return to the quest giver to hand the quest in

    Step 2 is the weak point: the quest panel is a set of TextLabels whose
    structure changes between game updates, so the reader looks for a
    label that contains a mob name from the mob table. When it cannot
    find one, the module says so instead of guessing.
]]

local Movement = require("world.movement")
local Mobs = require("data.mobs")
local NPCs = require("data.npcs")
local Util = require("core.util")

local AutoQuest = {}

AutoQuest.__index = AutoQuest

-- Labels that usually hold the quest description.
local QUEST_LABELS = { "QuestName", "QuestDescription", "QuestTarget", "MissionName", "QuestInfo" }

function AutoQuest.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _scanner = options.scanner,
        _input = options.input,
        _active = false,
        _state = "idle",
        _questGiver = nil,
        _targetMob = nil,
        _completed = 0,
        _startedAt = 0,
    }, AutoQuest)
end

function AutoQuest:Start()
    self._active = true
    self._startedAt = os.time()
    self._state = "looking for a quest giver"
    if self._logger then
        self._logger:info("Auto quest enabled")
    end
end

function AutoQuest:Stop()
    self._active = false
    self._state = "idle"
    self._questGiver = nil
    self._targetMob = nil
end

function AutoQuest:IsActive()
    return self._active
end

--- Read the quest target out of the HUD.
function AutoQuest:ReadQuestTarget()
    local ok, Players = pcall(function()
        return game:GetService("Players")
    end)
    if not ok then
        return nil
    end
    local okPlayer, player = pcall(function()
        return Players.LocalPlayer
    end)
    if not okPlayer or not player then
        return nil
    end
    local okGui, playerGui = pcall(function()
        return player:FindFirstChildOfClass("PlayerGui")
    end)
    if not okGui or not playerGui then
        return nil
    end

    for _, labelName in ipairs(QUEST_LABELS) do
        local ok, label = pcall(function()
            return playerGui:FindFirstChild(labelName, true)
        end)
        if ok and label and (label:IsA("TextLabel") or label:IsA("TextButton")) then
            local text = label.Text
            if type(text) == "string" and text ~= "" then
                -- look for a mob name inside the quest text
                for mobName, mob in pairs(Mobs.ByName) do
                    if text:lower():find(mobName:lower(), 1, true) then
                        return mob
                    end
                end
            end
        end
    end

    return nil
end

--- The closest quest giver in the world.
function AutoQuest:PickQuestGiver()
    if not self._scanner then
        return nil
    end

    local npcs = self._scanner:NPCs()
    local root = Movement.GetRoot()
    local origin = root and root.Position or Vector3.new(0, 0, 0)

    local best, bestDistance = nil, math.huge
    for _, npc in ipairs(npcs) do
        if npc.role == "quest" then
            local distance = (npc.position - origin).Magnitude
            if distance < bestDistance then
                best, bestDistance = npc, distance
            end
        end
    end

    return best
end

function AutoQuest:Step(deltaTime)
    if not self._active then
        return
    end

    if not Movement.IsAlive() then
        self._state = "waiting for respawn"
        return
    end

    local root = Movement.GetRoot()
    if not root then
        return
    end

    -- are we already fighting the quest target?
    if self._targetMob and Util.isInstance(self._targetMob.instance) then
        local humanoid = self._targetMob.instance:FindFirstChildOfClass("Humanoid")
        local alive = not humanoid or humanoid.Health > 0
        if alive then
            self._state = "fighting " .. self._targetMob.name
            local distance = (self._targetMob.position - root.Position).Magnitude
            if distance > 10 then
                local step = (deltaTime or 0.016) * 90
                Movement.MoveTowards(self._targetMob.position, math.max(step, 3))
            else
                Movement.LookAt(self._targetMob.position)
                if self._input then
                    self._input:Click()
                end
            end
            return
        end

        self._completed = self._completed + 1
        self._targetMob = nil
        self._state = "quest target defeated, returning to the giver"
    end

    -- find the giver
    if not self._questGiver or not Util.isInstance(self._questGiver.instance) then
        self._questGiver = self:PickQuestGiver()
        if not self._questGiver then
            self._state = "no quest giver in range"
            return
        end
    end

    local distance = (self._questGiver.position - root.Position).Magnitude
    if distance > 8 then
        self._state = "walking to " .. self._questGiver.name
        local step = (deltaTime or 0.016) * 100
        Movement.MoveTowards(self._questGiver.position, math.max(step, 4))
        return
    end

    -- we are at the giver -- read the quest and go after the target
    local target = self:ReadQuestTarget()
    if target then
        self._targetMob = {
            name = target.name,
            level = target.level,
            instance = nil,
            position = Vector3.new(0, 0, 0),
        }

        -- find the live instance of that mob
        if self._scanner then
            for _, mob in ipairs(self._scanner:Mobs()) do
                if mob.name == target.name then
                    self._targetMob = mob
                    break
                end
            end
        end

        if self._targetMob.instance then
            self._state = "quest accepted: " .. target.name
        else
            self._state = "quest target not in range yet"
        end
        return
    end

    -- no readable quest: interact with the giver and hope
    self._state = "at quest giver, interacting"
    if self._input then
        self._input:Click()
        self._input:PressE()
    end
end

function AutoQuest:GetStatus()
    return {
        active = self._active,
        state = self._state,
        questGiver = self._questGiver and self._questGiver.name or nil,
        target = self._targetMob and self._targetMob.name or nil,
        completed = self._completed,
        uptime = self._startedAt > 0 and (os.time() - self._startedAt) or 0,
    }
end

return AutoQuest

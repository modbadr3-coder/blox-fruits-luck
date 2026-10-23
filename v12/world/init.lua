--[[
    world/init.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    World module facade.

    Owns the scanner, the ESP overlay, the automation loops and the fast
    travel helper, and reacts to the settings that turn each feature on
    and off.
]]

local Scanner = require("world.scanner")
local Esp = require("world.esp")
local AutoFarm = require("world.auto_farm")
local AutoCollect = require("world.auto_collect")
local AutoQuest = require("world.auto_quest")
local FastTravel = require("world.fast_travel")
local PlayerStats = require("world.player_stats")
local Input = require("world.input")
local Entity = require("world.entity")
local Movement = require("world.movement")

local World = {}

World.__index = World

function World.new(options)
    options = options or {}

    local self = setmetatable({
        _logger = options.logger,
        _settings = options.settings,
        _cleanup = options.cleanup,
        _scanner = Scanner.new({ logger = options.logger }),
        _input = Input.new({ logger = options.logger }),
        _stats = PlayerStats.new({ logger = options.logger }),
        _started = false,
    }, World)

    self._esp = Esp.new({
        logger = options.logger,
        cleanup = options.cleanup,
    })

    self._autoFarm = AutoFarm.new({
        logger = options.logger,
        scanner = self._scanner,
        input = self._input,
        stats = self._stats,
        settings = options.settings,
    })

    self._autoCollect = AutoCollect.new({
        logger = options.logger,
        scanner = self._scanner,
        input = self._input,
    })

    self._autoQuest = AutoQuest.new({
        logger = options.logger,
        scanner = self._scanner,
        input = self._input,
    })

    self._fastTravel = FastTravel.new({
        logger = options.logger,
        scanner = self._scanner,
    })

    return self
end

function World:Start(suite)
    local settings = suite and suite:settings() or self._settings
    self._settings = settings or self._settings

    -- scan on a timer
    if suite and suite:scheduler() then
        suite:scheduler():every("world.scan", 2.0, function()
            self._scanner:Scan()
        end)

        -- refresh the overlay on its own, slower timer
        suite:scheduler():every("world.esp", 0.5, function()
            self:RefreshESP()
        end)

        -- drive the automation loops
        suite:scheduler():frame("world.farm", function(deltaTime)
            self._autoFarm:Step(deltaTime)
        end)

        suite:scheduler():frame("world.collect", function(deltaTime)
            self._autoCollect:Step(deltaTime)
        end)

        suite:scheduler():frame("world.quest", function(deltaTime)
            self._autoQuest:Step(deltaTime)
        end)
    end

    if settings then
        settings:onChange("world.maxESP", function(value)
            self._esp:SetMaxObjects(value)
        end)

        settings:onChange("world.fruitESPLabel", function(value)
            self._esp:SetShowLabel(value)
        end)

        settings:onChange("farm.autoFarm", function(value)
            if value then
                self._autoFarm:Start()
            else
                self._autoFarm:Stop()
            end
        end)

        settings:onChange("farm.autoCollect", function(value)
            if value then
                self._autoCollect:Start()
            else
                self._autoCollect:Stop()
            end
        end)

        settings:onChange("farm.autoQuest", function(value)
            if value then
                self._autoQuest:Start()
            else
                self._autoQuest:Stop()
            end
        end)

        -- apply the values that are already set
        self._esp:SetMaxObjects(settings:get("world.maxESP", 150))
    end

    -- first scan straight away
    self._scanner:Scan()

    self._started = true

    if self._logger then
        self._logger:info("World module started")
    end

    return true
end

function World:Stop()
    self._started = false
    self._autoFarm:Stop()
    self._autoCollect:Stop()
    self._autoQuest:Stop()
    self._esp:SetEnabled(false)
    self._esp:Destroy()
    return true
end

-- ── accessors ────────────────────────────────────────────────────────────

--- True once Start() has run successfully.
function World:IsStarted()
    return self._started
end

function World:Scanner()
    return self._scanner
end

function World:ESP()
    return self._esp
end

function World:AutoFarm()
    return self._autoFarm
end

function World:AutoCollect()
    return self._autoCollect
end

function World:AutoQuest()
    return self._autoQuest
end

function World:FastTravel()
    return self._fastTravel
end

function World:PlayerStats()
    return self._stats
end

function World:Input()
    return self._input
end

function World:Entity()
    return Entity
end

function World:Movement()
    return Movement
end

-- ── ESP control ──────────────────────────────────────────────────────────

--- Rebuild the overlay from the scanner buckets.
--- `kinds` is a list of entity kinds to draw.
function World:UpdateESP(kinds)
    local entries = {}
    local root = Movement.GetRoot()
    local origin = root and root.Position or Vector3.new(0, 0, 0)

    local buckets = self._scanner:Buckets()
    local wanted = {}
    for _, kind in ipairs(kinds or {}) do
        wanted[kind] = true
    end

    for kind, list in pairs(buckets) do
        if wanted[kind] then
            for _, entity in ipairs(list) do
                local distance = (entity.position - origin).Magnitude
                entries[#entries + 1] = {
                    entity = entity,
                    distance = distance,
                }
            end
        end
    end

    table.sort(entries, function(a, b)
        return a.distance < b.distance
    end)

    return self._esp:Render(entries, {
        labelBuilder = function(entity, distance)
            return Entity:Label(entity, distance)
        end,
        colorBuilder = function(entity)
            return Entity:Color(entity)
        end,
    })
end

--- Which ESP layers are currently enabled by the settings.
function World:EnabledLayers()
    local settings = self._settings
    if not settings then
        return {}
    end

    local layers = {}
    if settings:get("world.fruitESP", false) then
        layers[#layers + 1] = "fruit"
    end
    if settings:get("world.mobESP", false) then
        layers[#layers + 1] = "mob"
    end
    if settings:get("world.bossESP", false) then
        layers[#layers + 1] = "boss"
    end
    if settings:get("world.chestESP", false) then
        layers[#layers + 1] = "chest"
    end
    if settings:get("world.npcESP", false) then
        layers[#layers + 1] = "npc"
    end
    return layers
end

--- Refresh the overlay if any layer is enabled.
function World:RefreshESP()
    local layers = self:EnabledLayers()
    if #layers == 0 then
        self._esp:SetEnabled(false)
        return 0
    end

    self._esp:SetEnabled(true)
    return self:UpdateESP(layers)
end

-- ── automation control ───────────────────────────────────────────────────

function World:SetAutoFarm(enabled)
    if enabled then
        self._autoFarm:Start()
    else
        self._autoFarm:Stop()
    end
    return enabled
end

function World:SetAutoCollect(enabled)
    if enabled then
        self._autoCollect:Start()
    else
        self._autoCollect:Stop()
    end
    return enabled
end

function World:SetAutoQuest(enabled)
    if enabled then
        self._autoQuest:Start()
    else
        self._autoQuest:Stop()
    end
    return enabled
end

--- Travel to a named NPC.
function World:TravelTo(name)
    return self._fastTravel:TravelTo(name)
end

--- One status snapshot for the dashboard.
function World:GetStats()
    local buckets = self._scanner:Buckets()

    return {
        scanCount = self._scanner:ScanCount(),
        scanDuration = self._scanner:LastDuration(),
        counts = {
            fruit = #buckets.fruit,
            mob = #buckets.mob,
            boss = #buckets.boss,
            chest = #buckets.chest,
            npc = #buckets.npc,
        },
        player = self._stats:Get(),
        autoFarm = self._autoFarm:GetStatus(),
        autoCollect = self._autoCollect:GetStatus(),
        autoQuest = self._autoQuest:GetStatus(),
        travel = self._fastTravel:GetStatus(),
        input = { method = self._input:Method() },
    }
end

return World

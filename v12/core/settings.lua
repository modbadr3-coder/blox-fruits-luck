--[[
    core/settings.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Persistence layer.

    On a real executor the suite writes a JSON file next to the script
    (`bfs_settings.json`). When no file API is available (Studio sandbox,
    stripped executor) the settings live in memory for the session and the
    UI clearly reports that persistence is unavailable.

    v11 shipped a `config/settings.json` that was never read by any code --
    the toggles silently did nothing. Everything here is wired to the live
    store, so a value that is visible in the UI is a value that is honoured.
]]

local Json = require("core.json")
local Util = require("core.util")

local Settings = {}

Settings.__index = Settings

local FILE_NAME = "bfs_settings.json"

-- Every setting the suite understands, with its default and a short
-- description. The UI builds itself from this table, so adding a setting
-- here automatically exposes it.
Settings.SCHEMA = {
    general = {
        keybind = { type = "key", default = Enum.KeyCode.RightShift, desc = "Toggle the interface" },
        minimizeOnDeath = { type = "bool", default = true, desc = "Hide the interface when the character dies" },
        minimizeKey = { type = "key", default = Enum.KeyCode.End, desc = "Minimise the interface" },
        theme = { type = "string", default = "midnight", desc = "Interface theme" },
        transparency = { type = "number", default = 0, min = 0, max = 90, desc = "Interface transparency" },
        accent = { type = "string", default = "cyan", desc = "Accent colour" },
        notifications = { type = "bool", default = true, desc = "Show toast notifications" },
        sounds = { type = "bool", default = false, desc = "Play UI sounds" },
        logLevel = { type = "string", default = "INFO", desc = "Console verbosity" },
        saveOnChange = { type = "bool", default = true, desc = "Save settings automatically" },
    },
    luck = {
        enabled = { type = "bool", default = true, desc = "Enable the luck engine" },
        multiplier = { type = "number", default = 2.0, min = 1, max = 10, step = 0.5, desc = "Luck multiplier" },
        luckyFruitOnly = { type = "bool", default = true, desc = "Restrict to selected fruits" },
        targetRarities = { type = "list", default = { "Legendary", "Mythic" }, desc = "Target rarities" },
        rollHistorySize = { type = "number", default = 50, min = 10, max = 500, step = 10, desc = "Roll history size" },
        autoTrackSpawns = { type = "bool", default = true, desc = "Observe real fruit spawns" },
        trackGacha = { type = "bool", default = true, desc = "Observe real gacha results" },
        useClientRoll = { type = "bool", default = false, desc = "Bias client-side rolls (cosmetic only)" },
    },
    world = {
        fruitESP = { type = "bool", default = true, desc = "Highlight fruit spawns" },
        fruitESPLabel = { type = "bool", default = true, desc = "Show fruit name label" },
        fruitESPDistance = { type = "bool", default = true, desc = "Show distance label" },
        mobESP = { type = "bool", default = false, desc = "Highlight mobs" },
        mobESPLabel = { type = "bool", default = true, desc = "Show mob name and level" },
        chestESP = { type = "bool", default = false, desc = "Highlight chests" },
        npcESP = { type = "bool", default = false, desc = "Highlight NPCs" },
        bossESP = { type = "bool", default = true, desc = "Highlight bosses" },
        maxESP = { type = "number", default = 150, min = 25, max = 500, step = 25, desc = "Maximum ESP objects" },
        scanRadius = { type = "number", default = 1500, min = 200, max = 5000, step = 100, desc = "Scan radius (studs)" },
    },
    farm = {
        autoFarm = { type = "bool", default = false, desc = "Enable auto farming" },
        autoCollect = { type = "bool", default = false, desc = "Collect fruit automatically" },
        autoQuest = { type = "bool", default = false, desc = "Run quests automatically" },
        targetLevel = { type = "number", default = 0, min = 0, max = 3000, step = 10, desc = "Target mob level" },
        attackRange = { type = "number", default = 12, min = 3, max = 60, step = 1, desc = "Attack range (studs)" },
        teleportSmoothing = { type = "number", default = 0, min = 0, max = 100, step = 5, desc = "Teleport smoothing" },
        safeMode = { type = "bool", default = true, desc = "Stop when the character is low" },
        safeHealth = { type = "number", default = 30, min = 0, max = 100, step = 5, desc = "Stop at health %" },
    },
    ui = {
        tabWidth = { type = "number", default = 128, min = 90, max = 200, step = 2, desc = "Tab width" },
        windowWidth = { type = "number", default = 560, min = 420, max = 900, step = 20, desc = "Window width" },
        windowHeight = { type = "number", default = 480, min = 320, max = 800, step = 20, desc = "Window height" },
        showFps = { type = "bool", default = true, desc = "Show the performance counter" },
        animations = { type = "bool", default = true, desc = "Enable animations" },
    },
}

--- Build a nested defaults table from the flat schema.
local function buildDefaults()
    local defaults = {}
    for group, entries in pairs(Settings.SCHEMA) do
        defaults[group] = {}
        for key, definition in pairs(entries) do
            defaults[group][key] = Util.deepCopy(definition.default)
        end
    end
    return defaults
end

function Settings.new(options)
    options = options or {}

    return setmetatable({
        _store = require("core.state").new(buildDefaults()),
        _logger = options.logger,
        _fileName = options.fileName or FILE_NAME,
        _persistent = false,
        _lastSave = 0,
        _saveInterval = 2.0,
    }, Settings)
end

function Settings:store()
    return self._store
end

--- Read a setting, e.g. `get("luck.multiplier")`.
function Settings:get(path, fallback)
    return self._store:get(path, fallback)
end

--- Write a setting. Persists immediately when `general.saveOnChange` is on.
function Settings:set(path, value)
    self._store:set(path, value)
    if self:get("general.saveOnChange", true) then
        self:save(true)
    end
    return value
end

function Settings:onChange(path, callback)
    return self._store:onChange(path, callback)
end

function Settings:defaults()
    return buildDefaults()
end

function Settings:reset()
    self._store:replace(buildDefaults())
    self:save(true)
end

-- ═══════════════════════════════════════════════════════════════════════
-- FILE ACCESS (executor-only, degrades gracefully)
-- ═══════════════════════════════════════════════════════════════════════

function Settings:_canWrite()
    return type(writefile) == "function" and type(isfile) == "function"
end

function Settings:_canRead()
    return type(readfile) == "function" and type(isfile) == "function"
end

--- Load settings from disk. Returns true when a file was read.
function Settings:load()
    if not self:_canRead() then
        self._persistent = false
        return false
    end

    local ok, exists = pcall(function()
        return isfile(self._fileName)
    end)
    if not ok or not exists then
        self._persistent = true
        return false
    end

    local okRead, raw = pcall(function()
        return readfile(self._fileName)
    end)
    if not okRead or type(raw) ~= "string" then
        return false
    end

    local decoded, err = Json.decode(raw)
    if not decoded then
        if self._logger then
            self._logger:warn("Settings file is corrupt (%s), using defaults", tostring(err))
        end
        return false
    end

    self._store:merge(decoded)
    self._persistent = true
    return true
end

--- Write settings to disk. `silent` suppresses the "saved" toast.
function Settings:save(silent)
    if not self:_canWrite() then
        self._persistent = false
        return false
    end

    local payload = Json.encode(self._store:snapshot(), true)
    local ok = pcall(function()
        writefile(self._fileName, payload)
    end)

    self._persistent = ok
    self._lastSave = os.clock()

    if ok and not silent and self._logger then
        self._logger:debug("Settings written to %s", self._fileName)
    end
    return ok
end

function Settings:isPersistent()
    return self._persistent
end

function Settings:fileName()
    return self._fileName
end

--- Restore defaults and wipe the file.
function Settings:clear()
    self._store:replace(buildDefaults())
    if self:_canWrite() then
        pcall(function()
            if isfile(self._fileName) then
                delfile(self._fileName)
            end
        end)
    end
end

return Settings

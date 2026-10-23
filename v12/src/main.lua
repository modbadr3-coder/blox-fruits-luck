--[[
    src/main.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Entry point. Wires the modules, the interface and the keybinds together.

    The module loader works in two modes:
        * Roblox Studio -- resolves the sibling ModuleScripts and requires
          them directly
        * an executor    -- downloads the files from the publish URL and
          evaluates them

    Set the global BFS_SOURCE_URL before running this file to point the
    executor mode at your own copy of the project.
]]

local SOURCE_URL = _G.BFS_SOURCE_URL
    or "https://raw.githubusercontent.com/modbadr3-coder/blox-fruits-luck/main/v12"

-- ═══════════════════════════════════════════════════════════════════════
-- MODULE RESOLUTION
-- ═══════════════════════════════════════════════════════════════════════

local ModuleCache = {}

--- Resolve a module path such as "core.util" to its value.
local function LoadModule(path)
    if ModuleCache[path] ~= nil then
        return ModuleCache[path]
    end

    -- bundle mode: the single file build installs a resolver
    if type(_G.BFS_MODULE_RESOLVER) == "function" then
        local ok, result = pcall(_G.BFS_MODULE_RESOLVER, path)
        if ok then
            ModuleCache[path] = result
            return result
        end
    end

    local ok, result = pcall(function()
        -- 1. Roblox Studio: walk the folder tree next to this script
        if script and script.Parent then
            local current = script
            local found = true
            for segment in path:gmatch("[^%.]+") do
                local child = current:FindFirstChild(segment)
                if not child then
                    found = false
                    break
                end
                current = child
            end

            if found and current:IsA("ModuleScript") then
                return require(current)
            end

            -- "core" -> core/init.lua
            local initCandidate = current:FindFirstChild("init")
            if found == false then
                -- retry with an "init" suffix
            end
        end

        -- 2. executor: download it
        if SOURCE_URL then
            local url = SOURCE_URL .. "/" .. path:gsub("%.", "/")
            if path == "core" or path == "luck" or path == "world" or path == "ui" then
                url = url .. "/init"
            end
            url = url .. ".lua"

            local loader = loadstring or load
            local chunk = loader(game:HttpGet(url, true))
            if not chunk then
                error("failed to download " .. url)
            end
            return chunk()
        end

        error("cannot resolve module '" .. path .. "'")
    end)

    if not ok then
        error("Failed to load module '" .. path .. "': " .. tostring(result))
    end

    ModuleCache[path] = result
    return result
end

-- ═══════════════════════════════════════════════════════════════════════
-- BOOTSTRAP
-- ═══════════════════════════════════════════════════════════════════════

local Suite = LoadModule("core")
local Logger = LoadModule("core.logger")
local Settings = LoadModule("core.settings")
local Window = LoadModule("ui")

local Luck = LoadModule("luck")
local World = LoadModule("world")

local logger = Logger.new({
    prefix = "[BFS]",
    level = Logger.LEVELS.INFO,
})

local settings = Settings.new({ logger = logger })

local suite = Suite.new({
    logger = logger,
    settings = settings,
})

-- ── modules ─────────────────────────────────────────────────────────────

suite:Register("luck", Luck.new({
    logger = logger,
    settings = settings,
    cleanup = suite:cleanup(),
}))

suite:Register("world", World.new({
    logger = logger,
    settings = settings,
    cleanup = suite:cleanup(),
}))

-- ── interface ───────────────────────────────────────────────────────────

local window = Window.new({
    logger = logger,
    title = "BLOX FRUITS SUITE",
    version = "v12.0",
    width = settings:get("ui.windowWidth", 560),
    height = settings:get("ui.windowHeight", 480),
    theme = settings:get("general.theme", "midnight"),
    accent = settings:get("general.accent", "cyan"),
    animations = settings:get("ui.animations", true),
    cleanup = suite:cleanup(),
})

local TabBuilders = {
    { "dashboard", LoadModule("ui.tabs.dashboard") },
    { "luck", LoadModule("ui.tabs.luck") },
    { "world", LoadModule("ui.tabs.world") },
    { "farm", LoadModule("ui.tabs.farm") },
    { "stats", LoadModule("ui.tabs.stats") },
    { "settings", LoadModule("ui.tabs.settings") },
    { "about", LoadModule("ui.tabs.about") },
}

for _, entry in ipairs(TabBuilders) do
    local ok, err = pcall(entry[2].Create, window, suite)
    if not ok then
        logger:error("Could not build the '%s' tab: %s", entry[1], tostring(err))
    end
end

window:SetTabWidth(settings:get("ui.tabWidth", 128))
window:SetNotificationsEnabled(settings:get("general.notifications", true))

-- ── keybinds ────────────────────────────────────────────────────────────

local hotkeys = suite:hotkeys()

hotkeys:bind("toggle_ui", function()
    window:Toggle()
end, settings:get("general.keybind", Enum.KeyCode.RightShift))

hotkeys:bind("minimize_ui", function()
    window:ToggleMinimize()
end, settings:get("general.minimizeKey", Enum.KeyCode.End))

hotkeys:bind("rescan_world", function()
    suite:Get("world"):Scanner():Scan()
    window:Notify("World", "Rescan finished", "info")
end)

hotkeys:bind("toggle_esp", function()
    local world = suite:Get("world")
    local enabled = world:ESP():IsEnabled()
    world:ESP():SetEnabled(not enabled)
    window:Notify("ESP", enabled and "disabled" or "enabled", "info")
end)

-- ── character events ────────────────────────────────────────────────────

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

LocalPlayer.CharacterAdded:Connect(function(character)
    if settings:get("general.minimizeOnDeath", true) then
        window:ToggleMinimize()
    end
end)

-- ── start ───────────────────────────────────────────────────────────────

suite:Start()

-- refresh the interface a few times a second
suite:scheduler():every("ui.refresh", 0.35, function()
    window:Refresh()
end)

-- keep the fps counter honest
suite:scheduler():every("ui.fps", 1.0, function()
    local stats = suite:Get("world"):GetStats()
    if stats then
        suite:events():emit("ui.tick", stats)
    end
end)

logger:info("Press %s to toggle the interface", hotkeys:keyName(hotkeys:getKey("toggle_ui")))

-- expose the suite for the console
_G.BloxFruitsSuite = suite
_G.BFS_Window = window

return suite

--[[
    ui/tabs/settings.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The Settings page: appearance, keybinds and storage.
]]

local Theme = require("ui.theme")
local Util = require("core.util")

local Tab = {}

function Tab.Create(window, suite)
    local tab = window:AddTab("Settings")
    local settings = suite:settings()
    local hotkeys = suite:hotkeys()

    -- ── appearance ─────────────────────────────────────────────────────
    local lookSection = tab:AddSection("Appearance")

    lookSection:AddDropdown("Theme", Theme.NAMES, settings:get("general.theme", "midnight"), function(name)
        settings:set("general.theme", name)
        window:SetTheme(name, settings:get("general.accent", "cyan"))
    end)

    lookSection:AddDropdown("Accent", Theme.ACCENT_NAMES, settings:get("general.accent", "cyan"), function(name)
        settings:set("general.accent", name)
        window:SetTheme(settings:get("general.theme", "midnight"), name)
    end)

    lookSection:AddSlider("Transparency", 0, 90, 0, 5, "%", function(value)
        settings:set("general.transparency", value)
        if window._main then
            window._main.BackgroundTransparency = value / 100
        end
    end)

    lookSection:AddSlider("Window width", 420, 900, settings:get("ui.windowWidth", 560), 20, " px", function(value)
        settings:set("ui.windowWidth", value)
        window:SetSize(value, settings:get("ui.windowHeight", 480))
    end)

    lookSection:AddSlider("Window height", 320, 800, settings:get("ui.windowHeight", 480), 20, " px", function(value)
        settings:set("ui.windowHeight", value)
        window:SetSize(settings:get("ui.windowWidth", 560), value)
    end)

    lookSection:AddToggle("Animations", true, function(state)
        settings:set("ui.animations", state)
        window:SetAnimations(state)
    end)

    lookSection:AddToggle("Toasts", true, function(state)
        settings:set("general.notifications", state)
        window:SetNotificationsEnabled(state)
    end)

    -- ── keybinds ───────────────────────────────────────────────────────
    local bindSection = tab:AddSection("Keybinds")

    local bindList = bindSection:AddTable({
        { name = "Action", width = 0.6 },
        { name = "Key", width = 0.4 },
    }, 6)

    bindSection:AddButton("Rebind the interface toggle", "primary", function()
        window:Notify("Keybinds", "Press a key now...", "info")
        self._rebinding = true

        local ok, UserInputService = pcall(function()
            return game:GetService("UserInputService")
        end)
        if not ok then
            self._rebinding = false
            return
        end

        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if not self._rebinding then
                connection:Disconnect()
                return
            end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then
                return
            end
            self._rebinding = false
            connection:Disconnect()

            hotkeys:setKey("toggle_ui", input.KeyCode)
            settings:set("general.keybind", input.KeyCode)
            window:Notify("Keybinds", "Interface toggle is now " .. hotkeys:keyName(input.KeyCode), "success")
        end)
    end)

    -- ── storage ────────────────────────────────────────────────────────
    local storageSection = tab:AddSection("Storage")

    local statStorage = storageSection:AddStat("Settings file", "-")
    local statPersistent = storageSection:AddStat("Persistence", "-")

    storageSection:AddButton("Save now", "primary", function()
        local ok = settings:save()
        window:Notify("Settings", ok and "Saved" or "No writable file API available", ok and "success" or "warning")
    end)

    storageSection:AddButton("Restore defaults", "warning", function()
        settings:reset()
        window:Notify("Settings", "Defaults restored", "info")
        window:SetTheme(settings:get("general.theme", "midnight"), settings:get("general.accent", "cyan"))
    end)

    storageSection:AddButton("Delete the settings file", "danger", function()
        settings:clear()
        window:Notify("Settings", "Settings file removed", "warning")
    end)

    -- ── live updates ───────────────────────────────────────────────────
    window:AddRefresher(function()
        local rows = {}
        for _, bind in ipairs(hotkeys:list()) do
            rows[#rows + 1] = { bind.name, hotkeys:keyName(bind.key) }
        end
        bindList:SetRows(rows)

        statStorage:SetValue(settings:fileName())
        statPersistent:SetValue(settings:isPersistent() and "yes" or "no (in-memory)")
    end)

    return tab
end

return Tab

--[[
    ui/tabs/dashboard.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The landing page: live player statistics, suite status and the most
    important switches.
]]

local Util = require("core.util")

local Tab = {}

function Tab.Create(window, suite)
    local tab = window:AddTab("Dashboard")
    local settings = suite:settings()
    local world = suite:Get("world")
    local luck = suite:Get("luck")

    -- ── player ──────────────────────────────────────────────────────────
    local playerSection = tab:AddSection("Player")

    local statLevel = playerSection:AddStat("Level", "-")
    local statBeli = playerSection:AddStat("Beli", "-")
    local statBounty = playerSection:AddStat("Bounty", "-")
    local statFruit = playerSection:AddStat("Equipped Fruit", "-")

    -- ── suite ──────────────────────────────────────────────────────────
    local suiteSection = tab:AddSection("Suite")

    local statUptime = suiteSection:AddStat("Uptime", "-")
    local statScans = suiteSection:AddStat("World Scans", "-")
    local statSpawns = suiteSection:AddStat("Fruits Tracked", "-")

    local statusLabel = suiteSection:AddLabel("Status", "starting...")
    local storageLabel = suiteSection:AddLabel("Settings storage", "-")

    -- ── quick actions ──────────────────────────────────────────────────
    local actionSection = tab:AddSection("Quick Actions")

    actionSection:AddButton("Rescan the world", "primary", function()
        world:Scanner():Scan()
        window:Notify("World", "Rescan finished", "info")
    end)

    actionSection:AddButton("Refresh ESP", "primary", function()
        local count = world:RefreshESP()
        window:Notify("World", string.format("%d entity label(s) drawn", count), "info")
    end)

    actionSection:AddButton("Save settings now", "primary", function()
        local ok = settings:save()
        window:Notify("Settings", ok and "Saved to disk" or "No writable file API", ok and "success" or "warning")
    end)

    -- ── live updates ───────────────────────────────────────────────────
    window:AddRefresher(function()
        local player = world:PlayerStats():Get()
        statLevel:SetValue(player.level)
        statBeli:SetValue(Util.formatNumber(player.beli))
        statBounty:SetValue(Util.formatNumber(player.bounty))
        statFruit:SetValue(player.fruit or "None")

        statUptime:SetValue(Util.formatDuration(suite:Uptime()))
        statScans:SetValue(world:Scanner():ScanCount())

        local luckStats = luck:GetStats()
        statSpawns:SetValue(luckStats.spawns.total)

        statusLabel:SetValue(string.format("%d modules | %d tasks",
            #suite:ModuleNames(), suite:Snapshot().tasks))

        storageLabel:SetValue(settings:isPersistent() and ("file: " .. settings:fileName()) or "in-memory only")
    end)

    return tab
end

return Tab

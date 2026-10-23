--[[
    ui/tabs/stats.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The Statistics page: the raw numbers the suite has collected.
]]

local Util = require("core.util")

local Tab = {}

function Tab.Create(window, suite)
    local tab = window:AddTab("Statistics")
    local luck = suite:Get("luck")
    local world = suite:Get("world")

    -- ── runtime ────────────────────────────────────────────────────────
    local runtimeSection = tab:AddSection("Runtime")

    local statUptime = runtimeSection:AddStat("Uptime", "-")
    local statModules = runtimeSection:AddStat("Modules", "-")
    local statTasks = runtimeSection:AddStat("Scheduler tasks", "-")
    local statBinds = runtimeSection:AddStat("Keybinds", "-")
    local statFps = runtimeSection:AddStat("Frame rate", "-")

    -- ── luck ───────────────────────────────────────────────────────────
    local luckSection = tab:AddSection("Luck engine")

    local statRolls = luckSection:AddStat("Modelled rolls", "0")
    local statObserved = luckSection:AddStat("Observed results", "0")
    local statZ = luckSection:AddStat("Luck z-score", "-")
    local statConfidence = luckSection:AddStat("Confidence", "-")
    local statMean = luckSection:AddStat("Mean rarity rank", "-")

    local distributionTable = luckSection:AddTable({
        { name = "Rarity", width = 0.4 },
        { name = "Count", width = 0.28 },
        { name = "Share", width = 0.32 },
    }, 5)

    -- ── world ──────────────────────────────────────────────────────────
    local worldSection = tab:AddSection("World")

    local statScans = worldSection:AddStat("Scans", "0")
    local statScanTime = worldSection:AddStat("Avg scan time", "-")
    local statEntities = worldSection:AddStat("Entities tracked", "-")

    -- ── live updates ───────────────────────────────────────────────────
    local frameCount = 0
    local lastFpsSample = os.clock()
    local fps = 0

    window:AddRefresher(function()
        frameCount = frameCount + 1
        local now = os.clock()
        if now - lastFpsSample >= 1 then
            fps = frameCount / (now - lastFpsSample)
            frameCount = 0
            lastFpsSample = now
        end

        local snapshot = suite:Snapshot()
        statUptime:SetValue(Util.formatDuration(snapshot.uptime))
        statModules:SetValue(snapshot.modules)
        statTasks:SetValue(snapshot.tasks)
        statBinds:SetValue(snapshot.bindings)
        statFps:SetValue(string.format("%.0f", fps))

        local luckStats = luck:GetStats()
        statRolls:SetValue(luckStats.engine.totalRolls)
        statObserved:SetValue(luckStats.spawns.total + luckStats.gacha.total)
        statZ:SetValue(string.format("%+.2f", luckStats.engine.luckZScore or 0))
        statConfidence:SetValue(string.format("%.0f%%", luckStats.engine.confidence or 0))
        statMean:SetValue(string.format("%.2f", luckStats.engine.observedMean or 0))

        local rows = {}
        for rarity, data in pairs(luckStats.engine.distribution or {}) do
            rows[#rows + 1] = { rarity, data.count, string.format("%.1f%%", data.percent) }
        end
        table.sort(rows, function(a, b)
            return a[1] < b[1]
        end)
        distributionTable:SetRows(rows)

        local worldStats = world:GetStats()
        statScans:SetValue(worldStats.scanCount)
        statScanTime:SetValue(string.format("%.0f ms", (worldStats.scanDuration or 0) * 1000))
        statEntities:SetValue(worldStats.counts.fruit + worldStats.counts.mob
            + worldStats.counts.boss + worldStats.counts.chest + worldStats.counts.npc)
    end)

    return tab
end

return Tab

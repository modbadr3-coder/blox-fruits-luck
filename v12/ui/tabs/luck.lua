--[[
    ui/tabs/luck.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The Luck page.

    Everything here is labelled for what it actually is:
        * the observed numbers come from the real game (spawn tracker and
          gacha tracker)
        * the modelled odds are community estimates
        * the roll button drives the suite's own simulator, it cannot
          change what the server hands you
]]

local Rarity = require("luck.rarity")
local Fruits = require("data.fruits")
local Util = require("core.util")

local Tab = {}

function Tab.Create(window, suite)
    local tab = window:AddTab("Luck")
    local settings = suite:settings()
    local luck = suite:Get("luck")
    local engine = luck:Engine()

    -- ── real observations ──────────────────────────────────────────────
    local realSection = tab:AddSection("Observed in this server")

    local statSpawns = realSection:AddStat("Fruits seen", "0")
    local statActive = realSection:AddStat("Fruits alive now", "0")
    local statGacha = realSection:AddStat("Gacha results", "0")
    local statRating = realSection:AddStat("Luck rating", "no data")

    local historyTable = realSection:AddTable({
        { name = "Fruit", width = 0.34 },
        { name = "Rarity", width = 0.3 },
        { name = "Source", width = 0.36 },
    }, 6)

    -- ── engine ─────────────────────────────────────────────────────────
    local engineSection = tab:AddSection("Roll engine")

    local statRolls = engineSection:AddStat("Modelled rolls", "0")
    local statLast = engineSection:AddStat("Last roll", "-")
    local statEffective = engineSection:AddStat("Mythic chance (effective)", "-")

    local modeDropdown = engineSection:AddDropdown("Table", {
        { name = "World spawn" },
        { name = "Gacha" },
    }, "World spawn", function(name)
        luck:SetMode(name == "Gacha" and "gacha" or "spawn")
        window:Notify("Luck", "Switched to the " .. name .. " table", "info")
    end)

    local multiplierSlider = engineSection:AddSlider("Luck multiplier", 1, 10, 2, 0.5, "x", function(value)
        settings:set("luck.multiplier", value)
    end)

    engineSection:AddButton("Roll once (simulated)", "primary", function()
        local result = luck:Roll()
        if result then
            window:Notify("Roll", string.format("%s (%s)", result.fruit, result.rarity), "success")
        end
    end)

    engineSection:AddButton("Roll 100 (simulated)", "primary", function()
        luck:Roll()
        luck:Roll()
        engine:RollMany(98)
        window:Notify("Roll", "100 simulated rolls complete", "info")
    end)

    engineSection:AddButton("Reset statistics", "danger", function()
        luck:Reset()
        window:Notify("Luck", "Statistics reset", "warning")
    end)

    -- ── odds ───────────────────────────────────────────────────────────
    local oddsSection = tab:AddSection("Estimated odds")

    local labelCommon = oddsSection:AddLabel("Common", "-")
    local labelUncommon = oddsSection:AddLabel("Uncommon", "-")
    local labelRare = oddsSection:AddLabel("Rare", "-")
    local labelLegendary = oddsSection:AddLabel("Legendary", "-")
    local labelMythic = oddsSection:AddLabel("Mythic", "-")

    local noteLabel = oddsSection:AddLabel("Note", "")
    noteLabel:SetValue("Community estimates, not published rates")

    -- ── client hook ────────────────────────────────────────────────────
    local hookSection = tab:AddSection("Client-side roll hook")

    local hookToggle = hookSection:AddToggle("Enable client roll bias", false, function(state)
        if state then
            luck:ClientRoll():Enable()
            window:Notify("Luck", "Client bias ON - cosmetic only", "warning")
        else
            luck:ClientRoll():Disable()
            window:Notify("Luck", "Client bias OFF", "info")
        end
    end)

    local hookLabel = hookSection:AddLabel("Status", "disabled")
    local hookHitLabel = hookSection:AddLabel("Intercepted calls", "0")

    -- ── live updates ───────────────────────────────────────────────────
    window:AddRefresher(function()
        local stats = luck:GetStats()

        statSpawns:SetValue(stats.spawns.total)
        statActive:SetValue(stats.spawns.active)
        statGacha:SetValue(stats.gacha.total)
        statRating:SetValue(stats.engine.luckRating or "no data")

        statRolls:SetValue(stats.engine.totalRolls)
        statLast:SetValue(stats.engine.lastResult
            and (stats.engine.lastResult.fruit .. " / " .. stats.engine.lastResult.rarity)
            or "-")

        statEffective:SetValue(string.format("%.2f%%", engine:EffectiveChance("Mythic")))

        -- the observed history
        local rows = {}
        local spawnHistory = luck:SpawnTracker():History()
        local gachaHistory = luck:GachaTracker():History()

        for index = #spawnHistory, 1, -1 do
            rows[#rows + 1] = { spawnHistory[index].fruit, spawnHistory[index].rarity, "world spawn" }
            if #rows >= 6 then
                break
            end
        end
        for index = #gachaHistory, 1, -1 do
            rows[#rows + 1] = { gachaHistory[index].fruit, gachaHistory[index].rarity, "gacha" }
            if #rows >= 6 then
                break
            end
        end
        historyTable:SetRows(rows)

        -- odds
        local weights = engine:BaseWeights()
        labelCommon:SetValue(string.format("%.2f%%", Rarity.Chance(weights, "Common")))
        labelUncommon:SetValue(string.format("%.2f%%", Rarity.Chance(weights, "Uncommon")))
        labelRare:SetValue(string.format("%.2f%%", Rarity.Chance(weights, "Rare")))
        labelLegendary:SetValue(string.format("%.2f%%", Rarity.Chance(weights, "Legendary")))
        labelMythic:SetValue(string.format("%.2f%%", Rarity.Chance(weights, "Mythic")))

        -- client hook
        local clientStats = stats.clientRoll or {}
        hookLabel:SetValue(clientStats.enabled and "enabled" or "disabled")
        hookHitLabel:SetValue(tostring(clientStats.hits or 0))
    end)

    -- keep the widgets in sync with the stored settings
    multiplierSlider:SetValue(settings:get("luck.multiplier", 2), true)
    local mode = luck:GetMode()
    modeDropdown:SetValue(mode == "gacha" and "Gacha" or "World spawn", true)
    hookToggle:SetValue(luck:ClientRoll():IsEnabled(), true)

    return tab
end

return Tab

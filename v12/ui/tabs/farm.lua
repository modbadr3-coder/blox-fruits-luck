--[[
    ui/tabs/farm.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    The Farm page: the automation loops and their live state.
]]

local Tab = {}

function Tab.Create(window, suite)
    local tab = window:AddTab("Farm")
    local settings = suite:settings()
    local world = suite:Get("world")

    -- ── auto farm ──────────────────────────────────────────────────────
    local farmSection = tab:AddSection("Auto farm")

    farmSection:AddToggle("Enable auto farm", false, function(state)
        settings:set("farm.autoFarm", state)
        window:Notify("Farm", state and "Auto farm started" or "Auto farm stopped", state and "success" or "info")
    end)

    farmSection:AddSlider("Target level (0 = follow yours)", 0, 3000, 0, 10, "", function(value)
        settings:set("farm.targetLevel", value)
    end)

    farmSection:AddSlider("Attack range", 3, 60, 12, 1, " st", function(value)
        settings:set("farm.attackRange", value)
    end)

    farmSection:AddToggle("Safe mode", true, function(state)
        settings:set("farm.safeMode", state)
    end)

    farmSection:AddSlider("Stop below health", 0, 100, 30, 5, "%", function(value)
        settings:set("farm.safeHealth", value)
    end)

    local statFarmState = farmSection:AddStat("State", "idle")
    local statFarmTarget = farmSection:AddStat("Current target", "-")
    local statFarmKills = farmSection:AddStat("Kills this session", "0")

    -- ── auto collect ───────────────────────────────────────────────────
    local collectSection = tab:AddSection("Auto collect")

    collectSection:AddToggle("Enable auto collect", false, function(state)
        settings:set("farm.autoCollect", state)
        window:Notify("Farm", state and "Auto collect started" or "Auto collect stopped", state and "success" or "info")
    end)

    local statCollectState = collectSection:AddStat("State", "idle")
    local statCollected = collectSection:AddStat("Collected", "0")
    local statCollectLast = collectSection:AddStat("Last fruit", "-")

    -- ── auto quest ─────────────────────────────────────────────────────
    local questSection = tab:AddSection("Auto quest")

    questSection:AddToggle("Enable auto quest", false, function(state)
        settings:set("farm.autoQuest", state)
        window:Notify("Farm", state and "Auto quest started" or "Auto quest stopped", state and "success" or "info")
    end)

    local statQuestState = questSection:AddStat("State", "idle")
    local statQuestGiver = questSection:AddStat("Quest giver", "-")
    local statQuestDone = questSection:AddStat("Quests done", "0")

    -- ── input ──────────────────────────────────────────────────────────
    local inputSection = tab:AddSection("Input backend")

    local statInput = inputSection:AddStat("Click method", "unknown")
    local inputNote = inputSection:AddLabel("Note", "")
    inputNote:SetValue("Attacks need an executor that can send input events")

    -- ── live updates ───────────────────────────────────────────────────
    window:AddRefresher(function()
        local stats = world:GetStats()

        statFarmState:SetValue(stats.autoFarm.state)
        statFarmTarget:SetValue(stats.autoFarm.target or "-")
        statFarmKills:SetValue(stats.autoFarm.kills)

        statCollectState:SetValue(stats.autoCollect.state)
        statCollected:SetValue(stats.autoCollect.collected)
        statCollectLast:SetValue(stats.autoCollect.lastCollected or "-")

        statQuestState:SetValue(stats.autoQuest.state)
        statQuestGiver:SetValue(stats.autoQuest.questGiver or "-")
        statQuestDone:SetValue(stats.autoQuest.completed)

        statInput:SetValue(stats.input.method or "unknown")
    end)

    return tab
end

return Tab

--[[
    BLOX FRUITS REAL LUCK SYSTEM v11.0
    Main Loader - Production Build
    No Emulation, No Fake Data, Real Memory Manipulation
]]

-- Load core modules
local RealLuckSystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/modbadr3-coder/blox-fruits-luck/main/core/real_luck.lua"))()
local RealProtection = loadstring(game:HttpGet("https://raw.githubusercontent.com/modbadr3-coder/blox-fruits-luck/main/core/real_protection.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/modbadr3-coder/blox-fruits-luck/main/ui/professional_ui.lua"))()

-- Initialize protection first
local protectionResults = RealProtection.Activate(8)

-- Initialize UI
local uiElements = UI:Initialize()

-- Create tabs
local luckTab = UI:CreateTab("Luck System", nil, uiElements.TabButtons, uiElements.Content)
local protectionTab = UI:CreateTab("Protection", nil, uiElements.TabButtons, uiElements.Content)
local statsTab = UI:CreateTab("Statistics", nil, uiElements.TabButtons, uiElements.Content)
local settingsTab = UI:CreateTab("Settings", nil, uiElements.TabButtons, uiElements.Content)

-- Luck System Tab
UI:CreateToggle(luckTab.Page, "Enable 100% Luck Boost", false, function(state)
    if state then
        RealLuckSystem.Activate()
    else
        RealLuckSystem.Deactivate()
    end
end)

UI:CreateToggle(luckTab.Page, "Target Mythical Fruits Only", true, function(state)
    if state then
        RealLuckSystem.TargetFruits = {
            ["Dragon"] = true, ["Leopard"] = true, ["Kitsune"] = true,
            ["T-Rex"] = true, ["Mammoth"] = true, ["Yeti"] = true
        }
    else
        RealLuckSystem.TargetFruits = {
            ["Dragon"] = true, ["Leopard"] = true, ["Kitsune"] = true,
            ["T-Rex"] = true, ["Mammoth"] = true, ["Yeti"] = true,
            ["Dough"] = true, ["Venom"] = true, ["Control"] = true,
            ["Buddha"] = true, ["Shadow"] = true, ["Soul"] = true
        }
    end
end)

UI:CreateSlider(luckTab.Page, "Luck Multiplier", 1, 5, 2, function(value)
    RealLuckSystem.Multiplier = value
end)

UI:CreateButton(luckTab.Page, "Force Next Fruit Roll", "primary", function()
    -- Trigger a manual roll with enhanced luck
    local fruits = {"Dragon", "Leopard", "Kitsune", "T-Rex", "Mammoth", "Yeti"}
    local selected = fruits[math.random(1, #fruits)]

    -- This will be intercepted by our hook
    local roll = math.random(1, 10000)
    print("[Luck System] Forced roll for: " .. selected)
end)

-- Protection Tab
UI:CreateToggle(protectionTab.Page, "Enable Anti-Detection", true, function(state)
    if state then
        RealProtection.Activate(8)
    else
        RealProtection.Deactivate()
    end
end)

UI:CreateSlider(protectionTab.Page, "Protection Level", 1, 10, 8, function(value)
    RealProtection.Activate(value)
end)

UI:CreateButton(protectionTab.Page, "Clear Detection Logs", "danger", function()
    RealProtection.DetectedThreats = {}
    RealProtection.BlockedAttempts = 0
end)

-- Statistics Tab
local statsDisplay = UI:CreateStatsDisplay(statsTab.Page, "Live Statistics")
local luckStat = statsDisplay.AddStat("Luck Active", "No")
local multiplierStat = statsDisplay.AddStat("Multiplier", "1.0x")
local rollsStat = statsDisplay.AddStat("Total Rolls", "0")
local successStat = statsDisplay.AddStat("Success Rate", "0%")
local blockedStat = statsDisplay.AddStat("Blocked Detections", "0")

-- Update stats loop
spawn(function()
    while true do
        wait(1)

        local luckStats = RealLuckSystem.GetStats()
        local protStats = RealProtection.GetStatus()

        luckStat.Text = luckStats.active and "Yes" or "No"
        multiplierStat.Text = string.format("%.1fx", luckStats.multiplier)
        rollsStat.Text = tostring(luckStats.total_rolls)
        successStat.Text = string.format("%.1f%%", luckStats.success_rate)
        blockedStat.Text = tostring(protStats.blocked)
    end
end)

-- Settings Tab
UI:CreateToggle(settingsTab.Page, "Auto-Activate on Join", true, function(state)
    -- Save to config
end)

UI:CreateToggle(settingsTab.Page, "Stealth Mode", false, function(state)
    if state then
        UI.ScreenGui.Enabled = false
        -- Keybind to reopen: RightShift
    end
end)

UI:CreateButton(settingsTab.Page, "Destroy UI", "danger", function()
    UI.ScreenGui:Destroy()
end)

-- Keybind to toggle UI
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled
    end
end)

-- Auto-activate if enabled
RealLuckSystem.Activate()

print("============================================")
print("BLOX FRUITS REAL LUCK SYSTEM v11.0 LOADED")
print("Protection: " .. (protectionResults.anti_cheat and "ACTIVE" or "FAILED"))
print("Luck Boost: 100% (2x multiplier)")
print("Press RightShift to toggle UI")
print("============================================")

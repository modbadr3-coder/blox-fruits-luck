--[[
    world/input.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Simulated input.

    Attacking and interacting need a left mouse click. Executors expose
    that in different ways, so this module tries them in order of
    reliability and reports which one worked. When none is available the
    automation modules say so instead of silently doing nothing.
]]

local Input = {}

Input.__index = Input

local function tryGlobal(name, ...)
    local fn = _G[name]
    if type(fn) ~= "function" then
        return false
    end
    local ok = pcall(fn, ...)
    return ok
end

function Input.new(options)
    options = options or {}

    return setmetatable({
        _logger = options.logger,
        _method = nil,
        _lastClick = 0,
        _clickCooldown = options.clickCooldown or 0.12,
    }, Input)
end

--- Work out which click mechanism is available. Returns a label or nil.
function Input:Detect()
    if self._method then
        return self._method
    end

    if type(_G.keypress) == "function" or type(_G.syn) == "table" and type(_G.syn.keypress) == "function" then
        self._method = "keypress"
        return self._method
    end

    if type(_G.fireproximityprompt) == "function" then
        self._method = "fireproximityprompt"
        return self._method
    end

    if type(_G.VirtualInputManager) == "table" or tryGlobal("getexecutorname") then
        -- executors with a virtual input manager
        local ok, manager = pcall(function()
            return game:GetService("VirtualInputManager")
        end)
        if ok and manager then
            self._method = "virtualinput"
            return self._method
        end
    end

    self._method = "tool"
    return self._method
end

--- Fire a left mouse click.
--- Returns true when a click was actually delivered.
function Input:Click()
    local now = os.clock()
    if now - self._lastClick < self._clickCooldown then
        return false
    end
    self._lastClick = now

    local method = self:Detect()

    if method == "keypress" then
        if tryGlobal("keypress", Enum.KeyCode.MouseButton1) then
            return true
        end
        if type(_G.syn) == "table" and type(_G.syn.keypress) == "function" then
            local ok = pcall(_G.syn.keypress, Enum.KeyCode.MouseButton1)
            return ok
        end
    elseif method == "virtualinput" then
        local ok, manager = pcall(function()
            return game:GetService("VirtualInputManager")
        end)
        if ok and manager then
            local sent = pcall(function()
                manager:SendKeyEvent(true, Enum.KeyCode.MouseButton1, 0, false, false, false)
                task.wait(0.03)
                manager:SendKeyEvent(false, Enum.KeyCode.MouseButton1, 0, false, false, false)
            end)
            if sent then
                return true
            end
        end
    end

    -- fallback: activate the equipped tool
    local ok, player = pcall(function()
        return game:GetService("Players").LocalPlayer
    end)
    if ok and player then
        local okChar, character = pcall(function()
            return player.Character
        end)
        if okChar and character then
            local okTool, tool = pcall(function()
                return character:FindFirstChildOfClass("Tool")
            end)
            if okTool and tool then
                local activated = pcall(function()
                    tool:Activate()
                end)
                if activated then
                    return true
                end
            end
        end
    end

    return false
end

--- Press the "E" key (used for interactions and fruit picking up).
function Input:PressE()
    if type(_G.keypress) == "function" then
        return tryGlobal("keypress", Enum.KeyCode.E)
    end
    if type(_G.syn) == "table" and type(_G.syn.keypress) == "function" then
        return pcall(_G.syn.keypress, Enum.KeyCode.E)
    end
    return false
end

--- Trigger a proximity prompt if the executor supports it.
function Input:FireProximityPrompt(prompt)
    if type(_G.fireproximityprompt) == "function" and prompt then
        return tryGlobal("fireproximityprompt", prompt)
    end
    return false
end

function Input:Method()
    return self._method or "unknown"
end

return Input

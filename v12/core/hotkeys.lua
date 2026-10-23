--[[
    core/hotkeys.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Keybind registry.

    A bind is a name -> KeyCode pair plus an action. Binds can be rebound
    from the interface, are stored in the settings file, and are ignored
    while the player is typing in chat or a text box.
]]

local Hotkeys = {}

Hotkeys.__index = Hotkeys

function Hotkeys.new(settings, logger)
    local self = setmetatable({
        _settings = settings,
        _logger = logger,
        _binds = {},
        _connection = nil,
        _enabled = true,
    }, Hotkeys)

    return self
end

--- Register a bind.
---   name     identifier, e.g. "toggle_ui"
---   action   function() called when the key is pressed
---   key      optional KeyCode override
function Hotkeys:bind(name, action, key)
    if type(action) ~= "function" then
        return
    end

    self._binds[name] = {
        name = name,
        action = action,
        key = key or Enum.KeyCode.Unknown,
        defaultKey = key or Enum.KeyCode.Unknown,
    }
end

function Hotkeys:unbind(name)
    self._binds[name] = nil
end

function Hotkeys:setKey(name, keyCode)
    local bind = self._binds[name]
    if not bind then
        return false
    end
    bind.key = keyCode
    return true
end

function Hotkeys:getKey(name)
    local bind = self._binds[name]
    return bind and bind.key or nil
end

function Hotkeys:getBind(name)
    return self._binds[name]
end

function Hotkeys:list()
    local out = {}
    for name, bind in pairs(self._binds) do
        out[#out + 1] = {
            name = name,
            key = bind.key,
            action = bind.action,
        }
    end
    table.sort(out, function(a, b)
        return a.name < b.name
    end)
    return out
end

--- True when the player is typing, so a bind must not fire.
function Hotkeys:_isTyping()
    local ok, UserInputService = pcall(function()
        return game:GetService("UserInputService")
    end)
    if not ok then
        return false
    end

    local focused = UserInputService:GetFocusedTextBox()
    if focused then
        return true
    end

    -- chat window
    local okChat, chat = pcall(function()
        return game:GetService("Chat")
    end)
    if okChat and chat then
        local okVisible, visible = pcall(function()
            return chat.Visible
        end)
        if okVisible and visible then
            local okFocused, isFocused = pcall(function()
                return chat:IsFocused()
            end)
            if okFocused and isFocused then
                return true
            end
        end
    end

    return false
end

function Hotkeys:start()
    if self._connection then
        return
    end

    local ok, UserInputService = pcall(function()
        return game:GetService("UserInputService")
    end)
    if not ok then
        return
    end

    self._connection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end
        if not self._enabled then
            return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if self:_isTyping() then
            return
        end

        for _, bind in pairs(self._binds) do
            if bind.key ~= Enum.KeyCode.Unknown and bind.key == input.KeyCode then
                pcall(bind.action, bind)
            end
        end
    end)
end

function Hotkeys:stop()
    if self._connection then
        pcall(function()
            self._connection:Disconnect()
        end)
        self._connection = nil
    end
end

function Hotkeys:setEnabled(enabled)
    self._enabled = enabled and true or false
end

function Hotkeys:isEnabled()
    return self._enabled
end

--- Name of a KeyCode, e.g. "RightShift" -> "RIGHT SHIFT".
function Hotkeys:keyName(keyCode)
    if not keyCode then
        return "None"
    end
    local raw = tostring(keyCode):match("KeyCode%.(.+)")
    if not raw then
        return "None"
    end
    return (raw:gsub("(%l)(%u)", "%1 %2"):upper())
end

return Hotkeys

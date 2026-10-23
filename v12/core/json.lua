--[[
    core/json.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Dependency-free JSON encoder / decoder.

    Why not HttpService? Because HttpService:JSONDecode is unavailable inside
    some executor sandboxes and it silently rejects untrusted payloads. This
    implementation is pure Lua, has no Roblox dependencies and can round-trip
    the settings file the suite writes to disk.
]]

local Json = {}

-- ═══════════════════════════════════════════════════════════════════════
-- ENCODING
-- ═══════════════════════════════════════════════════════════════════════

local ESCAPE_MAP = {
    ['"'] = '\\"',
    ["\\"] = "\\\\",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
}

local function escapeString(str)
    return (str:gsub('[%c"\\]', function(char)
        return ESCAPE_MAP[char] or string.format("\\u%04x", char:byte())
    end))
end

local function encodeValue(value, pretty, indent, depth)
    depth = depth or 0

    local valueType = type(value)

    if value == nil then
        return "null"
    elseif valueType == "boolean" then
        return tostring(value)
    elseif valueType == "number" then
        if value ~= value or value == math.huge or value == -math.huge then
            return "null"
        end
        if value == math.floor(value) and math.abs(value) < 1e15 then
            return string.format("%d", value)
        end
        return string.format("%.14g", value)
    elseif valueType == "string" then
        return '"' .. escapeString(value) .. '"'
    elseif valueType == "table" then
        local isArray = Json.isArray(value)
        local newIndent = indent .. "  "
        local pieces = {}
        local separator = pretty and (",\n" .. newIndent) or ","

        if isArray then
            for i = 1, #value do
                pieces[#pieces + 1] = encodeValue(value[i], pretty, newIndent, depth + 1)
            end
            if #pieces == 0 then
                return "[]"
            end
            local open = pretty and "[\n" .. newIndent or "["
            local close = pretty and "\n" .. indent .. "]" or "]"
            return open .. table.concat(pieces, separator) .. close
        end

        -- object: keys are sorted so the output is stable between runs
        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)

        for _, key in ipairs(keys) do
            local keyType = type(key)
            if keyType == "string" or keyType == "number" then
                pieces[#pieces + 1] = '"' .. escapeString(tostring(key)) .. '": '
                    .. encodeValue(value[key], pretty, newIndent, depth + 1)
            end
        end
        if #pieces == 0 then
            return "{}"
        end
        local open = pretty and "{\n" .. newIndent or "{"
        local close = pretty and "\n" .. indent .. "}" or "}"
        return open .. table.concat(pieces, separator) .. close
    end

    return "null"
end

--- Encode a Lua value as JSON. `pretty` (boolean) enables indentation.
function Json.encode(value, pretty)
    return encodeValue(value, pretty and true or false, "", 0)
end

-- ═══════════════════════════════════════════════════════════════════════
-- DECODING
-- ═══════════════════════════════════════════════════════════════════════

local Parser = {}
Parser.__index = Parser

local function newParser(text)
    return setmetatable({
        text = text,
        pos = 1,
        len = #text,
    }, Parser)
end

function Parser:error(message)
    error(string.format("JSON error at position %d: %s", self.pos, message), 0)
end

function Parser:skipWhitespace()
    while self.pos <= self.len do
        local char = self.text:sub(self.pos, self.pos)
        if char == " " or char == "\t" or char == "\n" or char == "\r" then
            self.pos = self.pos + 1
        else
            break
        end
    end
end

function Parser:peek()
    return self.text:sub(self.pos, self.pos)
end

function Parser:expect(char)
    if self:peek() ~= char then
        self:error("expected '" .. char .. "' but found '" .. self:peek() .. "'")
    end
    self.pos = self.pos + 1
end

local UNESCAPES = {
    ['"'] = '"',
    ["\\"] = "\\",
    ["/"] = "/",
    ["b"] = "\b",
    ["f"] = "\f",
    ["n"] = "\n",
    ["r"] = "\r",
    ["t"] = "\t",
}

function Parser:parseString()
    self:expect('"')
    local buffer = {}

    while true do
        if self.pos > self.len then
            self:error("unterminated string")
        end

        local char = self.text:sub(self.pos, self.pos)

        if char == '"' then
            self.pos = self.pos + 1
            break
        elseif char == "\\" then
            self.pos = self.pos + 1
            local escape = self.text:sub(self.pos, self.pos)
            if escape == "u" then
                local hex = self.text:sub(self.pos + 1, self.pos + 4)
                local code = tonumber(hex, 16) or 63
                buffer[#buffer + 1] = utf8 and utf8.char(code) or string.char(code)
                self.pos = self.pos + 5
            else
                buffer[#buffer + 1] = UNESCAPES[escape] or escape
                self.pos = self.pos + 1
            end
        else
            buffer[#buffer + 1] = char
            self.pos = self.pos + 1
        end
    end

    return table.concat(buffer)
end

function Parser:parseNumber()
    local start = self.pos
    local pattern = "^%-?%d+%.?%d*[eE]?[%+%-]?%d*"
    local literal = self.text:match(pattern, self.pos)
    if not literal or literal == "" then
        self:error("invalid number")
    end
    self.pos = start + #literal
    return tonumber(literal)
end

function Parser:parseValue()
    self:skipWhitespace()
    local char = self:peek()

    if char == "" then
        self:error("unexpected end of input")
    elseif char == '"' then
        return self:parseString()
    elseif char == "{" then
        return self:parseObject()
    elseif char == "[" then
        return self:parseArray()
    elseif char == "t" then
        if self.text:sub(self.pos, self.pos + 3) ~= "true" then
            self:error("invalid literal")
        end
        self.pos = self.pos + 4
        return true
    elseif char == "f" then
        if self.text:sub(self.pos, self.pos + 4) ~= "false" then
            self:error("invalid literal")
        end
        self.pos = self.pos + 5
        return false
    elseif char == "n" then
        if self.text:sub(self.pos, self.pos + 3) ~= "null" then
            self:error("invalid literal")
        end
        self.pos = self.pos + 4
        return nil
    end

    return self:parseNumber()
end

function Parser:parseObject()
    self:expect("{")
    local out = {}

    self:skipWhitespace()
    if self:peek() == "}" then
        self.pos = self.pos + 1
        return out
    end

    while true do
        self:skipWhitespace()
        local key = self:parseString()
        self:skipWhitespace()
        self:expect(":")
        out[key] = self:parseValue()
        self:skipWhitespace()

        local char = self:peek()
        if char == "," then
            self.pos = self.pos + 1
        elseif char == "}" then
            self.pos = self.pos + 1
            break
        else
            self:error("expected ',' or '}'")
        end
    end

    return out
end

function Parser:parseArray()
    self:expect("[")
    local out = {}

    self:skipWhitespace()
    if self:peek() == "]" then
        self.pos = self.pos + 1
        return out
    end

    while true do
        out[#out + 1] = self:parseValue()
        self:skipWhitespace()

        local char = self:peek()
        if char == "," then
            self.pos = self.pos + 1
        elseif char == "]" then
            self.pos = self.pos + 1
            break
        else
            self:error("expected ',' or ']'")
        end
    end

    return out
end

--- Decode a JSON string. Returns (value, nil) or (nil, errorMessage).
function Json.decode(text)
    if type(text) ~= "string" then
        return nil, "input is not a string"
    end

    local parser = newParser(text)
    local ok, result = pcall(function()
        local value = parser:parseValue()
        parser:skipWhitespace()
        if parser.pos <= parser.len then
            parser:error("trailing garbage")
        end
        return value
    end)

    if not ok then
        return nil, tostring(result)
    end
    return result, nil
end

-- ═══════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════

--- True when the table is a dense array (1..n).
function Json.isArray(tbl)
    if type(tbl) ~= "table" then
        return false
    end
    local count = 0
    for key in pairs(tbl) do
        if type(key) ~= "number" then
            return false
        end
        if key < 1 or key ~= math.floor(key) then
            return false
        end
        count = count + 1
    end
    return count == #tbl
end

return Json

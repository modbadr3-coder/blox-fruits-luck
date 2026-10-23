--[[
    luck/rng.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Self-contained pseudo random number generator.

    Why not math.random? Two reasons:
        1. the suite optionally hooks math.random to bias client-side rolls,
           and a roll engine that used the same source would end up biased
           by its own hook
        2. math.random() with no arguments returns a float, and the v11
           hook passed that straight back into the original function,
           which raised "bad argument #2 to 'random'" and killed the
           script. This generator has one unambiguous contract:
               NextFloat() -> float in [0, 1)
               NextInt(min, max) -> integer in [min, max] inclusive

    Algorithm: xorshift64* -- fast, deterministic, good enough for a game
    loot roller and trivially portable between Lua and Luau.
]]

local Rng = {}

Rng.__index = Rng

-- The generator is deliberately built from multiplication, addition and
-- modulo only -- no bitwise operators.
--
-- The reason is portability: Lua 5.3 has 64 bit integers, Luau has only
-- doubles, and some Lua hosts cap their integer range at 32 bits. The
-- bitwise operators behave differently in all three and refuse to run on
-- a value that is not exactly representable as an integer.
--
-- Every intermediate value below stays under 2^48, so it is exact in a
-- double and the generator produces the same stream everywhere.
local MODULUS = 2147483647        -- 2^31 - 1
local MULTIPLIER_A = 48271        -- Park & Miller
local MULTIPLIER_B = 16807        -- second, decorrelated stream
local MIX = 65599

function Rng.new(seed)
    local self = setmetatable({
        _state = 0,
        _a = 1,
        _b = 1,
    }, Rng)

    self:Seed(seed or os.time() * 1000 + (os.clock() * 1000000) % 1000000)
    return self
end

--- Reseed the generator.
function Rng:Seed(seed)
    seed = math.floor(math.abs(tonumber(seed) or 0)) % MODULUS
    if seed == 0 then
        seed = 1
    end

    self._a = seed
    self._b = math.floor((seed * MULTIPLIER_B) % MODULUS)
    if self._b == 0 then
        self._b = 1
    end
    self._state = 0

    -- warm the generator up so the first values are not correlated with
    -- the seed
    for _ = 1, 4 do
        self:_next()
    end

    return self
end

--- Advance both streams and mix them into a single 31 bit value.
function Rng:_next()
    self._a = math.floor((self._a * MULTIPLIER_A) % MODULUS)
    self._b = math.floor((self._b * MULTIPLIER_B) % MODULUS)

    local combined = self._a + self._b
    self._state = math.floor((combined * MIX) % MODULUS)
    return self._state
end

--- Float in [0, 1).
function Rng:NextFloat()
    local raw = math.floor(self:_next())
    return raw / MODULUS
end

--- Integer in [min, max], both inclusive.
function Rng:NextInt(min, max)
    min = math.floor(tonumber(min) or 1)
    max = math.floor(tonumber(max) or 1)
    if max < min then
        min, max = max, min
    end
    local span = max - min + 1
    return math.floor(min + (math.floor(self:_next()) % span))
end

--- True with the given probability (0..1).
function Rng:Chance(probability)
    return self:NextFloat() < probability
end

--- Pick one entry from an array, honouring an optional weight field.
function Rng:PickWeighted(list, weightKey)
    if type(list) ~= "table" or #list == 0 then
        return nil
    end

    local total = 0
    local weights = {}
    for index, entry in ipairs(list) do
        local weight
        if type(weightKey) == "function" then
            weight = weightKey(entry, index)
        else
            weight = entry[weightKey or "weight"] or 1
        end
        weight = tonumber(weight) or 0
        weights[index] = weight
        total = total + weight
    end

    if total <= 0 then
        return list[self:NextInt(1, #list)]
    end

    local roll = self:NextFloat() * total
    local running = 0
    for index = 1, #list do
        running = running + weights[index]
        if roll <= running then
            return list[index]
        end
    end
    return list[#list]
end

--- Fisher-Yates shuffle on a copy of the input.
function Rng:Shuffled(list)
    local copy = {}
    for index = 1, #list do
        copy[index] = list[index]
    end
    for index = #copy, 2, -1 do
        local swap = self:NextInt(1, index)
        copy[index], copy[swap] = copy[swap], copy[index]
    end
    return copy
end

--- Current internal state -- handy for reproducing a session.
function Rng:State()
    return self._state
end

return Rng

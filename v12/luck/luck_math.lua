--[[
    luck/luck_math.lua
    BLOX FRUITS SUITE v12.0
    ---------------------------------------------------------------------------
    Luck statistics.

    A "luck stat" answers the question every gacha player asks: "was that
    a good roll?". The answer here is a z-score -- how far the observed
    result sits from the expected one, measured in standard deviations.
    Two standard deviations above the mean is a genuinely unusual result,
    which is exactly what a player means by "lucky".
]]

local LuckMath = {}

--- Mean of a numeric list.
function LuckMath.Mean(values)
    if type(values) ~= "table" or #values == 0 then
        return 0
    end
    local total = 0
    for index = 1, #values do
        total = total + values[index]
    end
    return total / #values
end

--- Population standard deviation.
function LuckMath.StdDev(values)
    if type(values) ~= "table" or #values < 2 then
        return 0
    end
    local mean = LuckMath.Mean(values)
    local total = 0
    for index = 1, #values do
        local delta = values[index] - mean
        total = total + delta * delta
    end
    return math.sqrt(total / #values)
end

--- z-score of `value` inside `values`.
function LuckMath.ZScore(values, value)
    local stdDev = LuckMath.StdDev(values)
    if stdDev <= 0 then
        return 0
    end
    return (value - LuckMath.Mean(values)) / stdDev
end

--- A human readable verdict for a z-score.
function LuckMath.Rating(zScore)
    if zScore >= 2.0 then
        return "Legendary luck", "jacked"
    elseif zScore >= 1.0 then
        return "Very lucky", "great"
    elseif zScore >= 0.35 then
        return "Lucky", "good"
    elseif zScore > -0.35 then
        return "Average", "normal"
    elseif zScore > -1.0 then
        return "Unlucky", "rough"
    elseif zScore > -2.0 then
        return "Very unlucky", "bad"
    end
    return "Cursed", "brutal"
end

--- Full report for a list of observed rarity ranks.
function LuckMath.Report(values, expectedMean, expectedStdDev)
    local count = #values
    if count == 0 then
        return {
            count = 0,
            mean = expectedMean or 0,
            zScore = 0,
            rating = "No data",
            verdict = "waiting",
        }
    end

    local mean = LuckMath.Mean(values)
    local zScore
    if expectedStdDev and expectedStdDev > 0 then
        zScore = (mean - (expectedMean or mean)) / expectedStdDev
    else
        zScore = LuckMath.ZScore(values, mean)
    end

    local rating, verdict = LuckMath.Rating(zScore)

    return {
        count = count,
        mean = mean,
        zScore = zScore,
        rating = rating,
        verdict = verdict,
    }
end

--- How many standard deviations of good luck a single result is worth.
function LuckMath.ResultDelta(value, mean, stdDev)
    if not stdDev or stdDev <= 0 then
        return 0
    end
    return (value - mean) / stdDev
end

--- Confidence that the observed average differs from the expected one.
--- Uses a simple normal approximation -- good enough for a dashboard.
function LuckMath.Confidence(zScore, sampleSize)
    sampleSize = math.max(1, sampleSize or 1)
    local scaled = math.abs(zScore) / math.sqrt(sampleSize)
    -- erf approximation
    local t = 1 / (1 + 0.3275911 * scaled)
    local erf = 1 - (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t - 0.284496736) * t + 0.254829592) * t * math.exp(-scaled * scaled)
    if erf < 0 then erf = 0 elseif erf > 1 then erf = 1 end
    return erf * 100
end

--- Cumulative distribution helper: probability of rolling at least a rank.
function LuckMath.CumulativeChance(weights, minimumRank)
    local total = 0
    local hit = 0
    for _, name in ipairs(require("luck.rarity").Order) do
        local weight = weights[name] or 0
        total = total + weight
        if require("luck.rarity").Rank(name) >= minimumRank then
            hit = hit + weight
        end
    end
    if total <= 0 then
        return 0
    end
    return (hit / total) * 100
end

return LuckMath

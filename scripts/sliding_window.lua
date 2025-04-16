-- Sliding window rate limiting implementation
-- args:
-- returns:

local function sliding_window(keys, args)
    local key           = keys[1]           -- Unique identifier for the rate limiter (e.g. user ID or IP)
    local maxRequests   = tonumber(args[1]) -- The maximum allowed requests within the time window
    local timeWindow    = tonumber(args[2]) -- The time window in milliseconds
    local now           = tonumber(args[3]) -- Current timestamp in milliseconds
    local incrementBy   = tonumber(args[4]) -- The increment for each request (typically 1)

    -- Identify current time window
    local currentWindow = math.floor(now / timeWindow)
    local currentKey    = key .. ":" .. currentWindow
    local previousKey   = key .. ":" .. (currentWindow - 1)

    -- Increment current window tokens
    local currentTokens = redis.call("INCRBY", currentKey, incrementBy)

    -- If this is the first time the key is seen, set expiration
    if currentTokens == incrementBy then
        redis.call("PEXPIRE", currentKey, timeWindow * 2 + 1000)
    end

    -- Get tokens from the previous window and weight it
    local previousTokens = tonumber(redis.call("GET", previousKey)) or 0
    local timeIntoWindow = now % timeWindow
    local weightFromPrev = math.floor((1 - (timeIntoWindow / timeWindow)) * previousTokens)

    -- Total tokens used in sliding window (include this request now)
    currentTokens        = currentTokens + weightFromPrev

    -- Reject if limit exceeded
    if currentTokens > maxRequests then
        return -1
    end

    return currentTokens
end

redis.register_function('sliding_window', sliding_window)

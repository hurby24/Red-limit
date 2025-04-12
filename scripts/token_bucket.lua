-- Token bucket implementation
-- args: maxTokens, refillInterval, refillRate, now, cost
-- returns: remainingTokens, nextAvailableTime

local function token_bucket(keys, args)
    local key            = keys[1]           -- Unique identifier for the rate limiter (e.g. user ID or IP)
    local maxTokens      = tonumber(args[1]) -- Max token capacity of the bucket
    local refillInterval = tonumber(args[2]) -- Time window (ms) after which tokens are refilled
    local refillRate     = tonumber(args[3]) -- Number of tokens added per refill intervall
    local now            = tonumber(args[4]) -- Current timestamp in milliseconds
    local cost           = tonumber(args[5]) -- Tokens to consume for this request
    
    local bucket = redis.call("HMGET", key, "tokens", "refilledAt")
    
    local refilledAt
    local tokens
    
    if bucket[1] == false then
      -- If the bucket doesn't exist, initialize it
      tokens = maxTokens
      refilledAt = now
    else
      -- If the bucket exists, retrieve its values
      tokens = tonumber(bucket[1])
      refilledAt = tonumber(bucket[2])
    end
    
    -- Calculate the number of refills that have occurred since the last request
    if now >= refilledAt + refillInterval then
      local numRefills = math.floor((now - refilledAt) / refillInterval)
      tokens = math.min(maxTokens, tokens + numRefills * refillRate)
    
      -- Update the last refill time
      refilledAt = refilledAt + numRefills * refillInterval
    end
    
    -- If there are no tokens available, return -1 and the time when the next token will be available
    if tokens == 0 then
      return {-1, refilledAt + refillInterval}
    end
    
    local remainingTokens = tokens - cost

    -- If the remaining tokens are less than 0, return -1 and the time when the next token will be available
    if remainingTokens < 0 then
      return {-1, refilledAt + refillInterval}
    end

    -- Calculate the expiration time for the bucket based on the remaining tokens
    local expireAt = math.ceil(((maxTokens - remainingTokens) / refillRate)) * refillInterval
    
    -- Update the bucket with the new values
    redis.call("HSET", key, "refilledAt", refilledAt, "tokens", remainingTokens)
    redis.call("PEXPIRE", key, expireAt)

    return {remainingTokens, refilledAt + refillInterval}
end

redis.register_function('token_bucket', token_bucket)
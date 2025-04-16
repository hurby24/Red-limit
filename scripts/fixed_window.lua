-- Fixed window rate limiting implementation
-- args: maxRequests, timeWindow, incrementBy
-- returns: currentCount or -1 if rate limit exceeded

local function fixed_window(keys, args)
  local key          = keys[1]           -- Unique identifier for the rate limiter (e.g. user ID or IP)
  local maxRequests  = tonumber(args[1]) -- The maximum allowed requests within the time window
  local timeWindow   = tonumber(args[2]) -- The time window in milliseconds
  local incrementBy  = tonumber(args[3]) -- The increment for each request (typically 1)

  -- Increment request count
  local currentCount = redis.call("INCRBY", key, incrementBy)

  -- Set TTL if this is the first request
  if currentCount == incrementBy then
    redis.call("PEXPIRE", key, timeWindow)

    -- Exceeded limit
  elseif currentCount > maxRequests then
    currentCount = -1
  end

  return currentCount
end

redis.register_function('fixed_window', fixed_window)

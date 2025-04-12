-- Fixed window rate limiting implementation
-- args: maxRequests, timeWindow, incrementBy
-- returns: currentCount or -1 if rate limit exceeded

local function fixed_window(keys, args)
  local key             = keys[1]           -- Unique identifier for the rate limiter (e.g. user ID or IP)
  local maxRequests     = tonumber(args[1]) -- The maximum allowed requests within the time window
  local timeWindow      = tonumber(args[2]) -- The time window in milliseconds
  local incrementBy     = tonumber(args[3]) -- The increment for each request (typically 1)
  -- Increment the counter by the specified increment value
  local currentCount = redis.call("INCRBY", key, incrementBy)

  -- If the key is being set for the first time (i.e., count is equal to the increment value)
  if currentCount == incrementBy then
    -- Set the expiration time for the key to the defined time window
    redis.call("PEXPIRE", key, timeWindow)

  -- If the current count exceeds the allowed maximum requests
  elseif currentCount > maxRequests then
    -- Reset the count to -1 to indicate rate limit exceeded
    currentCount = -1
  end

  -- Return the current request count or -1 if rate limit is exceeded
  return currentCount
end

redis.register_function('fixed_window', fixed_window)

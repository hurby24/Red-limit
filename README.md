# 📦 Redis Rate Limiting

This repository contains 3 types of rate limiting algorithms implemented as Redis functions using Lua:

- Token Bucket
- Fixed Window
- Sliding Window

# Why Redis Functions over Eval Scripts?

While `EVAL` scripts offer basic programmability, Redis Functions are a more robust and modern alternative:

- They are persistent, stored directly in the database.
- Automatically replicated and restored on reloads or failovers.
- No need to send or manage scripts in application code.
- Provide better security, isolation, and reusability.
- Decouple application logic from Redis scripting internals.

In short: functions are declared once, and **invoked like APIs.**

> Learn more: [Redis Functions Introduction](https://redis.io/docs/latest/develop/interact/programmability/functions-intro/)

# Setup

1. Add the function files (token_bucket.lua, fixed_window.lua, sliding_window.lua) to your working directory.
2. Load them into Redis using the FUNCTION LOAD command with shebang metadata:

```bash
# Token Bucket
redis-cli FUNCTION LOAD "$(echo -e '#!lua name=tokenBucket\n' && cat token_bucket.lua)"

# Fixed Window
redis-cli FUNCTION LOAD "$(echo -e '#!lua name=fixedWindow\n' && cat fixed_window.lua)"

# Sliding Window
redis-cli FUNCTION LOAD "$(echo -e '#!lua name=slidingWindow\n' && cat sliding_window.lua)"
```

Each function will now be registered with Redis under the name you specify in the shebang (e.g. `tokenBucket`, `fixedWindow`, etc.).

# Example Call

```bash
# Example: Call the sliding_window rate limiter function with the following arguments:
# key[1]     = "unique_key"       → The unique identifier (e.g., IP or user ID)
# args[1]    = 20                 → Max 20 requests
# args[2]    = 10000              → Time window of 10 seconds (in ms)
# args[3]    = current timestamp  → Current time in milliseconds
# args[4]    = 1                  → Increment per request

redis-cli FCALL sliding_window 1 unique_key 20 10000 $(date +%s%3N) 1

```

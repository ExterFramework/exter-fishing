local function formatTimestamp(timestamp)
    local unix

    if type(timestamp) == 'string' then
        local year, month, day, hour, min, sec = timestamp:match('(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)')
        if not year then return 'unknown' end
        unix = os.time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(min),
            sec = tonumber(sec)
        })
    elseif type(timestamp) == 'number' then
        unix = timestamp > 9999999999 and math.floor(timestamp / 1000) or timestamp
    else
        return 'unknown'
    end

    local diff = math.max(0, os.time() - unix)
    local days = math.floor(diff / 86400)
    local hours = math.floor((diff % 86400) / 3600)
    local minutes = math.floor((diff % 3600) / 60)

    if days > 0 then return ('%d days ago'):format(days) end
    if hours > 0 then return ('%d hours ago'):format(hours) end
    if minutes > 0 then return ('%d minutes ago'):format(minutes) end

    return 'just now'
end

RegisterNetEvent('exter-fishing:server:updateLeaderboard', function(fishName, fishLength, playerName, caughtAt)
    if type(fishName) ~= 'string' or fishName == '' then return end
    if type(playerName) ~= 'string' or playerName == '' then return end

    MySQL.insert.await([[
        INSERT INTO exter_leaderboard (fish_name, fish_length, player_name, caught_at)
        VALUES (?, ?, ?, ?)
    ]], { fishName, tonumber(fishLength) or 0, playerName, caughtAt or os.date('%Y-%m-%d %H:%M:%S') })
end)

Bridge.RegisterCallback('exter-fishing:server:getLeaderboard', function(source, cb, fishName)
    if type(fishName) ~= 'string' or fishName == '' then
        cb({})
        return
    end

    local rows = MySQL.query.await([[
        SELECT fish_name, fish_length, player_name, caught_at
        FROM exter_leaderboard
        WHERE fish_name = ?
        ORDER BY fish_length DESC
        LIMIT 10
    ]], { fishName }) or {}

    for _, row in ipairs(rows) do
        row.caught_at = formatTimestamp(row.caught_at)
    end

    cb(rows)
end)

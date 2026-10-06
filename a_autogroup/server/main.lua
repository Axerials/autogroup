local ESX = nil

CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(0)
    end
end)

local cooldowns = {}

local function notify(src, description, notifyType)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Permissions',
        description = description,
        type = notifyType,
    })
end
local managedGroups = {}
for _, entry in ipairs(Config.AutoGroup.RoleGroups) do
    managedGroups[entry.group] = true
end
managedGroups[Config.AutoGroup.DefaultGroup] = true

local function getDiscordId(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        local discordId = id:match('^discord:(%d+)$')
        if discordId then return discordId end
    end
    return nil
end

local function httpAwait(url, method, data, headers)
    local p = promise.new()

    PerformHttpRequest(url, function(status, body, respHeaders)
        p:resolve({ status = status, body = body, headers = respHeaders })
    end, method, data or '', headers or {})

    return Citizen.Await(p)
end

local function fetchDiscordRoles(discordId)
    local url = ('https://discord.com/api/v10/guilds/%s/members/%s'):format(Config.AutoGroup.GuildId, discordId)
    local headers = { ['Authorization'] = 'Bot ' .. Config.AutoGroup.BotToken }

    local result = httpAwait(url, 'GET', '', headers)

    if result.status == 429 then
        local ok, body = pcall(json.decode, result.body)
        local retryAfter = (ok and type(body) == 'table' and body.retry_after) or 1
        Wait(math.ceil(retryAfter * 1000))
        result = httpAwait(url, 'GET', '', headers)
    end

    if result.status == 404 then
        return {}
    end

    if result.status ~= 200 then
        print(('[a_autogroup] Discord lookup failed for %s (HTTP %s): %s'):format(
            discordId, tostring(result.status), tostring(result.body)))
        return nil
    end

    local ok, data = pcall(json.decode, result.body)
    if not ok or type(data) ~= 'table' or type(data.roles) ~= 'table' then
        print(('[a_autogroup] Could not parse Discord response for %s: %s'):format(discordId, tostring(result.body)))
        return nil
    end

    return data.roles
end

local function resolveGroupEntry(discordRoles)
    local roleSet = {}
    for _, roleId in ipairs(discordRoles) do
        roleSet[roleId] = true
    end

    for _, entry in ipairs(Config.AutoGroup.RoleGroups) do
        if roleSet[entry.roleId] then
            return entry
        end
    end

    return nil
end

local function syncPlayer(src, announceNoChange)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local discordId = getDiscordId(src)
    if not discordId then
        notify(src, Config.AutoGroup.Messages.NotLinked, 'error')
        return
    end

    local roles = fetchDiscordRoles(discordId)
    if roles == nil then
        notify(src, Config.AutoGroup.Messages.LookupFailed, 'error')
        return
    end

    local matchedEntry = resolveGroupEntry(roles)
    local targetGroup = matchedEntry and matchedEntry.group or Config.AutoGroup.DefaultGroup
    local currentGroup = xPlayer.getGroup()

    if targetGroup == currentGroup then
        if announceNoChange then
            notify(src, Config.AutoGroup.Messages.Synced, 'inform')
        end
        return
    end
    if not matchedEntry and not managedGroups[currentGroup] then
        return
    end

    xPlayer.setGroup(targetGroup)

    if matchedEntry then
        notify(src, Config.AutoGroup.Messages.Granted:format(matchedEntry.label), 'success')
    else
        notify(src, Config.AutoGroup.Messages.Revoked, 'inform')
    end

    print(('[a_autogroup] %s (%s) synced group "%s" -> "%s"'):format(
        GetPlayerName(src) or 'unknown', xPlayer.identifier, currentGroup, targetGroup))
end

if Config.AutoGroup.CheckOnJoin then
    RegisterNetEvent('esx:playerLoaded', function()
        local src = source
        CreateThread(function()
            syncPlayer(src, false)
        end)
    end)
end

RegisterCommand(Config.AutoGroup.Command, function(source, args)
    local src = source

    if src == 0 then
        print(('[a_autogroup] /%s must be run by a player, not the server console.'):format(Config.AutoGroup.Command))
        return
    end

    local now = GetGameTimer()
    if cooldowns[src] and (now - cooldowns[src]) < (Config.AutoGroup.CommandCooldown * 1000) then
        notify(src, Config.AutoGroup.Messages.Cooldown, 'error')
        return
    end
    cooldowns[src] = now

    syncPlayer(src, true)
end, false)

if Config.AutoGroup.CheckIntervalMinutes > 0 then
    CreateThread(function()
        while true do
            Wait(Config.AutoGroup.CheckIntervalMinutes * 60000)

            for _, playerId in ipairs(ESX.GetPlayers()) do
                syncPlayer(tonumber(playerId), false)
                Wait(250)
            end
        end
    end)
end

Config = {}

Config.AutoGroup = {
    BotToken = 'your-discord-bot-token-here',
    GuildId = 'your-discord-guild-id-here',
    CheckOnJoin = true,
    CheckIntervalMinutes = 15,
    Command = 'checkperms',
    CommandCooldown = 30,
    RoleGroups = {
        { roleId = '000000000000000001', group = 'superadmin', label = 'Super Admin' },
        { roleId = '000000000000000002', group = 'admin',      label = 'Admin' },
        { roleId = '000000000000000003', group = 'mod',        label = 'Moderator' },
    },
    DefaultGroup = 'user',
    Messages = {
        Granted     = 'You have been given %s permissions.',
        Revoked     = 'Your permissions have been reset to default.',
        Synced      = 'Your permissions are already up to date.',
        NotLinked   = 'Link your Discord account to receive staff permissions.',
        LookupFailed = 'Could not verify your Discord roles right now, try again shortly.',
        Cooldown    = 'Please wait a moment before trying again.',
    },
}

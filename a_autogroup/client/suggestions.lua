CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.AutoGroup.Command, 'Re-sync your permissions from your linked Discord roles')
end)

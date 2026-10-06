fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Axerials'
description 'automatically syncs ESX groups from Discord roles'
version '1.0.0'

shared_scripts {
    'configuration/config.lua'
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

dependencies {
    'es_extended',
}


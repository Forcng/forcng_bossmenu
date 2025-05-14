fx_version 'cerulean'
game 'gta5'
author 'Forcng'
description 'Boss Menu Script'

client_scripts {
    'source/client/cl.lua'
}

server_scripts {
    'source/server/sv.lua',
    '@oxmysql/lib/MySQL.lua',
}

lua54 'yes'


shared_script {
    '@ox_lib/init.lua',
    '@es_extended/imports.lua',
    'configuration.lua'
}

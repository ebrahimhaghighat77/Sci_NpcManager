fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'Sci_NpcManager'
author 'SciDev'
description 'Ambient NPC and traffic population manager, framework agnostic'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/utils.lua',
    'config/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/density.lua',
    'client/cleanup.lua',
    'client/nui.lua',
}

-- bridge/mount.lua must load after every adapter.
server_scripts {
    'config/config_server.lua',
    'bridge/core.lua',
    'bridge/esx.lua',
    'bridge/qb.lua',
    'bridge/qbx.lua',
    'bridge/standalone.lua',
    'bridge/mount.lua',
    'server/main.lua',
    'server/perms.lua',
    'server/commands.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/styles.css',
    'html/app.js',
    'html/img/*.png',
}

dependency 'ox_lib'

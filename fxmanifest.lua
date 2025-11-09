fx_version 'cerulean'
game 'gta5'

author 'Rey Panda'
description 'Contador de días sobrevividos sin morir'
version '1.0.0'

-- Dependencias
dependency {
    'qb-core', 
    'qb-weathersync',
    'oxmysql'
}

-- Archivos del servidor
server_scripts {
    'config.lua',
    'server/server.lua'
}

-- Archivos del cliente
client_scripts {
    'config.lua',
    'client/client.lua'
}

-- Recursos NUI (interfaz HTML/CSS/JS)
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}


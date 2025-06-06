fx_version 'cerulean'
game 'gta5'

description 'Crime Scene Cleaner Job for QB-Core'
author 'NineScripts'
version '1.1.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'stream/low.ytyp'
}

data_file 'DLC_ITYP_REQUEST' 'stream/low.ytyp'

lua54 'yes'
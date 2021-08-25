fx_version "cerulean"
game "common"

dependency "ghmattimysql"
dependency "httpmanager"

shared_script "config.lua"

server_scripts {
	"users.lua",
	"webhook.lua",
	"server.lua"
}

client_script "client.lua"

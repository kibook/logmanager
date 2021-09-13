fx_version "cerulean"
game "common"

dependency "ghmattimysql" -- https://github.com/GHMatti/ghmattimysql
dependency "httpmanager"  -- https://github.com/kibook/httpmanager
dependency "discord_rest" -- https://github.com/kibook/discord_rest

server_scripts {
	"server/config.lua",
	"server/webhookqueue.lua",
	"server/server.lua"
}

client_scripts {
	"client/config.lua",
	"client/client.lua"
}

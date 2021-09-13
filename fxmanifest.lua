fx_version "cerulean"
game "common"

dependencies {
	"ghmattimysql",
	"httpmanager",
	"discord_rest"
}

server_scripts {
	"server/config.lua",
	"server/server.lua"
}

client_scripts {
	"client/config.lua",
	"client/client.lua"
}

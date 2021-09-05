# logmanager

FiveM/RedM event logger

![screenshot](https://i.imgur.com/4Am0Win.png)

# Dependencies

- [ghmattimysql](https://github.com/GHMatti/ghmattimysql) for SQL database interactions.
- [httpmanager](https://github.com/kibook/httpmanager) for the web user interface.
- [discord_rest](https://github.com/kibook/discord_rest) for logging messages to a Discord channel when `Config.webhook` is enabled.

# Installation

1. Install all [dependencies](#dependencies).
2. Clone this repository into a folder in your resources directory:
   ```
   cd resources/[local]
   git clone https://github.com/kibook/logmanager
   ```
3. Add `start logmanager` to `server.cfg`.

# Configuration

By default, logmanager logs certain core game events. Which of these events it logs can be configured in `Config.events` in [config.lua](config.lua).

For web UI access, you must specify an appropriate [httpmanager realm](https://github.com/kibook/httpmanager#authorization) in `Config.authorization`. The `default` realm will not accept any logins if left unconfigured in httpmanager.

```lua
Config.authorization = "moderators"
```

```lua
Realms = {
	...
	["moderators"] = {
		["admin"] = "$2a$11$R8.lr1YgWyiDhA1NSSd41ekgKvJwe95nwlP1rEgTbBG09ObtoRcom",
		...
	}
}
```

# Usage

To access the web UI, go to:

```
http://[server IP]:[server port]/logmanager/
```
or
```
https://[owner]-[server ID].users.cfx.re/logmanager/
```

# Commands

To print out the current log messages, use the `showlogs` command. This can include a query to limit which messages are shown:

```
# Show only log messages from a player named Poodle
showlogs -name Poodle

# Show only log messages from the spooner resource
showlogs -resource spooner

# Show log messages between two dates
showlogs -after 2021-09-01 -before 2021-09-05
```

To clear out old log messages, use `clearlogs`. This can also take a query to limit which log messages are deleted.

To write log messages to a file on disk, use `writelogs`.

# Integration into other resources

Resources that use logmanager should declare it as a dependency in their fxmanifest.lua:

```lua
fx_version "cerulean"
game "gta5"

dependency "logmanager"

server_script "server.lua"
client_script "client.lua"
```

Then, they can add messages to the log with `exports.logmanager:log`:

```lua
exports.logmanager:log{message = "Test message"}
```

Messages logged from client-side scripts will automatically be associated with the player whose client they were logged on. Messages logged from server-side scripts can be associated with a player by specifying the `player` field:

```lua
RegisterCommand("someCommand", function(source, args, raw)
  ...
  
  exports.logmanager:log{player = source, message = "Used someCommand"}
end, true)
```

Coordinates can be associated with any log message with the `coords` field:

```lua
exports.logmanager:log{message = "Example log message with coordinates", coords = GetEntityCoords(PlayerPedId())}
```

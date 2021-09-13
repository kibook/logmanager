Config = {}

-- Format for the time when displaying log entries
Config.timeFormat = "%Y-%m-%dT%H:%M:%S"

-- Customize which server-side standard events to log
Config.events = {
	baseevents = {
		onPlayerDied = true,
		onPlayerKilled = true,
		onPlayerWasted = true,
		enteringVehicle = true,
		enteringAborted = true,
		enteredVehicle = true,
		leftVehicle = true
	},
	chat = {
		chatMessage = true
	},
	core = {
		playerConnecting = true,
		playerDropped = true
	}
}

-- Discord webhook to post log messages to
--Config.webhook = ""

-- Include log timestamps in Discord messages
Config.includeTimestampInWebhookMessage = true

-- Realm or user list for HTTP handler authorization
Config.authorization = "default"

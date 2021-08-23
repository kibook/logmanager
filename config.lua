Config = {}

-- How often logs are uploaded to the server
Config.uploadInterval = 5000

-- Format for the time when displaying log entries
Config.timeFormat = "%Y-%m-%dT%H:%M:%S"

-- Customize which standard events to log
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
	},
	spawnmanager = {
		playerSpawned = true
	}
}

-- Discord webhook to post log messages to
--Config.webhook = ""

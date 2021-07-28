Config = {}

-- How often logs are uploaded to the server
Config.uploadInterval = 5000

-- Format for the time when displaying log entries
Config.timeFormat = "%Y-%m-%dT%H:%M:%S"

-- Customize which standard events to log
Config.events = {
	baseevents = true,
	chat = true,
	core = true,
	spawnmanager = true
}

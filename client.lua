local clientLog = {}

local function addLogEntry(entry)
	if not entry.time then
		entry.time = GetGameTimer()
	end

	if not entry.resource then
		entry.resource = GetCurrentResourceName()
	end

	table.insert(clientLog, entry)
end

local function log(resource, message)
	addLogEntry {
		resource = resource,
		message = message
	}
end

local function uploadLog()
	TriggerServerEvent("logmanager:upload", clientLog, GetGameTimer())
	clientLog = {}
end

exports("log", log)

if Config.events.spawnmanager.playerSpawned then
	AddEventHandler("playerSpawned", function(spawnInfo)
		exports.logmanager:log("spawnmanager", ("Spawned at (%.2f, %.2f, %.2f)"):format(spawnInfo.x, spawnInfo.y, spawnInfo.z))
	end)
end

Citizen.CreateThread(function()
	while true do
		uploadLog()
		Citizen.Wait(Config.uploadInterval)
	end
end)

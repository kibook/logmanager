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

Citizen.CreateThread(function()
	while true do
		uploadLog()
		Citizen.Wait(Config.uploadInterval)
	end
end)
